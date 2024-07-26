@isTest
private class CPQ_Opportunity_DetailPageExt_ContTest {
    @isTest static void myUnitTest() {
        Contract testContract = new Contract(AccountId = TestDataFactory.customers[0].Id);
        insert testContract;
    
        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id);
        insert testSub;
    
        List<Opportunity> testOpps = TestDataFactory.opportunities;

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpps[0].Id, SBQQ__Primary__c = true);
        insert testQuote;

        Test.startTest();
            SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Product__c = TestDataFactory.products[0].Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuote.Id, SBQQ__RenewedSubscription__c = testSub.Id, SBQQ__EndDate__c = System.Today() + 1, SBCF_Form_Factor__c = 'SaaS', SBQQ__DefaultSubscriptionTerm__c = 1);
            insert testQuoteLine;

            CPQ_Opportunity_DetailPageExt_Controller.AlertsResults r = CPQ_Opportunity_DetailPageExt_Controller.retrieveAlerts(testOpps[0].Id);
            System.Debug(r.errorMsg);
        Test.stopTest();
    }

    @isTest static void testAlertOtherAmendmentQuote() {
        Opportunity testOpp = TestDataFactory.opportunities[0];
        testOpp.Business_Group__c = 'MSP';
        update testOpp;

        List<SBQQ__Quote__c> testQuotes = new List<SBQQ__Quote__c> {
            new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Amendment'),
            new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = false, SBQQ__Type__c = 'Amendment')
        };
        insert testQuotes;

        Test.startTest();
            CPQ_Opportunity_DetailPageExt_Controller.AlertsResults r = CPQ_Opportunity_DetailPageExt_Controller.retrieveAlerts(testOpp.Id);
            System.Debug(r.errorMsg);
        Test.stopTest();
    }
}