/**
* @author        Sonal Agrawal(bluvium)
* @date          16th October 2023
* @description   Unit Test class for CPQAccountPartnerChangeOnQuoteBatch,CPQAccountPartnerChangeOnQuoteBatchSched
* @group         Test
*
*/
@isTest
public class CPQAccountPartnerChangeOnQuoteTest {
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
        testAccount.Partner_Level__c = 'Authorized';
        testAccount.IsPartnerLevelChange__c =true;
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
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBCF_Reseller__c=testAccount.id, SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Renewal');
        insert testQuote;
        Test.stopTest();
    }
    @isTest static void test_CPQAccountPartnerChangeOnQuoteBatch() {
        Test.startTest();
        CPQAccountPartnerChangeOnQuoteBatchSched s = new CPQAccountPartnerChangeOnQuoteBatchSched();
        String sch ='0 0 * * * ?'; 
        System.schedule('CPQAccountPartnerChangeOnQuoteBatch', sch, s);
        
        CPQAccountPartnerChangeOnQuoteBatch b = new CPQAccountPartnerChangeOnQuoteBatch();
        Database.executeBatch(b, b.defaultBatchSize);
        Test.stopTest();
    }
}