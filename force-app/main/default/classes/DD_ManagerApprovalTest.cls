/**
 * DD_ManagerApprovalTest
 *
 * Prova o caminho de decisao humana entregue na F5-12 (Approval Process DD_Manager_Approval):
 *   - o pedido em Status Submitted e submetido ao processo;
 *   - o aprovador resolvido no campo Approver__c recebe o item em "Itens para Aprovar";
 *   - APROVAR grava Status = Approved e DecidedAt__c;
 *   - REJEITAR grava Status = Rejected e DecidedAt__c;
 *   - as regras de validacao do objeto nao bloqueiam as acoes finais do processo.
 *
 * O teste nao depende da massa DEMO- e nao deixa residuo: os dados ficam no rollback do teste.
 */
@IsTest
private class DD_ManagerApprovalTest {
    private static final String PROCESS_NAME = 'DD_Manager_Approval';
    private static final String APPROVER_USERNAME_PREFIX = 'dd.approval.approver.';

    @TestSetup
    static void makeData() {
        Profile standardUser = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User approver = new User(
            FirstName = 'Test',
            LastName = 'Approver',
            Alias = 'tapprov',
            Email = 'dd.approval.approver@example.com',
            Username = APPROVER_USERNAME_PREFIX + DateTime.now().getTime() + '@example.com',
            ProfileId = standardUser.Id,
            TimeZoneSidKey = 'America/Sao_Paulo',
            LocaleSidKey = 'pt_BR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'pt_BR'
        );
        insert approver;

        // O aprovador precisa enxergar o pedido para abri-lo na tela de aprovacoes.
        insert new PermissionSetAssignment(
            AssigneeId = approver.Id,
            PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'DD_DealDesk_User' LIMIT 1].Id
        );
    }

    @IsTest
    static void approval_writesApprovedAndDecisionDate() {
        User approver = approverUser();
        DD_DiscountRequest__c request = insertRequest(approver.Id);
        submit(request.Id);

        ProcessInstanceWorkitem item = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :request.Id
            LIMIT 1
        ];
        Id workitemId = item.Id;

        System.runAs(approver) {
            Test.startTest();
            Approval.ProcessResult result = decide(workitemId, 'Approve');
            Test.stopTest();
            System.assert(result.isSuccess(), 'A aprovacao deve concluir: ' + result.getErrors());
        }

        DD_DiscountRequest__c decided = [
            SELECT Status__c, DecidedAt__c
            FROM DD_DiscountRequest__c
            WHERE Id = :request.Id
        ];
        System.assertEquals('Approved', decided.Status__c, 'Aprovar deve gravar Status = Approved.');
        System.assertNotEquals(null, decided.DecidedAt__c, 'Aprovar deve gravar a data da decisao.');
    }

    @IsTest
    static void rejection_writesRejectedAndDecisionDate() {
        User approver = approverUser();
        DD_DiscountRequest__c request = insertRequest(approver.Id);
        submit(request.Id);

        ProcessInstanceWorkitem item = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :request.Id
            LIMIT 1
        ];
        Id workitemId = item.Id;

        System.runAs(approver) {
            Test.startTest();
            Approval.ProcessResult result = decide(workitemId, 'Reject');
            Test.stopTest();
            System.assert(result.isSuccess(), 'A rejeicao deve concluir: ' + result.getErrors());
        }

        DD_DiscountRequest__c decided = [
            SELECT Status__c, DecidedAt__c
            FROM DD_DiscountRequest__c
            WHERE Id = :request.Id
        ];
        System.assertEquals('Rejected', decided.Status__c, 'Rejeitar deve gravar Status = Rejected.');
        System.assertNotEquals(null, decided.DecidedAt__c, 'Rejeitar deve gravar a data da decisao.');
    }

    // ---------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------

    private static User approverUser() {
        String usernamePattern = APPROVER_USERNAME_PREFIX + '%';
        return [SELECT Id FROM User WHERE Username LIKE :usernamePattern LIMIT 1];
    }

    private static DD_DiscountRequest__c insertRequest(Id approverId) {
        // Quote__c e GuardrailState__c sao obrigatorios no objeto.
        Quote quote = new Quote(
            Name = 'TEST-Quote-Approval',
            Pricebook2Id = Test.getStandardPricebookId(),
            CurrencyIsoCode = 'USD',
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(30)
        );
        insert quote;

        DD_DiscountRequest__c request = new DD_DiscountRequest__c(
            Quote__c = quote.Id,
            GuardrailState__c = 'Requer Aprovação',
            Status__c = 'Submitted',
            Decision__c = 'ManagerApproval',
            Approver__c = approverId,
            Justification__c = 'Pedido de teste do Approval Process.',
            CurrencyIsoCode = 'USD'
        );
        insert request;
        return request;
    }

    private static void submit(Id requestId) {
        Approval.ProcessSubmitRequest submission = new Approval.ProcessSubmitRequest();
        submission.setObjectId(requestId);
        submission.setProcessDefinitionNameOrId(PROCESS_NAME);

        Approval.ProcessResult result = Approval.process(submission);
        System.assert(result.isSuccess(), 'A submissao deve concluir: ' + result.getErrors());
    }

    private static Approval.ProcessResult decide(Id workitemId, String action) {
        Approval.ProcessWorkitemRequest decision = new Approval.ProcessWorkitemRequest();
        decision.setAction(action);
        decision.setWorkitemId(workitemId);
        decision.setComments('Decisao do teste automatizado.');
        return Approval.process(decision);
    }
}
