@isTest
private class DynamicBusinessRuleAssetTest {
    
    static Product2 testProd;
    static Account testAccount;
    static Contact testContact;
    static Asset testAsset;

    static void setup() {

        testProd = TestDataFactory.products[0];
        testAccount = TestDataFactory.customers[0];

        Opportunity testOpp = TestDataFactory.createOpportunity(testAccount);

        Product2 testParentProduct                  = new Product2();
        testParentProduct.Name                      = 'Parent Product';       
        testParentProduct.Base_SKU__c               = 'Test';
        testParentProduct.ProductCode               = 'Test';
        insert new List<Product2>{testParentProduct};

        Contract contract = new Contract();
        contract.AccountId = testOpp.accountId;
        contract.SBQQ__Opportunity__c = testOpp.Id;
        insert contract;
       

        testContact=new Contact(LastName='TestContact', AccountId=testAccount.Id);
        insert testContact;

        Serial__c serial1 = new Serial__c();
        serial1.Serial_Number__c = '9999';
        serial1.Status__c = 'Active';
        serial1.Contract__c = contract.Id;

        insert new List<Serial__c>{serial1};

        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c  = testAccount.Id;
        subscription.SBQQ__Contract__c = contract.Id;
        subscription.SBCF_Serial_Number__c = null;
        subscription.SBQQ__Quantity__c = 1;
        subscription.SBQQ__Product__c=testParentProduct.Id;
        insert subscription;                

        testAsset=new Asset(Name='TestAsset',ContactId=testContact.Id,AccountId=testAccount.Id,Product2Id=testParentProduct.Id);
        insert testAsset;
    }
    @IsTest
    static  void unitTest() {

        setup();
        Test.startTest();

        List<Serial__c> serial = [SELECT ID FROM Serial__c WHERE Serial_Number__c = '9999' Limit 1];
        List<SBQQ__Subscription__c> sub = [SELECT ID FROM SBQQ__Subscription__c Limit 1];
        List<Product2> prod = [SELECT ID FROM Product2 Limit 1];

        Assigned_Serial__c assignedSerial = new Assigned_Serial__c();
        assignedSerial.Serial__c = serial[0].Id;
        assignedSerial.Subscription__c = sub[0].Id;
        assignedSerial.Status__c = 'Active';
        assignedSerial.Qty_In_Use__c = 10;
        assignedSerial.External_Id__c = 'uniqueId1';       
        insert assignedSerial;

        SBQQ__ProductOption__c po=new SBQQ__ProductOption__c();
        po.SBQQ__ConfiguredSKU__c=prod[0].Id;
        po.SBQQ__Number__c=0000;
        insert po;

        testAsset.BNCPQ_Serial__c=serial[0].Id;
        testAsset.SBCF_Serial_Number__c='9999';
      
        update testAsset;


        Test.stopTest();


    }

}