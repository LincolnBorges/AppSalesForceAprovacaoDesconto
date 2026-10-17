import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import GUARDRAIL_STATE_FIELD from '@salesforce/schema/Quote.DD_GuardrailState__c';

// D14: a lista de campos das cotacoes NAO inclui margem nem custo.
const QUOTE_FIELDS = [GUARDRAIL_STATE_FIELD];

// O lightning-flow devolve as variaveis de saida em um array de { name, value }.
// As chaves lidas aqui sao a whitelist do console: nenhuma delas e margem ou custo.
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
    Blocked: 'Roteamento bloqueado: aprovador não resolvido',
    Fault: 'Falha operacional no roteamento'
};

export default class DdMarginConsole extends LightningElement {
    @api recordId;

    quoteState;
    loadError;
    wiredQuoteResult;

    // Simulador (nao grava nada)
    simDiscountPct = 10;
    simRunning = false;
    simInputs = [];
    simResult;
    simError;

    // Pedido de desconto (Flow de roteamento)
    reqDiscountPct = 10;
    reqJustification = '';
    routeRunning = false;
    routeInputs = [];
    routeResult;
    routeError;

    @wire(getRecord, { recordId: '$recordId', fields: QUOTE_FIELDS })
    wiredQuote(result) {
        this.wiredQuoteResult = result;
        const { data, error } = result;
        if (data) {
            this.quoteState = getFieldValue(data, GUARDRAIL_STATE_FIELD);
            this.loadError = undefined;
        } else if (error) {
            this.quoteState = undefined;
            this.loadError = this.reduceError(error);
        }
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
        return Boolean(state) && state !== 'Saudável';
    }

    get justificationLabel() {
        return this.requiresJustification ? 'Justificativa (obrigatória)' : 'Justificativa (opcional)';
    }

    get isRequestDisabled() {
        return this.routeRunning || !this.hasRecordId;
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

    handleSimulate() {
        this.simError = undefined;
        this.simResult = undefined;
        const pct = Number(this.simDiscountPct);
        if (!this.isValidDiscount(pct)) {
            this.simError = 'Informe um desconto entre 0 e 100.';
            return;
        }
        this.simInputs = [
            { name: 'quoteId', type: 'String', value: this.recordId },
            { name: 'requestedDiscountPct', type: 'Number', value: pct }
        ];
        this.simRunning = true;
    }

    handleSimulateStatus(event) {
        const detail = event.detail || {};
        if (!this.isFlowFinished(detail.status)) {
            if (detail.status === 'ERROR') {
                this.simRunning = false;
                this.simError = 'Falha ao simular o desconto.';
            }
            return;
        }
        const output = this.toOutputMap(detail.outputVariables);
        this.simRunning = false;
        if (!output.guardrailState) {
            this.simError =
                'O cálculo não devolveu um estado. Verifique a política ativa e as linhas da cotação.';
            return;
        }
        this.simResult = {
            state: output.guardrailState,
            policyName: output.policyName,
            decision: output.decision
        };
    }

    handleRequestDiscountPctChange(event) {
        this.reqDiscountPct = event.target.value;
    }

    handleJustificationChange(event) {
        this.reqJustification = event.target.value;
    }

    handleRequestDiscount() {
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
        this.routeInputs = [
            { name: 'quoteId', type: 'String', value: this.recordId },
            { name: 'requestedDiscountPct', type: 'Number', value: pct },
            { name: 'justification', type: 'String', value: this.reqJustification }
        ];
        this.routeRunning = true;
    }

    handleRouteStatus(event) {
        const detail = event.detail || {};
        if (!this.isFlowFinished(detail.status)) {
            if (detail.status === 'ERROR') {
                this.routeRunning = false;
                this.routeError =
                    'Falha ao executar o roteamento. Nenhum pedido deve ser considerado enviado.';
            }
            return;
        }
        const output = this.toOutputMap(detail.outputVariables);
        this.routeRunning = false;
        if (!output.decision) {
            this.routeError =
                'O roteamento não devolveu decisão. Nenhum pedido deve ser considerado enviado.';
            return;
        }
        this.routeResult = {
            decision: output.decision,
            status: output.status,
            requestId: output.requestId,
            approverName: output.approverName,
            message: output.message
        };
        const failed = output.decision === 'Fault' || output.decision === 'Blocked';
        this.dispatchEvent(
            new ShowToastEvent({
                title: failed ? 'Pedido não encaminhado' : 'Pedido de desconto',
                message: output.message || this.routeResultDecision,
                variant: failed ? 'error' : 'success'
            })
        );
    }

    handleRefresh() {
        if (this.wiredQuoteResult) {
            refreshApex(this.wiredQuoteResult);
        }
    }

    isFlowFinished(status) {
        return status === 'FINISHED_SCREEN' || status === 'FINISHED';
    }

    toOutputMap(outputVariables) {
        const map = {};
        if (Array.isArray(outputVariables)) {
            outputVariables.forEach((item) => {
                if (item && item.name) {
                    map[item.name] = item.value;
                }
            });
        } else if (outputVariables) {
            Object.keys(outputVariables).forEach((key) => {
                map[key] = outputVariables[key];
            });
        }
        return map;
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
