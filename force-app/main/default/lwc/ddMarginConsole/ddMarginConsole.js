import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import GUARDRAIL_STATE_FIELD from '@salesforce/schema/Quote.DD_GuardrailState__c';
import QUOTE_DISCOUNT_FIELD from '@salesforce/schema/Quote.Discount';
import simulateMargin from '@salesforce/apex/DD_MarginConsoleController.simulate';
import requestDiscountApproval from '@salesforce/apex/DD_MarginConsoleController.requestDiscount';

// D14: a lista de campos das cotacoes NAO inclui margem nem custo.
// Discount e desconto comercial (o usuario ja ve na tela da cotacao), nao margem.
const QUOTE_FIELDS = [GUARDRAIL_STATE_FIELD, QUOTE_DISCOUNT_FIELD];

// F5-11: os Flows sao chamados pelo DD_MarginConsoleController (Apex), nao mais pelo
// lightning-flow — o componente nativo recusava a execucao para usuario nao-admin.
// O Apex devolve um DTO com whitelist de campos: nenhuma chave abaixo e margem ou custo.
const STATE_META = {
    'Saudável': {
        badgeClass: 'slds-badge slds-theme_success',
        iconName: 'utility:success',
        guidance: 'A cotação está no alvo da política. O desconto não exige pedido de aprovação.'
    },
    'Requer Justificativa': {
        badgeClass: 'slds-badge slds-theme_warning',
        iconName: 'utility:warning',
        guidance: 'A cotação está entre o piso e o alvo. Informe a justificativa para registrar o pedido.'
    },
    'Requer Aprovação': {
        badgeClass: 'slds-badge slds-theme_error',
        iconName: 'utility:error',
        guidance: 'A cotação está abaixo do piso da política. O pedido sobe para o aprovador da alçada.'
    },
    'Pendente de Custo': {
        badgeClass: 'slds-badge dd-badge-cost',
        iconName: 'utility:warning',
        guidance:
            'O custo das linhas desta cotação não está cadastrado no price book. O Pricing precisa cadastrar o custo antes de liberar o desconto.'
    },
    'Pendente de Política': {
        badgeClass: 'slds-badge slds-theme_info',
        iconName: 'utility:info',
        guidance: 'Não há política de desconto ativa para a família desta cotação.'
    },
    Bloqueado: {
        badgeClass: 'slds-badge slds-theme_error',
        iconName: 'utility:ban',
        guidance: 'O cálculo não pôde ser concluído. Verifique as linhas da cotação.'
    }
};

const DEFAULT_META = {
    badgeClass: 'slds-badge',
    iconName: 'utility:help',
    guidance: 'Sem avaliação de guardrail para esta cotação.'
};

const DECISION_LABEL = {
    AutoApproved: 'Dentro do alvo — nenhum pedido é necessário',
    ManagerApproval: 'Pedido de desconto encaminhado ao aprovador',
    NoPolicy: 'Sem política de desconto ativa',
    CostPending: 'Pendente de Custo — o Pricing precisa cadastrar o custo',
    Blocked: 'Roteamento bloqueado: aprovador não resolvido',
    Fault: 'Falha operacional no roteamento'
};

// F5-07/A74: custo ausente nao pode parecer margem perfeita.
const COST_PENDING_STATE = 'Pendente de Custo';

export default class DdMarginConsole extends LightningElement {
    @api recordId;

    quoteState;
    quoteDiscount;
    loadError;
    wiredQuoteResult;
    // UX: os dois campos de desconto nascem com o desconto atual da cotacao
    // (campo nativo Quote.Discount = media ponderada das linhas). Inicializa uma vez
    // para que refreshApex/re-render nao apaguem o que o usuario digitou.
    discountInitialized = false;

    // Simulador (nao grava nada)
    simDiscountPct = '';
    simRunning = false;
    simResult;
    simError;

    // Pedido de desconto (Flow de roteamento via Apex)
    reqDiscountPct = '';
    reqJustification = '';
    routeRunning = false;
    routeResult;
    routeError;

    @wire(getRecord, { recordId: '$recordId', fields: QUOTE_FIELDS })
    wiredQuote(result) {
        this.wiredQuoteResult = result;
        const { data, error } = result;
        if (data) {
            this.quoteState = getFieldValue(data, GUARDRAIL_STATE_FIELD);
            this.quoteDiscount = getFieldValue(data, QUOTE_DISCOUNT_FIELD);
            this.initializeDiscounts(this.quoteDiscount);
            this.loadError = undefined;
        } else if (error) {
            this.quoteState = undefined;
            this.loadError = this.reduceError(error);
        }
    }

    // Formata com 2 casas (ex.: 75.73). Desconto nulo/vazio vira 0.00.
    initializeDiscounts(rawDiscount) {
        if (this.discountInitialized) {
            return;
        }
        const value = Number(rawDiscount);
        const formatted = (Number.isFinite(value) ? value : 0).toFixed(2);
        this.simDiscountPct = formatted;
        this.reqDiscountPct = formatted;
        this.discountInitialized = true;
    }

    get hasRecordId() {
        return Boolean(this.recordId);
    }

    get isLoading() {
        return this.hasRecordId && !this.quoteState && !this.loadError;
    }

    get hasState() {
        return Boolean(this.quoteState);
    }

    get stateLabel() {
        return this.quoteState || 'Sem avaliação';
    }

    get stateInfo() {
        return STATE_META[this.quoteState] || DEFAULT_META;
    }

    get stateBadgeClass() {
        return this.stateInfo.badgeClass;
    }

