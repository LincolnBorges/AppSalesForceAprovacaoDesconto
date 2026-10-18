/**
 * DD_MarginConsoleControllerTest
 *
 * Cobre o contrato do controller do console (F5-11):
 *   - caminho feliz do simulador e do roteamento (acima do alvo e abaixo do piso);
 *   - justificativa exigida pela politica;
 *   - entradas invalidas (cotacao e desconto);
 *   - execucao com usuario NAO-ADMIN, que e a razao de existir da classe;
 *   - D14: margem, custo, diagnostico e e-mail do aprovador nao cruzam o Apex.
 *
 * Dados de teste criados aqui (TEST-) nao dependem da massa DEMO- da org.
 */
@IsTest
private class DD_MarginConsoleControllerTest {
    private static final String FAMILY = 'Parts';
    private static final String POLICY_NAME = 'TEST-Policy-Parts-Console';
    private static final String HEALTHY_PRODUCT = 'TEST-Product-Healthy';
    private static final String BELOW_PRODUCT = 'TEST-Product-Below-Floor';
    private static final String HEALTHY_QUOTE = 'TEST-Quote-Healthy';
    private static final String BELOW_QUOTE = 'TEST-Quote-Below-Floor';
    private static final String SELLER_USERNAME_PREFIX = 'dd.console.seller.';

