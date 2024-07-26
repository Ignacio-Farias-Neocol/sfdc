/**
* @author        Rajesh Wani
* @date          2024-02-02
* @description   Unit Test class for LegacySerialDataFixBatch,LegacySerialDataFixBatchSchd 
* @group         Test
*
*/

@isTest
public class LegacySerialDataFixBatchTest {
    
	@testSetup
  static void setup() {

    // by pass business action
    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); 
    List<Contact> contacts = TestDataFactory.customerContacts;
    List<Account> customers = TestDataFactory.customers;
    List<Account> partners = TestDataFactory.partners;
    List<SBQQ__Subscription__c> newSublist = new   List<SBQQ__Subscription__c>();
    List<SBQQ__ProductOption__c> newPOlist = new   List<SBQQ__ProductOption__c>();
    List<Asset> newAssetList= new List<Asset>();

      //Opportunity
    Opportunity testOpp = TestDataFactory.createOpportunity(customers[0]);
    //Remove partners from the oppty
    testOpp.Distributor__c = null;
    testOpp.Distributor_Contact__c = null;
    testOpp.Reseller__c =  null;
    testOpp.Reseller_Contact__c = null;
    // testOpp.Business_Group__c = 'MSP';

    //Get addresses for the opportunity
    for(Address__c addr : [SELECT id, 
                                  Street__c, 
                                  City__c, 
                                  State_Name__c, 
                                  Country_Name__c, 
                                  Zip_Postal_Code__c,
                                  Type__c
                          FROM Address__c 
                          WHERE Account__c = :customers[0].Id ]){
      if(addr.Type__c == 'Billing'){
        System.debug('Inside billing');
        testOpp.Billing_Address__c = addr.Id;
        testOpp.Street__c = addr.Street__c;
        testOpp.City__c = addr.City__c;
        testOpp.State__c = addr.State_Name__c;
        testOpp.Country__c = addr.Country_Name__c;
        testOpp.Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
      }
      else if(addr.Type__c == 'Shipping'){
        System.debug('Inside shipping');
        testOpp.Shipping_Address__c = addr.Id;
        testOpp.Ship_To_Street__c = addr.Street__c;
        testOpp.Ship_To_City__c = addr.City__c;
        testOpp.Ship_To_State__c = addr.State_Name__c;
        testOpp.Ship_To_Country__c = addr.Country_Name__c;
        testOpp.Ship_To_Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
      }
    }

    insert testOpp;

    Contract contract = new Contract();
    contract.AccountId = testOpp.accountId;
    contract.SBQQ__Opportunity__c = testOpp.Id;
    insert contract;
    
       List<Product2> prodList = new List<Product2>();
        
        //Create a Bundle Parent product
        Product2 testAccountProduct                  = new Product2();
        testAccountProduct.Name                      = ' Product Test 1';
        testAccountProduct.Base_SKU__c               = 'F401';
        testAccountProduct.ProductCode               = 'ParentProductTest1'; 
        prodList.add(testAccountProduct);
        
       Product2 testRepProduct                  = new Product2();
        testRepProduct.Name                      = ' testRepProduct Test 1';
        testRepProduct.Base_SKU__c               = 'F401';
        testRepProduct.ProductCode               = 'testRepProductNo'; 
        prodList.add(testRepProduct);
      
        Product2 testBundleParentProduct1             = new Product2();
        testBundleParentProduct1.Name                 = 'Product Test 2';
        testBundleParentProduct1.Base_SKU__c          = 'F401';
        testBundleParentProduct1.ProductCode          = 'SUBProductTest2';
        prodList.add(testBundleParentProduct1);
        
        
        Product2 testBundleParentProduct2             = new Product2();
        testBundleParentProduct2.Name                 = 'Product Test 3';
        testBundleParentProduct2.Base_SKU__c          = 'F401';
        testBundleParentProduct2.ProductCode          = 'SUBProductTest3';
       prodList.add(testBundleParentProduct2);
       
