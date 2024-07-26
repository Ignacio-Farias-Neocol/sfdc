/**
* @author        Ivan Yeung/salesforce services
* @date          2019-01-31
* @description   Unit Test class for CPQApproveQuoteBatch, CPQActivateOrderBatch, CPQRenewOpportunityBatch, CPQRenewQuoteBatch
* @group         Test
*
*/
@isTest
public with sharing class CPQBatchTest {

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

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Renewal');
        insert testQuote;

        Order testOrder = TestDataFactory.orders[0];
        testOrder.OpportunityId = testOpp.Id;
        testOrder.Contract_Error_Check__c = '123';
        testOrder.BillingCity = 'Denver';
        testOrder.BillingPostalCode = '80000';
        testOrder.BillingState = 'Colorado';
        testOrder.BillingCountry = 'United States';
        testOrder.ShippingCity = 'Denver';
        testOrder.ShippingPostalCode = '80000';
        testOrder.ShippingState = 'Colorado';
        testOrder.ShippingCountry = 'United States';
        update testOrder;
        
       // System.debug('##testOrder:: ' + JSON.serialize(testOrder));
       // System.debug('##queriedAccount2:: ' + JSON.serialize([Select Id, Name, Bill_To_Contact__c from Account where Id =: testOpp.Bill_To_Account__c]));
    }

    @isTest static void test_CPQRenewOpportunityBatch() {
        Test.startTest();
            CPQRenewOpportunityBatchSched s = new CPQRenewOpportunityBatchSched();
            String sch ='0 0 * * * ?'; 
            System.schedule('TestCPQRenewOpportunityBatchSched', sch, s);

            CPQRenewOpportunityBatch b = new CPQRenewOpportunityBatch();
            Database.executeBatch(b, b.defaultBatchSize);
        Test.stopTest();
    }

    @isTest static void test_CPQRenewQuoteBatch() {
        Test.startTest();
            CPQRenewQuoteBatchSched s = new CPQRenewQuoteBatchSched();
            String sch ='0 0 * * * ?'; 
            System.schedule('TestCPQRenewQuoteBatchSched', sch, s);
            
            CPQRenewQuoteBatch b = new CPQRenewQuoteBatch();
            Database.executeBatch(b, b.defaultBatchSize);
        Test.stopTest();
    }

    @isTest static void test_CPQApproveQuoteBatch() {
        Test.startTest();
            CPQApproveQuoteBatchSched s = new CPQApproveQuoteBatchSched();
            String sch ='0 0 * * * ?'; 
            System.schedule('TestCPQApproveQuoteBatchSched', sch, s);
            
            CPQApproveQuoteBatch b = new CPQApproveQuoteBatch();
            Database.executeBatch(b, b.defaultBatchSize);
        Test.stopTest();
    }

    @isTest static void test_CPQCloseOpportunityBatch() {
        Test.startTest();
            SBQQ__Quote__c testQuote = [Select ID From SBQQ__Quote__c];
            testQuote.ApprovalStatus__c = 'Approved';
            testQuote.Has_Contract_Error__c = FALSE;
            update testQuote;

            CPQCloseOpportunityBatchSched s = new CPQCloseOpportunityBatchSched();
            String sch ='0 0 * * * ?'; 
            System.schedule('TestCPQCloseOpportunityBatchSched', sch, s);
            
            CPQCloseOpportunityBatch b = new CPQCloseOpportunityBatch();
            Database.executeBatch(b, b.defaultBatchSize);
        Test.stopTest();
    }

    @isTest static void test_CPQActivateOrderBatch() {
        Test.startTest();
            CPQActivateOrderBatchSched s = new CPQActivateOrderBatchSched();
            String sch ='0 0 * * * ?'; 
            System.schedule('TestCPQActivateOrderBatchSched', sch, s);
            
            CPQActivateOrderBatch b = new CPQActivateOrderBatch();
            Database.executeBatch(b, b.defaultBatchSize);
        Test.stopTest();
    }

    @isTest static void test_CPQPlaceOrderBatch() {
    
    Test.startTest();
        Order testOrder = [Select ID, OpportunityId, Opportunity.Bill_To_Account__c From Order];

        // update Account Bill to Contact         
        Account accountRecord = [Select Id, Bill_To_Contact__c from Account where Id =: testOrder.Opportunity.Bill_To_Account__c];
        accountRecord.Bill_To_Contact__c = 'Test Test';
         System.Debug('SOQL Limit 1#-' + Limits.getQueries());
        update accountRecord;
         System.Debug('SOQL Limit 2#-' + Limits.getQueries());
        
        testOrder.Status = 'Activated';
        testOrder.SBQQ__Contracted__c = true;
        testOrder.BillingStreet = '123 Main Street';
        testOrder.ShippingStreet = '123 Main Street';
        testOrder.Bill_To_Contact__c = 'Test Test';
        testOrder.Bill_To_Contact_Email__c = '123@123.com';
        testOrder.Ship_To_Contact__c = 'Test Test';
        testOrder.Ship_To_Contact_Email__c = '123@123.com';
        testOrder.Contracted_Date_Time__c = System.now();
         System.Debug('SOQL Limit 3#-' + Limits.getQueries());
        update testOrder;
         System.Debug('SOQL Limit 4#-' + Limits.getQueries());
        
        System.debug('##testOrder2:: ' + JSON.serialize(testOrder));

        

       // Test.startTest();
            CPQPlaceOrderBatchSched s = new CPQPlaceOrderBatchSched();
            String sch ='0 0 * * * ?'; 
            System.schedule('TestCPQPlaceOrderBatchSched', sch, s);

            CPQPlaceOrderBatch b1 = new CPQPlaceOrderBatch();
            Database.executeBatch(b1);
        Test.stopTest();
    }
}