    @TestSetup
    static void makeData() {
        Id standardPricebookId = Test.getStandardPricebookId();

        List<Product2> products = new List<Product2>{
            new Product2(Name = HEALTHY_PRODUCT, Family = FAMILY, IsActive = true),
            new Product2(Name = BELOW_PRODUCT, Family = FAMILY, IsActive = true)
        };
        insert products;

        PricebookEntry healthyEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = products[0].Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD',
            FixedCost__c = 60,
            VariableCostPerUnit__c = 0
        );
        PricebookEntry belowEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = products[1].Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'USD',
            FixedCost__c = 90,
            VariableCostPerUnit__c = 0
        );
        insert new List<PricebookEntry>{ healthyEntry, belowEntry };

        // Politica especifica da familia + price book (nivel L3 do Flow).
        insert new DD_DiscountPolicy__c(
            Name = POLICY_NAME,
            ProductFamily__c = FAMILY,
            Pricebook__c = standardPricebookId,
            FloorMarginPct__c = 20,
            TargetMarginPct__c = 30,
            MaxDiscountPct__c = 10,
            EffectiveFrom__c = Date.today().addDays(-1),
            IsActive__c = true,
            RequiresJustification__c = true,
            CurrencyIsoCode = 'USD'
        );

        Quote healthyQuote = new Quote(
            Name = HEALTHY_QUOTE,
            Pricebook2Id = standardPricebookId,
            CurrencyIsoCode = 'USD',
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(30)
        );
        Quote belowQuote = new Quote(
            Name = BELOW_QUOTE,
            Pricebook2Id = standardPricebookId,
            CurrencyIsoCode = 'USD',
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(30)
        );
        insert new List<Quote>{ healthyQuote, belowQuote };

        // O before-save DD_CalculateLineCost grava o custo da linha a partir do PricebookEntry.
        insert new List<QuoteLineItem>{
            new QuoteLineItem(
                QuoteId = healthyQuote.Id,
                PricebookEntryId = healthyEntry.Id,
                Product2Id = products[0].Id,
                Quantity = 1,
                UnitPrice = 100,
                Discount = 0
            ),
            new QuoteLineItem(
                QuoteId = belowQuote.Id,
                PricebookEntryId = belowEntry.Id,
                Product2Id = products[1].Id,
                Quantity = 1,
                UnitPrice = 100,
                Discount = 0
            )
        };

        insert buildSellerUser();
        PermissionSet appAccess = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'DD_DealDesk_User'
            LIMIT 1
        ];
        insert new PermissionSetAssignment(AssigneeId = sellerUser().Id, PermissionSetId = appAccess.Id);
    }

    // ---------------------------------------------------------------------
    // Simulador
    // ---------------------------------------------------------------------

    @IsTest
    static void simulate_healthyQuote_returnsWhitelistedState() {
        Quote quote = quoteByName(HEALTHY_QUOTE);

        Test.startTest();
        DD_MarginConsoleController.SimulationResult result = DD_MarginConsoleController.simulate(quote.Id, 0);
        Test.stopTest();

        System.assertEquals('Saudável', result.guardrailState, 'Margem de 40% deve ficar no alvo.');
        System.assertEquals('AutoApproved', result.decision, 'Acima do alvo nao exige pedido.');
        System.assertEquals(POLICY_NAME, result.policyName, 'A politica da familia deve ser aplicada.');

        String payload = JSON.serialize(result);
        System.assert(!payload.contains('marginBp'), 'D14: margem nao pode cruzar o Apex.');
        System.assert(!payload.contains('worstLineBp'), 'D14: pior linha nao pode cruzar o Apex.');
        System.assert(!payload.contains('diagnostics'), 'D14: diagnostico nao pode cruzar o Apex.');
        System.assert(!payload.contains('cost'), 'D14: custo nao pode cruzar o Apex.');
    }

    @IsTest
    static void simulate_belowFloor_returnsApprovalState() {
        Quote quote = quoteByName(BELOW_QUOTE);

        Test.startTest();
        DD_MarginConsoleController.SimulationResult result = DD_MarginConsoleController.simulate(quote.Id, 0);
        Test.stopTest();

        System.assertEquals('Requer Aprovação', result.guardrailState, 'Margem de 10% fica abaixo do piso.');
        System.assertEquals('ManagerApproval', result.decision, 'Abaixo do piso exige aprovacao.');
    }

    @IsTest
    static void simulate_worksForNonAdminSeller() {
        User seller = sellerUser();
        Quote quote = createQuoteOwnedBy(seller.Id, HEALTHY_PRODUCT, 'TEST-Quote-Seller-Healthy');

        System.runAs(seller) {
            Test.startTest();
            DD_MarginConsoleController.SimulationResult result = DD_MarginConsoleController.simulate(quote.Id, 10);
            Test.stopTest();

            // 100 de receita, custo 60, desconto de 10% -> margem 33,33% (ainda no alvo).
            System.assertEquals('Saudável', result.guardrailState, 'O vendedor nao-admin deve simular.');
            System.assertEquals(POLICY_NAME, result.policyName, 'A politica deve ser aplicada ao vendedor.');
        }
    }

    @IsTest
    static void simulate_rejectsInvalidDiscount() {
        Quote quote = quoteByName(HEALTHY_QUOTE);

        for (Decimal invalidDiscount : new List<Decimal>{ -1, 100.01, null }) {
            try {
                DD_MarginConsoleController.simulate(quote.Id, invalidDiscount);
                System.assert(false, 'Desconto invalido deveria falhar: ' + invalidDiscount);
            } catch (AuraHandledException expected) {
                System.assertNotEquals(null, expected.getMessage(), 'A falha deve ter mensagem para a tela.');
            }
        }
    }

    @IsTest
    static void simulate_rejectsInvalidQuote() {
        // 15 caracteres com o prefixo de Quote (0Q0), mas sem registro correspondente.
        String unknownQuoteId = '0Q0' + '0'.repeat(12);

        for (String invalidQuoteId : new List<String>{ null, '', '   ', 'not-an-id', unknownQuoteId }) {
            try {
                DD_MarginConsoleController.simulate(invalidQuoteId, 0);
                System.assert(false, 'Cotacao invalida deveria falhar: ' + invalidQuoteId);
            } catch (AuraHandledException expected) {
                System.assertNotEquals(null, expected.getMessage(), 'A falha deve ter mensagem para a tela.');
            }
        }
    }

    // ---------------------------------------------------------------------
    // Roteamento
    // ---------------------------------------------------------------------

    @IsTest
    static void requestDiscount_belowFloor_createsSubmittedRequest() {
        Quote quote = quoteByName(BELOW_QUOTE);

        Test.startTest();
        DD_MarginConsoleController.RoutingResult result = DD_MarginConsoleController.requestDiscount(
            quote.Id,
            5,
            'Cliente pediu desconto comercial para fechar o trimestre.'
        );
        Test.stopTest();

        System.assertEquals('ManagerApproval', result.decision, 'Abaixo do piso o pedido sobe.');
        System.assertEquals('Submitted', result.status, 'O pedido deve ficar submetido.');
        System.assertNotEquals(null, result.requestId, 'O Flow deve criar o pedido de desconto.');
        System.assertNotEquals(null, result.approverName, 'O Flow deve resolver o aprovador.');

        List<DD_DiscountRequest__c> requests = [
            SELECT Id, Decision__c, Status__c, Justification__c
            FROM DD_DiscountRequest__c
            WHERE Quote__c = :quote.Id
        ];
        System.assertEquals(1, requests.size(), 'Um pedido deve existir para a cotacao.');
        System.assertEquals('ManagerApproval', requests[0].Decision__c, 'Decisao gravada pelo Flow.');
        System.assertEquals('Submitted', requests[0].Status__c, 'Status gravado pelo Flow.');

        // F5-12: o pedido tem de chegar na tela nativa do aprovador.
        List<ProcessInstanceWorkitem> workitems = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :requests[0].Id
        ];
        System.assertEquals(1, workitems.size(), 'O pedido deve aparecer em "Itens para Aprovar".');

        String payload = JSON.serialize(result);
        System.assert(!payload.contains('approverEmail'), 'D14: e-mail do aprovador nao vai para a tela.');
        System.assert(!payload.contains('diagnostics'), 'D14: diagnostico nao vai para a tela.');
        System.assert(!payload.contains('marginBp'), 'D14: margem nao vai para a tela.');
    }

    @IsTest
    static void requestDiscount_healthyQuote_autoApprovesWithoutRequest() {
        Quote quote = quoteByName(HEALTHY_QUOTE);

        Test.startTest();
        DD_MarginConsoleController.RoutingResult result = DD_MarginConsoleController.requestDiscount(
            quote.Id,
            0,
            null
        );
        Test.stopTest();

        System.assertEquals('AutoApproved', result.decision, 'Acima do alvo nao gera pedido.');
        System.assertEquals('AutoApproved', result.status, 'Status devolvido pelo Flow.');
        System.assertEquals(null, result.requestId, 'Nenhum pedido deve ser criado.');

        Integer requestCount = [
            SELECT COUNT()
            FROM DD_DiscountRequest__c
            WHERE Quote__c = :quote.Id
        ];
        System.assertEquals(0, requestCount, 'Cotacao saudavel nao deve ter pedido.');
    }

    @IsTest
    static void requestDiscount_withoutJustification_isRejected() {
        Quote quote = quoteByName(BELOW_QUOTE);

        Test.startTest();
        DD_MarginConsoleController.RoutingResult result = DD_MarginConsoleController.requestDiscount(
            quote.Id,
            5,
            '   '
        );
        Test.stopTest();

        System.assertEquals('Rejected', result.status, 'Sem justificativa o Flow rejeita o pedido.');
        System.assertEquals(null, result.requestId, 'Pedido rejeitado nao deve ser criado.');

        Integer requestCount = [
            SELECT COUNT()
            FROM DD_DiscountRequest__c
            WHERE Quote__c = :quote.Id
        ];
        System.assertEquals(0, requestCount, 'A politica exige justificativa.');
    }

    @IsTest
    static void requestDiscount_worksForNonAdminSeller() {
        User seller = sellerUser();
        Quote quote = createQuoteOwnedBy(seller.Id, BELOW_PRODUCT, 'TEST-Quote-Seller-Below');
        Id approvedRequestId;

        System.runAs(seller) {
            Test.startTest();
            DD_MarginConsoleController.RoutingResult result = DD_MarginConsoleController.requestDiscount(
                quote.Id,
                5,
                'Desconto solicitado pelo cliente.'
            );
            Test.stopTest();

            System.assertEquals('ManagerApproval', result.decision, 'O vendedor nao-admin deve rotear.');
            System.assertEquals('Submitted', result.status, 'O pedido deve ficar submetido.');
            System.assertNotEquals(null, result.requestId, 'O pedido deve ser criado para o vendedor.');
            approvedRequestId = (Id) result.requestId;
        }

        // F5-12: a submissao ao Approval Process tem de funcionar tambem para o vendedor.
        List<ProcessInstanceWorkitem> workitems = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :approvedRequestId
        ];
        System.assertEquals(1, workitems.size(), 'O vendedor nao-admin deve alimentar a fila do aprovador.');
    }

    @IsTest
    static void requestDiscount_rejectsInvalidInput() {
        Quote quote = quoteByName(HEALTHY_QUOTE);

        try {
            DD_MarginConsoleController.requestDiscount(quote.Id, -0.01, 'x');
            System.assert(false, 'Desconto negativo deveria falhar.');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected.getMessage(), 'A falha deve ter mensagem para a tela.');
        }

        try {
            DD_MarginConsoleController.requestDiscount('not-an-id', 5, 'x');
            System.assert(false, 'Cotacao invalida deveria falhar.');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected.getMessage(), 'A falha deve ter mensagem para a tela.');
        }

        try {
            DD_MarginConsoleController.requestDiscount(quote.Id, 5, 'a'.repeat(32001));
            System.assert(false, 'Justificativa acima do limite deveria falhar.');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected.getMessage(), 'A falha deve ter mensagem para a tela.');
        }
    }

    // ---------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------

    private static Quote quoteByName(String name) {
        return [SELECT Id, Name FROM Quote WHERE Name = :name LIMIT 1];
    }

    private static User sellerUser() {
        String usernamePattern = SELLER_USERNAME_PREFIX + '%';
        return [SELECT Id FROM User WHERE Username LIKE :usernamePattern LIMIT 1];
    }

    private static User buildSellerUser() {
        Profile standardUser = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        return new User(
            FirstName = 'Test',
            LastName = 'Seller',
            Alias = 'tseller',
            Email = 'dd.console.seller@example.com',
            Username = SELLER_USERNAME_PREFIX + DateTime.now().getTime() + '@example.com',
            ProfileId = standardUser.Id,
            TimeZoneSidKey = 'America/Sao_Paulo',
            LocaleSidKey = 'pt_BR',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'pt_BR'
        );
    }

    /**
     * Cria uma cotacao com o vendedor como dono (visivel para ele por sharing).
     * A cotacao e criada pelo usuario de teste; o dono e quem vai operar o console.
     */
    private static Quote createQuoteOwnedBy(Id ownerId, String productName, String quoteName) {
        Id standardPricebookId = Test.getStandardPricebookId();
        Product2 product = [SELECT Id FROM Product2 WHERE Name = :productName LIMIT 1];
        PricebookEntry entry = [
            SELECT Id
            FROM PricebookEntry
            WHERE Pricebook2Id = :standardPricebookId AND Product2Id = :product.Id
            LIMIT 1
        ];

        Quote quote = new Quote(
            Name = quoteName,
            OwnerId = ownerId,
            Pricebook2Id = standardPricebookId,
            CurrencyIsoCode = 'USD',
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(30)
        );
        insert quote;

        insert new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = entry.Id,
            Product2Id = product.Id,
            Quantity = 1,
            UnitPrice = 100,
            Discount = 0
        );
        return quote;
    }
}
