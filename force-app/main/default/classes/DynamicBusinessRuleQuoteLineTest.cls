@IsTest
private class DynamicBusinessRuleQuoteLineTest {
    @testSetup static void setup() {
        Product2 testProd = TestDataFactory.products[0];
        testProd.Product_Long_Description__c = '123';
        update testProd;

        Opportunity testOpp = TestDataFactory.opportunities[0];

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Amendment');
        insert testQuote;

        Contract testContract = new Contract(AccountId = TestDataFactory.customers[0].Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, StartDate = System.Today());
        insert testContract;

        Order testOrder = TestDataFactory.orders[0];
        testOrder.Active_Contract__c = testContract.Id;
        update testOrder;

        Asset testAsset = TestDataFactory.assets[0];
        testAsset.Related_Order__c = testOrder.Id;
        update testAsset;
    }

    @IsTest
    static  void unitTest() {
        SBQQ__Quote__c testQuote = [Select ID From SBQQ__Quote__c][0];
        Asset testAsset = [Select ID From Asset][0];
        Product2 testProd = [Select ID From Product2][0];

        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 0, SBQQ__UpgradedAsset__c = testAsset.Id);
        
        test.startTest();
            insert testQuoteLine;
        test.stopTest();
    }
}