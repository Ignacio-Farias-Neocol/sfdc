@IsTest
private class DynamicBusinessRuleQuoteCoreBeforeTest {
    @testSetup static void setup() {
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        List <Account> customers = TestDataFactory.customers;
        List <Opportunity> opportunities = TestDataFactory.opportunities;
        TriggerHandler.clearAllBypasses();

        opportunities[0].Bill_To_Account__c = customers[0].Id;
        update opportunities[0];
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opportunities[0].Id, SBQQ__Primary__c = true);
        insert testQuote;
    }

    @IsTest
    static  void unitTest() {
        List<Opportunity> testOpps = [Select ID From Opportunity];
        List<SBQQ__Quote__c> testQuotes = [Select ID, SBQQ__PaymentTerms__c, ApprovalStatus__c, SBQQ__Status__c, SBQQ__Opportunity2__c From SBQQ__Quote__c];
        Test.startTest();
            testQuotes[0].SBQQ__PaymentTerms__c = 'Net 90';
            update testQuotes[0];

            testQuotes[0].ApprovalStatus__c = 'Approved';
            update testQuotes[0];
        Test.stopTest();
    }

    @IsTest
    static  void unitTestValidateSubsInRenewalQuote() {
        Product2 testProd = TestDataFactory.products[0];
        SBQQ__Quote__c testQuote = [Select ID, SBQQ__PaymentTerms__c, ApprovalStatus__c, SBQQ__Status__c, SBQQ__Opportunity2__c From SBQQ__Quote__c][0];
        Account testAccount = [Select ID From Account][0];
        Opportunity testOpp = [Select ID From Opportunity][0];

        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, StartDate = System.Today());
        insert testContract;

        List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today() - 720),
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today() - 720),
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today() - 720)
        }; 
        insert testSubs;
        testSubs[0].Renewed_By_Subscription__c = testSubs[1].Id;
        update testSubs[0];

        List<SBQQ__QuoteLine__c> testQuoteLines = new List<SBQQ__QuoteLine__c> {
            new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 0, SBQQ__RenewedSubscription__c = testSubs[0].Id)
        };
        insert testQuoteLines;
        
        Test.startTest();
            try {
                CPQ_Quote_DetailPageExt_Controller.AlertsResults r = CPQ_Quote_DetailPageExt_Controller.retrieveAlerts(testQuote.Id);

                testQuote.ApprovalStatus__c = 'Approved';
                update testQuote;

                testSubs[0].Renewed_By_Subscription__c = null;
                update testQuote;
            } catch (Exception e) {}

            try {
                testSubs[0].Renewed_By_Subscription__c = testSubs[1].Id;
                update testSubs[0];

                CPQ_Opportunity_DetailPageExt_Controller.AlertsResults r = CPQ_Opportunity_DetailPageExt_Controller.retrieveAlerts(testOpp.Id);
                
                testOpp.StageName = 'Closed Won';
                update testOpp;
            } catch (Exception e) {}

        Test.stopTest();
    }

    @IsTest
    static  void unitTestInitializeStageApprovalStatus() {
        Opportunity testOpp = [Select ID From Opportunity][0];
        Test.startTest();
            SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, ApprovalStatus__c = 'Pending');
            insert testQuote;
        Test.stopTest();
    }
}