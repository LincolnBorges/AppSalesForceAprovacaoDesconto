/**
 * DD_MarginConsoleController
 *
 * Ponte entre o LWC ddMarginConsole e os dois Flows do guardrail (F5-11 / D28).
 *
 * Por que existe: o componente nativo lightning-flow recusa a execucao para usuario
 * nao-admin nesta org (FLOW_ACCESS_RESTRICTED, FLW-005/FLW-006). Chamar os Flows por
 * Apex contorna o gate do componente sem mover regra de negocio: DD_CalculateQuoteMargin
 * e DD_RouteDiscountApproval continuam sendo a unica fonte de calculo e de decisao.
 *
 * Contexto de execucao (SystemModeWithSharing): Flow iniciado por Apex roda em contexto de
 * sistema e herda o sharing da classe que inicia a interview. Esta classe declara
 * `with sharing`, portanto os Flows:
 *   - ignoram CRUD/FLS do usuario (podem ler o custo do PricebookEntry, que e sensivel); e
 *   - respeitam o acesso ao registro (o vendedor so calcula cotacao que consegue ver).
 * Nenhum metadado de Flow foi alterado para isso.
 *
 * D14: a fronteira devolve apenas um DTO com whitelist de campos. Margem, custo,
 * diagnostico, piso/alvo/teto e e-mail do aprovador nunca cruzam o Apex — nem no payload
 * de retorno, nem em log.
 *
 * F5-12: depois que o Flow grava o pedido, esta classe o submete ao Approval Process nativo
 * DD_Manager_Approval. O Approval Process NAO decide margem (isso continua no Flow): ele
 * entrega ao gerente a tela "Itens para Aprovar" e grava Status__c/DecidedAt__c nas acoes
 * finais. Quem aprova e sempre o humano.
 */
