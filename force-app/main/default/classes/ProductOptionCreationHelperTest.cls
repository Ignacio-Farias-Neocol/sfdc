@isTest
public class ProductOptionCreationHelperTest {
	
    @isTest
    static void createProductOptionsTest(){
        Product2 prod = new Product2();
        prod.Name = 'test';
        prod.Family = 'Cloud Archiving';
        insert prod;
        
        SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c();
        prodOption.SBQQ__ConfiguredSKU__c = prod.Id;
        prodOption.SBQQ__Number__c = 1;
        insert prodOption;
        
        Test.startTest();
        ProductOptionCreationBatch batch = new ProductOptionCreationBatch('Cloud Archiving', 'Professional Services');
        ProductOptionCreationBatch batch2 = new ProductOptionCreationBatch('Cloud Archiving', 'Options');
        Database.executeBatch(batch);
        Database.executeBatch(batch2);
        Test.stopTest();
    }
}