         Product2 testBundleParentProduct3            = new Product2();
         testBundleParentProduct3.Name                = 'Product Test Asset';
        testBundleParentProduct3.Base_SKU__c          = 'F401';
        testBundleParentProduct3.ProductCode          = 'AssetProductTest3';
      
        prodList.add(testBundleParentProduct3);
      
      INSERT prodList;
      testAccountProduct.Replacement_Product__c=testRepProduct.id;
      UPDATE testAccountProduct;
       SBQQ__ProductOption__c podOp = new SBQQ__ProductOption__c();
            podOp.SBQQ__OptionalSKU__c = testBundleParentProduct1.id;
            podOp.SBQQ__ConfiguredSKU__c = testAccountProduct.id;// assign it's parent order item id to SBQQ__ConfiguredSKU__c field
            podOp.SBQQ__Number__c= 1;
      
      SBQQ__ProductOption__c podOp1 = new SBQQ__ProductOption__c();
            podOp1.SBQQ__OptionalSKU__c = testBundleParentProduct2.id;
            podOp1.SBQQ__ConfiguredSKU__c = testAccountProduct.id;// assign it's parent order item id to SBQQ__ConfiguredSKU__c field
            podOp1.SBQQ__Number__c= 2;
      newPOlist.add(podOp1);
      newPOlist.add(podOp);
      
  Serial__c serial1 = new Serial__c();
    serial1.Serial_Number__c = '999999';
    serial1.Status__c = 'Active';
    serial1.Contract__c = contract.Id;
     
    Serial__c serial2 = new Serial__c();
    serial2.Serial_Number__c = '888888';
    serial2.Status__c = 'Active';
    serial2.Contract__c = contract.Id;        
    insert new List<Serial__c>{serial1, serial2};
        
      Asset asset = new Asset();
        asset.Name = 'test_Instant Replacement_Support_Product';
        asset.AccountId = testOpp.accountId;
        asset.Product2Id = testBundleParentProduct3.Id;
        asset.SerialNumber = serial1.Serial_Number__c;
        asset.BNCPQ_Serial__c = serial1.Id;
      
       newAssetList.add(asset);
        INSERT newAssetList;
      
   
    
