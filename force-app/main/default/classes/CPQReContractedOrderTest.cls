/**
* @author        Sonal Agrawal(Bluvium)
* @date          16th October 2023
* @description   Unit Test class for CPQReContractedOrderBatch,CPQReContractedOrderScheduled
* @group         Test
*
*/
@isTest
public class CPQReContractedOrderTest {
    @testSetup
    static void setup() {
        Product2 testProd = TestDataFactory.products[0];
        testProd.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testProd.SBQQ__SubscriptionTerm__c = 1;
        update testProd;
        
        Account testAccount = TestDataFactory.customers[0];
        testAccount.SBQQ__RenewalPricingMethod__c = 'Same';
        testAccount.Bill_To_Contact__c = 'Test Test';
        testAccount.Bill_To_Email__c = '123@123.com';
        update testAccount;
        
        System.debug('##testAccount:: ' + JSON.serialize(testAccount));
        
        Contract testContract = new Contract(AccountId = testAccount.Id, 
                                             Business_Group__c = 'MSP', 
                                             SBQQ__RenewalPricebookId__c = '01sf2000003FSkFAAW', 
                                             SBQQ__RenewalOpportunityRecordTypeId__c = '012f2000001261kAAA', 
                                             SBQQ__RenewalOpportunityStage__c = 'Not Contacted', 
                                             StartDate = System.Today() - 720, ContractTerm = 12);
        insert testContract;
        testContract.Status = 'Activated';
        update testContract;
        
        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today() - 720); 
        insert testSub;
        
        Opportunity testOpp = TestDataFactory.opportunities[0];
        testOpp.RecordTypeID = '012f2000001261kAAA';
        testOpp.Business_Group__c = 'MSP';
        testOpp.CloseDate = System.Today();
        testOpp.SBQQ__RenewedContract__c = testContract.Id;
        testOpp.SBQQ__Renewal__c = true;
        testOpp.Contract_Error_Check__c = '123';
        testOpp.Bill_To_Account__c = testAccount.Id;
        update testOpp;   
        Test.startTest();
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Renewal', SBQQ__EndDate__c = System.today() + 1);
        insert testQuote;
        SBQQ.TriggerControl.disable();
        try {
            Order testOrder = TestDataFactory.orders[0];
            testOrder.SBQQ__Quote__c = testQuote.Id;
            testOrder.OpportunityId = testOpp.Id;
            testOrder.Contract_Error_Check__c = '123';
            testOrder.BillingCity = 'Denver';
            testOrder.BillingPostalCode = '80000';
            testOrder.BillingState = 'Colorado';
            testOrder.BillingCountry = 'United States';
            testOrder.BillingStreet= '123 test';
            testOrder.ShippingCity = 'Denver';
            testOrder.ShippingStreet= '123 test';
            testOrder.ShippingPostalCode = '80000';
            testOrder.ShippingState = 'Colorado';
            testOrder.ShippingCountry = 'United States';
            testOrder.SBQQ__Contracted__c = true;
            testOrder.Status = 'Activated';
            testOrder.Skout_Legacy_Order__c=true;
            testOrder.Bill_To_Contact__c= 'test test';
            testOrder.Bill_To_Contact_Email__c = 'Test@gmail.com';
            testOrder.Ship_To_Contact__c= 'test test';
            testOrder.Ship_To_Contact_Email__c = 'Test@gmail.com';
            update testOrder;} finally {
                SBQQ.TriggerControl.enable();
            }
        Test.stopTest();
    }
    @isTest static void test_CPQReContractedOrderBatch() {
        Test.startTest();
        /*Order o= [Select id,Active_Contract__c  from order where SBQQ__Contracted__c=true limit 1];
        o.Active_Contract__c = null;
        o.Has_Contract_Error__c = FALSE;
        update o;*/
        CPQReContractedOrderBatchSched s = new CPQReContractedOrderBatchSched();
        String sch ='0 0 * * * ?'; 
        System.schedule('CPQReContractedOrderBatchSched', sch, s);
        
        CPQReContractedOrderBatch b = new CPQReContractedOrderBatch();
        Database.executeBatch(b, b.defaultBatchSize);
        Test.stopTest();
    }
}