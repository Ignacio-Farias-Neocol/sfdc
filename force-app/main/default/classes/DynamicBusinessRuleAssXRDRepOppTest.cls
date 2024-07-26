@IsTest
public with sharing class DynamicBusinessRuleAssXRDRepOppTest {
    
    public testMethod static void testAssignXDRRep(){
        try{
            Product2 testProd = TestDataFactory.products[0];
            testProd.SBCF_Is_Shipped__c = TRUE;
            update testProd;
            Opportunity testOpp = TestDataFactory.opportunities[0];
            SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true);
            insert testQuote;
            Test.startTest();
            List<Opportunity> lstOpp = [select id, name, SBQQ__PrimaryQuote__c from Opportunity where id = :testOpp.id];
            lstOpp[0].SBQQ__PrimaryQuote__c = testQuote.id;
            lstOpp[0].Business_Group__c = 'MSP';
            update lstOpp;
            Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception occurred at:' +e.getStackTraceString());
        }
    }
}