        for(Product2 prd :prodList){
            if(prd.ProductCode.Contains('SUB') ){
            SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
            subscription.SBQQ__Account__c  = testOpp.accountId;
            subscription.SBQQ__Contract__c = contract.Id;
            subscription.SBCF_Serial_Number__c = null;
            subscription.SBQQ__Quantity__c = 1;
            subscription.SBQQ__product__c=prd.id;
            subscription.SBQQ__RequiredByProduct__c=testAccountProduct.id;
            subscription.SBQQ__SubscriptionEndDate__c =system.today()-12;
                newSublist.add(subscription);
            }
        }
    insert newSublist;         
    TriggerHandler.clearAllBypasses();    

  }


  @isTest static void testSetAssingSerialInactive() {

    //Get the serial record
    List<Serial__c> serial = [SELECT ID FROM Serial__c WHERE Serial_Number__c = '999999' Limit 1];
	 
    //Get subscription record
    List<SBQQ__Subscription__c> sub = [SELECT ID FROM SBQQ__Subscription__c WHERE SBQQ__RequiredByProduct__c!=null Limit 2];
    List<Asset> assetList = [SELECT ID FROM Asset Limit 1];
  
    Assigned_Serial__c assignedSerial = new Assigned_Serial__c();
    assignedSerial.Serial__c = serial[0].Id;
    assignedSerial.Subscription__c = sub[0].Id;
    assignedSerial.Status__c = 'Active';
    assignedSerial.Qty_In_Use__c = 10;
    assignedSerial.External_Id__c = 'uniqueId1';
     assignedSerial.Asset__c=assetList[0].id;
       assignedSerial.Parent_Subscription__c=sub[1].Id;
    insert assignedSerial;

       Jumbled_Serial_Tracking__c jumbObj=  new Jumbled_Serial_Tracking__c();
      jumbObj.Serial_1__c='999999';
          jumbObj.Final_Serial_For_Serial1__c='888888';
          jumbObj.Original_Model__c='F401';
          jumbObj.New_Model__c='F401';
           jumbObj.Status__c='Not Processed';
      jumbObj.Legacy_Serial_Issue__c=true;
      
      Insert jumbObj;

    Test.startTest();
      
      LegacySerialDataFixBatch d = new LegacySerialDataFixBatch();
      Database.executeBatch(d,1);
      
    Test.stopTest();

   

  }
     public testMethod static void testLegacySerialDataFixBatchSchd() {

    //Get the serial record
    List<Serial__c> serial = [SELECT ID FROM Serial__c WHERE Serial_Number__c = '999999' Limit 1];
	 
    //Get subscription record
    List<SBQQ__Subscription__c> sub = [SELECT ID FROM SBQQ__Subscription__c WHERE SBQQ__RequiredByProduct__c!=null Limit 2];
    List<Asset> assetList = [SELECT ID FROM Asset Limit 1];
  
    Assigned_Serial__c assignedSerial = new Assigned_Serial__c();
    assignedSerial.Serial__c = serial[0].Id;
    assignedSerial.Subscription__c = sub[0].Id;
    assignedSerial.Status__c = 'Active';
    assignedSerial.Qty_In_Use__c = 10;
    assignedSerial.External_Id__c = 'uniqueId1';
     assignedSerial.Asset__c=assetList[0].id;
       assignedSerial.Parent_Subscription__c=sub[1].Id;
    insert assignedSerial;

       Jumbled_Serial_Tracking__c jumbObj=  new Jumbled_Serial_Tracking__c();
      jumbObj.Serial_1__c='999999';
          jumbObj.Final_Serial_For_Serial1__c='888888';
          jumbObj.Original_Model__c='F401';
          jumbObj.New_Model__c='F401';
           jumbObj.Status__c='Not Processed';
      jumbObj.Legacy_Serial_Issue__c=true;
      
      Insert jumbObj;

    Test.startTest();
        LegacySerialDataFixBatchSchd  s = new LegacySerialDataFixBatchSchd ();
        String sch ='0 0 * * * ?'; 
        System.schedule('LegacySerialDataFixBatchSchd', sch, s);      
    Test.stopTest();

  
  }
    
    public testMethod static void testLegacySerialNewSerial() {

    //Get the serial record
    List<Serial__c> serial = [SELECT ID FROM Serial__c WHERE Serial_Number__c = '999999' Limit 1];
	DELETE [SELECT ID FROM Serial__c WHERE Serial_Number__c = '888888'];
    //Get subscription record
    List<SBQQ__Subscription__c> sub = [SELECT ID FROM SBQQ__Subscription__c WHERE SBQQ__RequiredByProduct__c!=null Limit 2];
    List<Asset> assetList = [SELECT ID FROM Asset Limit 1];
  
    Assigned_Serial__c assignedSerial = new Assigned_Serial__c();
    assignedSerial.Serial__c = serial[0].Id;
    assignedSerial.Subscription__c = sub[0].Id;
    assignedSerial.Status__c = 'Active';
    assignedSerial.Qty_In_Use__c = 10;
    assignedSerial.External_Id__c = 'uniqueId1';
     assignedSerial.Asset__c=assetList[0].id;
       assignedSerial.Parent_Subscription__c=sub[1].Id;
    insert assignedSerial;

       Jumbled_Serial_Tracking__c jumbObj=  new Jumbled_Serial_Tracking__c();
      jumbObj.Serial_1__c='999999';
          jumbObj.Final_Serial_For_Serial1__c='888888';
          jumbObj.Original_Model__c='F401';
          jumbObj.New_Model__c='F401';
           jumbObj.Status__c='Not Processed';
      jumbObj.Legacy_Serial_Issue__c=true;
      
      Insert jumbObj;

    Test.startTest();
             LegacySerialDataFixBatch d = new LegacySerialDataFixBatch();
      Database.executeBatch(d,1);
    Test.stopTest();

  
  }
}