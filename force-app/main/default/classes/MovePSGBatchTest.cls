@isTest
private  class MovePSGBatchTest {

    @testSetup static void setup() {
        Product2 testProd = TestDataFactory.products[0];
        testProd.Product_Long_Description__c = '123';
        update testProd;

        Opportunity testOpp = TestDataFactory.opportunities[0];

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Amendment');
        insert testQuote;       
    }

    @IsTest
    static  void unitTest() {
        SBQQ__Quote__c testQuote = [Select ID From SBQQ__Quote__c][0];
        testQuote.SBQQ__Primary__c=true;
        update testQuote;

        Product2 testProd = [Select ID From Product2][0];

        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 0);

        Test.startTest();
        
        insert testQuoteLine;             

        MovePSGBatch psg=new MovePSGBatch();

        Test.stopTest();       

    }
}