    get stateIcon() {
        return this.stateInfo.iconName;
    }

    get stateGuidance() {
        return this.stateInfo.guidance;
    }

    get isCostPending() {
        return this.quoteState === COST_PENDING_STATE;
    }

    // O alerta de custo vale tanto para o estado gravado quanto para o simulado.
    get hasCostPendingAlert() {
        const simulated = this.simResult && this.simResult.state;
        return this.isCostPending || simulated === COST_PENDING_STATE;
    }

    get simulateButtonLabel() {
        return this.simRunning ? 'Simulando...' : 'Simular';
    }

    get hasSimResult() {
        return Boolean(this.simResult);
    }

    get simResultBadgeClass() {
        const state = this.simResult && this.simResult.state;
        return (STATE_META[state] || DEFAULT_META).badgeClass;
    }

    get simResultIcon() {
        const state = this.simResult && this.simResult.state;
        return (STATE_META[state] || DEFAULT_META).iconName;
    }

    get simResultState() {
        return (this.simResult && this.simResult.state) || 'Sem avaliação';
    }

    get simResultPolicy() {
        return (this.simResult && this.simResult.policyName) || 'Nenhuma política ativa';
    }

    get simResultDecision() {
        const decision = this.simResult && this.simResult.decision;
        return DECISION_LABEL[decision] || decision || '';
    }

    get requiresJustification() {
        const state = (this.simResult && this.simResult.state) || this.quoteState;
        // Pendente de Custo nao e um pedido: o bloqueio e anterior a justificativa.
        return Boolean(state) && state !== 'Saudável' && state !== COST_PENDING_STATE;
    }

    get justificationLabel() {
        return this.requiresJustification ? 'Justificativa (obrigatória)' : 'Justificativa (opcional)';
    }

    get isRequestDisabled() {
        return this.routeRunning || !this.hasRecordId || this.isCostPending;
    }

    get requestDisabledHint() {
        return this.isCostPending
            ? 'Envio bloqueado: sem custo cadastrado no price book não existe margem, e o pedido de desconto não pode ser avaliado.'
            : '';
    }

    get requestButtonLabel() {
        return this.routeRunning ? 'Enviando...' : 'Pedir desconto';
    }

    get hasRouteResult() {
        return Boolean(this.routeResult);
    }

    get routeResultDecision() {
        const decision = this.routeResult && this.routeResult.decision;
        return DECISION_LABEL[decision] || decision || 'Resultado do roteamento';
    }

    handleSimDiscountChange(event) {
        this.simDiscountPct = event.target.value;
    }

    async handleSimulate() {
        this.simError = undefined;
        this.simResult = undefined;
        const pct = Number(this.simDiscountPct);
        if (!this.isValidDiscount(pct)) {
            this.simError = 'Informe um desconto entre 0 e 100.';
            return;
        }

        this.simRunning = true;
        try {
            const result = await simulateMargin({
                quoteId: this.recordId,
                requestedDiscountPct: pct
            });
            if (!result || !result.guardrailState) {
                this.simError =
                    'O cálculo não devolveu um estado. Verifique a política ativa e as linhas da cotação.';
                return;
            }
            this.simResult = {
                state: result.guardrailState,
                policyName: result.policyName,
                decision: result.decision
            };
        } catch (error) {
            this.simError = this.reduceError(error);
        } finally {
            this.simRunning = false;
        }
    }

    handleRequestDiscountPctChange(event) {
        this.reqDiscountPct = event.target.value;
    }

    handleJustificationChange(event) {
        this.reqJustification = event.target.value;
    }

    async handleRequestDiscount() {
        this.routeError = undefined;
        this.routeResult = undefined;
        const pct = Number(this.reqDiscountPct);
        if (!this.isValidDiscount(pct)) {
            this.routeError = 'Informe um desconto entre 0 e 100.';
            return;
        }
        if (this.requiresJustification && !this.reqJustification.trim()) {
            const projected = (this.simResult && this.simResult.state) || this.quoteState || 'Sem avaliação';
            this.routeError = `O estado "${projected}" exige justificativa antes do envio.`;
            return;
        }

        this.routeRunning = true;
        try {
            const result = await requestDiscountApproval({
                quoteId: this.recordId,
                requestedDiscountPct: pct,
                justification: this.reqJustification
            });
            if (!result || !result.decision) {
                this.routeError =
                    'O roteamento não devolveu decisão. Nenhum pedido deve ser considerado enviado.';
                return;
            }
            this.routeResult = {
                decision: result.decision,
                status: result.status,
                requestId: result.requestId,
                approverName: result.approverName,
                message: result.message
            };
            const failed = result.decision === 'Fault' || result.decision === 'Blocked';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: failed ? 'Pedido não encaminhado' : 'Pedido de desconto',
                    message: result.message || this.routeResultDecision,
                    variant: failed ? 'error' : 'success'
                })
            );
        } catch (error) {
            this.routeError = this.reduceError(error);
        } finally {
            this.routeRunning = false;
        }
    }

    handleRefresh() {
        if (this.wiredQuoteResult) {
            refreshApex(this.wiredQuoteResult);
        }
    }

    isValidDiscount(value) {
        return Number.isFinite(value) && value >= 0 && value <= 100;
    }

    reduceError(error) {
        if (!error) {
            return 'Erro desconhecido.';
        }
        if (Array.isArray(error.body)) {
            return error.body.map((item) => item.message).join(', ');
        }
        if (error.body && error.body.message) {
            return error.body.message;
        }
        return error.message || 'Erro desconhecido.';
    }
}
