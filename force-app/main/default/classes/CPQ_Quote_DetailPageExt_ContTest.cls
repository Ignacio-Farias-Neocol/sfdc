@isTest
private class CPQ_Quote_DetailPageExt_ContTest {
    @isTest static void myUnitTest() {
        List<Opportunity> testOpps = TestDataFactory.opportunities;
        testOpps[0].Business_Group__c = 'MSP';
        update testOpps[0];

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpps[0].Id);
        insert testQuote;

        CPQ_Quote_DetailPageExt_Controller.AlertsResults r = CPQ_Quote_DetailPageExt_Controller.retrieveAlerts(testQuote.Id);
        System.Debug(r.errorMsg);
    }

    @isTest static void testAlertOtherAmendmentQuote() {
        Opportunity testOpp = TestDataFactory.opportunities[0];
        testOpp.Business_Group__c = 'MSP';
        update testOpp;


        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Amendment');
        insert testQuote;

        Test.startTest();
            CPQ_Quote_DetailPageExt_Controller.AlertsResults r = CPQ_Quote_DetailPageExt_Controller.retrieveAlerts(testQuote.Id);
            System.Debug(r.errorMsg);
        Test.stopTest();
    }
}