public with sharing class DD_MarginConsoleController {
    private static final String FLOW_MARGIN = 'DD_CalculateQuoteMargin';
    private static final String FLOW_ROUTE = 'DD_RouteDiscountApproval';

    // F5-12: unico Approval Process ativo do objeto do pedido.
    private static final String APPROVAL_PROCESS = 'DD_Manager_Approval';

    // Limite do campo DD_DiscountRequest__c.Justification__c (LongTextArea).
    private static final Integer MAX_JUSTIFICATION_LENGTH = 32000;

    // D14: unicas variaveis de saida dos Flows que o console pode receber.
    private static final Map<String, List<String>> FLOW_OUTPUTS = new Map<String, List<String>>{
        FLOW_MARGIN => new List<String>{ 'guardrailState', 'policyName', 'decision' },
        FLOW_ROUTE => new List<String>{ 'decision', 'status', 'requestId', 'approverName', 'message' }
    };

    /**
     * Simula um desconto na cotacao sem gravar nada.
     *
     * @param quoteId              cotacao visivel para o usuario que chamou o console
     * @param requestedDiscountPct desconto simulado, entre 0 e 100
     * @return estado do guardrail, politica aplicada e decisao projetada (sem margem/custo)
     */
    @AuraEnabled
    public static SimulationResult simulate(String quoteId, Decimal requestedDiscountPct) {
        validateDiscount(requestedDiscountPct);
        Id quoteRef = validateQuote(quoteId);

        Map<String, Object> output = runFlow(
            FLOW_MARGIN,
            new Map<String, Object>{
                'quoteId' => quoteRef,
                'requestedDiscountPct' => requestedDiscountPct
            }
        );

        SimulationResult result = new SimulationResult();
        result.guardrailState = asText(output.get('guardrailState'));
        result.policyName = asText(output.get('policyName'));
        result.decision = asText(output.get('decision'));
        return result;
    }

    /**
     * Aciona o roteamento do guardrail e devolve a decisao ao vendedor.
     * A criacao/atualizacao do DD_DiscountRequest__c continua sendo responsabilidade do Flow.
     *
     * @param quoteId              cotacao visivel para o usuario que chamou o console
     * @param requestedDiscountPct desconto pedido, entre 0 e 100
     * @param justification        justificativa do vendedor (exigida conforme a politica)
     * @return decisao, status, pedido, aprovador e mensagem (sem e-mail nem diagnostico)
     */
    @AuraEnabled
    public static RoutingResult requestDiscount(
        String quoteId,
        Decimal requestedDiscountPct,
        String justification
    ) {
        validateDiscount(requestedDiscountPct);
        Id quoteRef = validateQuote(quoteId);

        String cleanJustification = String.isBlank(justification) ? '' : justification.trim();
        if (cleanJustification.length() > MAX_JUSTIFICATION_LENGTH) {
            throw new AuraHandledException(
                'A justificativa excede o limite de ' + MAX_JUSTIFICATION_LENGTH + ' caracteres.'
            );
        }

        Map<String, Object> output = runFlow(
            FLOW_ROUTE,
            new Map<String, Object>{
                'quoteId' => quoteRef,
                'requestedDiscountPct' => requestedDiscountPct,
                'justification' => cleanJustification
            }
        );

        RoutingResult result = new RoutingResult();
        result.decision = asText(output.get('decision'));
        result.status = asText(output.get('status'));
        result.requestId = asText(output.get('requestId'));
        result.approverName = asText(output.get('approverName'));
        // Falha operacional nao repassa a mensagem tecnica do Flow para a tela.
        result.message = result.decision == 'Fault'
            ? 'Falha operacional no roteamento. Nenhum pedido deve ser considerado enviado.'
            : asText(output.get('message'));

        // F5-12: o pedido tem de aparecer na tela nativa de aprovacoes do gerente.
        if ('ManagerApproval'.equals(result.decision) && String.isNotBlank(result.requestId)) {
            result.message = submitForManagerApproval(result.requestId, result.message);
        }
        return result;
    }

    /**
     * Submete o pedido recem-gravado ao Approval Process nativo (F5-12).
     *
     * O Flow continua sendo a unica fonte de decisao: aqui so se entrega o registro ja criado
     * ao unico processo ativo do objeto, para que o aprovador resolvido no campo Approver__c
     * receba o item em "Itens para Aprovar". Nenhuma decisao e tomada neste metodo.
     *
     * Se a submissao falhar, o pedido continua existindo e a tela avisa o vendedor: e melhor
     * um pedido visivel sem item de aprovacao do que um erro que faca o vendedor repetir o envio.
     *
     * @return a mensagem do Flow, acrescida do aviso quando a submissao nao conclui
     */
    private static String submitForManagerApproval(String requestId, String message) {
        try {
            Approval.ProcessSubmitRequest submission = new Approval.ProcessSubmitRequest();
            submission.setObjectId(Id.valueOf(requestId));
            submission.setProcessDefinitionNameOrId(APPROVAL_PROCESS);
            submission.setComments('Pedido encaminhado pelo console do Deal Desk.');

            Approval.ProcessResult outcome = Approval.process(submission);
            if (outcome.isSuccess()) {
                return message;
            }
            System.debug(
                LoggingLevel.ERROR,
                'DD_MarginConsoleController: submissao para aprovacao recusada.'
            );
        } catch (Exception submissionFailure) {
            // D14: so o tipo da falha vai para o log.
            System.debug(
                LoggingLevel.ERROR,
                'DD_MarginConsoleController: falha ao submeter para aprovacao (' +
                    submissionFailure.getTypeName() +
                    ')'
            );
        }
        return message +
            ' O pedido foi registrado, mas nao chegou a tela de aprovacoes: avise o aprovador.';
    }

    /**
     * Valida o desconto antes de acionar qualquer Flow (a mesma faixa que a UI oferece).
     * A mensagem vai direto para a tela do vendedor.
     */
    private static void validateDiscount(Decimal requestedDiscountPct) {
        if (requestedDiscountPct == null || requestedDiscountPct < 0 || requestedDiscountPct > 100) {
            throw new AuraHandledException('Informe um desconto entre 0 e 100.');
        }
    }

    /**
     * Confirma que a cotacao existe e e visivel para o usuario que chamou o console.
     * WITH USER_MODE aplica CRUD/FLS e o `with sharing` da classe aplica o acesso ao registro:
     * nenhum Id de cotacao fora do alcance do vendedor chega ao Flow, que roda em contexto de sistema.
     */
    private static Id validateQuote(String quoteId) {
        if (String.isBlank(quoteId)) {
            throw new AuraHandledException('Informe a cotação para executar o guardrail.');
        }

        Id quoteRef;
        try {
            quoteRef = Id.valueOf(quoteId.trim());
        } catch (Exception invalidId) {
            throw new AuraHandledException('Cotação inválida.');
        }

        List<Quote> quotes = [SELECT Id FROM Quote WHERE Id = :quoteRef WITH USER_MODE LIMIT 1];
        if (quotes.isEmpty()) {
            throw new AuraHandledException('Cotação não encontrada ou sem acesso.');
        }
        return quoteRef;
    }

    /**
     * Executa o Flow e copia SOMENTE as variaveis de saida da whitelist (D14).
     * Qualquer falha vira uma mensagem generica: o detalhe tecnico fica no log sem payload.
     */
    private static Map<String, Object> runFlow(String flowName, Map<String, Object> inputs) {
        List<String> outputs = FLOW_OUTPUTS.get(flowName);
        if (outputs == null) {
            throw new AuraHandledException('Fluxo de guardrail não suportado.');
        }

        try {
            Flow.Interview interview = Flow.Interview.createInterview(flowName, inputs);
            interview.start();

            Map<String, Object> result = new Map<String, Object>();
            for (String variableName : outputs) {
                result.put(variableName, interview.getVariableValue(variableName));
            }
            return result;
        } catch (Exception flowFailure) {
            // D14: apenas o tipo da falha vai para o log; sem payload, custo ou margem.
            System.debug(
                LoggingLevel.ERROR,
                'DD_MarginConsoleController: falha ao executar ' +
                    flowName +
                    ' (' +
                    flowFailure.getTypeName() +
                    ')'
            );
            throw new AuraHandledException('Não foi possível executar o guardrail. Tente novamente.');
        }
    }

    /**
     * Converte o Object devolvido pelo Flow em texto sem inventar valor para null.
     */
    private static String asText(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    /**
     * Saida do simulador (D14: sem margem, custo, piso, alvo, teto ou diagnostico).
     */
    public class SimulationResult {
        @AuraEnabled
        public String guardrailState { get; set; }

        @AuraEnabled
        public String policyName { get; set; }

        @AuraEnabled
        public String decision { get; set; }
    }

    /**
     * Saida do roteamento (D14: sem e-mail do aprovador e sem diagnostico).
     */
    public class RoutingResult {
        @AuraEnabled
        public String decision { get; set; }

        @AuraEnabled
        public String status { get; set; }

        @AuraEnabled
        public String requestId { get; set; }

        @AuraEnabled
        public String approverName { get; set; }

        @AuraEnabled
        public String message { get; set; }
    }
}
