/**
* @author        Dilowar
* @date          2023-08-31
* @description   Test class for CPQRenewOpportunityBatch. The test methods did exist in CPQBatchTest for this class.
*                However, as a part of SFDC-19803, the main class has been modified. So a new test class has been introduced.
* @group         Test
*
*/
@isTest
public class CPQRenewOpportunityBatchTest {
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
            StartDate = System.Today() - 20, ContractTerm = 12);
        insert testContract;
        testContract.Status = 'Activated';
        //testContract.SBQQ__ExpirationDate__c = system.today().addDays(30);
        //testContract.Auto_Renew__c = true;
        testContract.SBQQ__RenewalQuoted__c = false;
        testContract.Has_Contract_Error__c = false;
        testContract.Exclude_from_Batch__c = false;
        //testContract.Demo_Opp__c = false;
        testContract.SBQQ__RenewalForecast__c = false;
        testContract.All_Subs_RMA__c = false;
        //testContract.SBCF_EndDate__c = system.today().addDays(60);
        update testContract;

        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today() - 20); 
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
        Test.stopTest();
        
       // System.debug('##testOrder:: ' + JSON.serialize(testOrder));
       // System.debug('##queriedAccount2:: ' + JSON.serialize([Select Id, Name, Bill_To_Contact__c from Account where Id =: testOpp.Bill_To_Account__c]));
    }
    @isTest static void test_CPQRenewOpportunityBatch() {
        Test.startTest();
        List<Contract> lstCon = [select Id,AccountID, Status,SBQQ__ExpirationDate__c,Auto_Renew__c,SBQQ__RenewalQuoted__c,Demo_Opp__c,SBQQ__RenewalForecast__c,EndDate,Lead_Source__c,SBCF_EndDate__c,Has_Contract_Error__c,Contract_Error_Check__c,Business_Group__c,SBQQ__RenewalOpportunity__c,SBQQ__Order__r.OrderNumber,CreatedBy.Name,Owner.Name,(select ID from SBQQ__Subscriptions__r) from Contract where Has_Contract_Error__c = FALSE and SBQQ__RenewalQuoted__c = false and Status = 'Activated' and Auto_Renew__c = true and Exclude_from_Batch__c != true and Demo_Opp__c != true and SBQQ__RenewalForecast__c != true AND All_Subs_RMA__c  = false AND((Business_Group__c = 'Core' AND SBCF_EndDate__c >today) OR (Business_Group__c = 'MSP') OR (Business_Group__c = 'Sonian')) AND (createdBy.name != 'Legacy Load' AND Owner.Name != 'Legacy Load') order by SBQQ__Order__r.OrderNumber];
        system.debug('lstCon is:' +lstCon);
        List<Contract> lstCon02 = [select Id,AccountID, Status,SBQQ__ExpirationDate__c,Auto_Renew__c,SBQQ__RenewalQuoted__c,Demo_Opp__c,SBQQ__RenewalForecast__c,EndDate,Lead_Source__c,SBCF_EndDate__c,Has_Contract_Error__c,Contract_Error_Check__c,Business_Group__c,SBQQ__RenewalOpportunity__c,SBQQ__Order__r.OrderNumber,CreatedBy.Name,Owner.Name,(select ID from SBQQ__Subscriptions__r) from Contract];
        system.debug('lstCon02 is:' +lstCon02);    
        CPQRenewOpportunityBatchSched s = new CPQRenewOpportunityBatchSched();
            String sch ='0 0 * * * ?'; 
            System.schedule('TestCPQRenewOpportunityBatchSched', sch, s);

            CPQRenewOpportunityBatch b = new CPQRenewOpportunityBatch();
            Database.executeBatch(b, b.defaultBatchSize);
        Test.stopTest();
    }


}