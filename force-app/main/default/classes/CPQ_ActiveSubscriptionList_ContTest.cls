@isTest
private class CPQ_ActiveSubscriptionList_ContTest {
    @testSetup static void setup() {
        Account testAcount = TestDataFactory.customers[0];

        Contract testContract = new Contract(AccountId = testAcount.Id, Business_Group__c = 'MSP', StartDate = System.Today());
        insert testContract;

        List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAcount.Id, SBCF_Serial_Number__c = '123'),
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAcount.Id, SBCF_Serial_Number__c = '123'),
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAcount.Id, SBCF_Serial_Number__c = '123'),
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAcount.Id, SBCF_Serial_Number__c = '123')
        }; 
        insert testSubs;
    }

    @isTest static void unitTest() {
        Account testAcount = [Select ID From Account LIMIT 1];
        Test.startTest();
            CPQ_ActiveSubscriptionList_Controller.SubscriptionResults r = CPQ_ActiveSubscriptionList_Controller.retrieveSubscriptions('001000000000000000');
            
            r = CPQ_ActiveSubscriptionList_Controller.retrieveSubscriptions(testAcount.Id);
            System.Debug(r.errorMsg);
        Test.stopTest();
    }
}