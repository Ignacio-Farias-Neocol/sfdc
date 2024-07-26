/*
Yuli 10/1/2019 Removed from PB. moved to contract trigger, DynamicBusinessRuleContract class
 */
@isTest
private class CPQ_RenewalOpportunityNamingTest {
    @isTest static void myUnitTest() {
        /*
        List <Contact> contacts = TestDataFactory.customerContacts;
        List <Account> customers = TestDataFactory.customers;
        List <Account> partners = TestDataFactory.partners;
        List <Product2> products = TestDataFactory.products;
        List <Opportunity> opportunities = TestDataFactory.opportunities;
        TriggerHandler.clearAllBypasses();

        Contract testContract = new Contract(AccountId = opportunities[0].accountId, SBQQ__MasterContract__c = true);
        insert testContract;

        opportunities[0].SBQQ__RenewedContract__c = testContract.Id;
        update opportunities[0];

        testContract.SBQQ__RenewalOpportunity__c = opportunities[0].Id;
        update testContract;

        CPQ_RenewalOpportunityNaming.process(new List<Id> {testContract.Id});
        */
        CPQ_RenewalOpportunityNaming.process(null);
    }
}