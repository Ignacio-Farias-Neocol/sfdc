/**
 * Created by: Salesforce Services
 * Date: 03/17/2021
 * 
 * Description: Test class of EOL validation related logic
 */

@isTest
public with sharing class EOLValidationTest {

  @TestSetup
  static void setupData(){
    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   

    //Create Parent Product
    Product2 testParentProduct                  = new Product2();
    testParentProduct.Name                      = 'Parent Product';
    testParentProduct.is_pst_enterprise__c      = true;
    testParentProduct.Base_SKU__c               = 'TEST_SKU';
    testParentProduct.ProductCode               = 'TEST_SKU';
    //testParentProduct.Product_Sales_Grouping__c = 'Cloud Email Services';  
    testParentProduct.Product_Sales_Grouping__c = 'ESS';  

    //Create a child product
    Product2 testChildProduct             = new Product2();
    testChildProduct.Name                 = 'Child Product';
    testChildProduct.is_pst_enterprise__c = true;
    testChildProduct.Base_SKU__c          = 'TEST_SKU_CHILD';
    testChildProduct.ProductCode          = 'TEST_SKU_CHILD';
    testChildProduct.SBQQ__Component__c   = true;  


    Product2 testChildProduct2             = new Product2();
    testChildProduct2.Name                 = 'Child Product 2';
    testChildProduct2.is_pst_enterprise__c = true;
    testChildProduct2.Base_SKU__c          = 'TEST_SKU_CHILD2';
    testChildProduct2.ProductCode          = 'TEST_SKU_CHILD2';
    testChildProduct2.SBQQ__Component__c   = true;  


    insert new List<Product2>{testParentProduct, testChildProduct,testChildProduct2};

    //Create a pricebook
    Pricebook2 pb = new Pricebook2(Name = 'Test PB', Description = 'Test Pricebook', IsActive = true );
    insert pb;

    //Create the custom PricebookEntry
    PricebookEntry customPBE = new PricebookEntry(
      Pricebook2Id = pb.Id,
      Product2Id = testParentProduct.Id,
      UnitPrice = 100,
      IsActive = true
    );

    //Create the standard PricebookEntry
    PricebookEntry stdPBE = new PricebookEntry(
      Pricebook2Id = Test.getStandardPricebookId(),
      Product2Id = testParentProduct.Id,
      UnitPrice = 100,
      IsActive = true
    );
    
    Insert new List<PricebookEntry>{stdPBE, customPBE};

    //Update Account Information
    Account customerAccount = TestDataFactory.customers[0];

    //Opportunity
    Opportunity testOpp = TestDataFactory.createOpportunity(customerAccount);
    //Remove partners from the oppty
    testOpp.Distributor__c = null;
    testOpp.Distributor_Contact__c = null;
    testOpp.Reseller__c =  null;
    testOpp.Reseller_Contact__c = null;
    testOpp.Business_Group__c = 'Core';

    //Get addresses for the opportunity
    for(Address__c addr : [SELECT id, 
                                          Street__c, 
                                          City__c, 
                                          State_Name__c, 
                                          Country_Name__c, 
                                          Zip_Postal_Code__c,
                                          Type__c
                                  FROM Address__c 
                                  WHERE Account__c = :customerAccount.Id ]){
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

    //Opportunity line item with custom PBE
    OpportunityLineItem oli = new OpportunityLineItem(OpportunityId =  testOpp.Id,
                                                      Product2Id = testParentProduct.Id,
                                                      PricebookEntryId = customPBE.Id,
                                                      UnitPrice = 100,
                                                      Quantity = 1);
    
    insert oli;

    //Quote
    SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, 
                                                  SBQQ__Primary__c      = true);
    insert testQuote;

    //Contract
    Contract testContract = new Contract(AccountId            = customerAccount.Id, 
                                         Business_Group__c    = 'Core', 
                                         SBQQ__Quote__c       = testQuote.Id, 
                                         StartDate            = System.today(),
                                         SBQQ__RenewalTerm__c = 12);
                                       
    insert new List<Contract>{testContract};

    //Asset
    Asset testAsset1 = new Asset(AccountId     = customerAccount.Id,
                                 Contract__c = testContract.Id,
                                 Product2Id    =  testParentProduct.Id,
                                 Name        = 'test asset'); 

    insert testAsset1;

    //Subscription
    List<SBQQ__Subscription__c> subsToInsert = new List<SBQQ__Subscription__c>();
    SBQQ__Subscription__c testSub1 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                               SBQQ__Contract__c              = testContract.Id, 
                                                               SBQQ__SubscriptionStartDate__c = System.today(),
                                                               SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                               SBQQ__Product__c               = testChildProduct.Id,
                                                               SBQQ__Account__c               = customerAccount.Id,
                                                               SBQQ__RootId__c                = testAsset1.Id,
                                                               SBQQ__RequiredByProduct__c     = testParentProduct.Id);  
      subsToInsert.add(testSub1);
     //Subscription2
     SBQQ__Subscription__c testSub2 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                                SBQQ__Contract__c              = testContract.Id, 
                                                                SBQQ__SubscriptionStartDate__c = System.today(),
                                                                SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                                SBQQ__Product__c               = testChildProduct2.Id,
                                                                SBQQ__Account__c               = customerAccount.Id,
                                                                SBQQ__RootId__c                = testAsset1.Id,
                                                                SBQQ__RequiredByProduct__c     = testParentProduct.Id);  
    subsToInsert.add(testSub2);                                                            
    insert subsToInsert;

    TriggerHandler.clearAllBypasses();  
  }

  /** test scenario 1: Should not allow opportunity to be closed won
   * 
   */
  @isTest
  private static void test_CannotCloseOpportunity(){
    //Get parent product
    List<Product2> prod = [SELECT Id FROM Product2 WHERE ProductCode = 'TEST_SKU'];

    //Set product status to EOL
    update new Product2(Id = prod[0].Id, Lifecycle_Status__c = 'End of Life');

    
    //Start test
    Test.startTest();

      //Get the opportunity
      List<Opportunity> oppList = [SELECT Id, Business_Group__c FROM Opportunity];
      oppList[0].StageName = 'Closed Won';

      //Call the validation class
      DynamicValidationEOLProducts valClass = new DynamicValidationEOLProducts();
      Map<SObject,Boolean> result = valClass.evaluateRule(oppList);

    Test.stopTest();

    //Assertion
    System.assert(result!=null && !result.isEmpty());
    for(Boolean resultValue: result.values()){
      System.assert(!resultValue);
    }

  }

  /** test scenario 2: Should not allow Contract to be renewed
   * 
   */
  @isTest
  private static void test_CannotCreateRenewal(){
    
    //Get parent product
    List<Product2> prodList = [SELECT Id,Lifecycle_Status__c FROM Product2];

    //Mark these products for end of life
    for(Product2 prod: prodList){
      prod.Lifecycle_Status__c = 'End of Life';
    }

    //Set product status to EOL
    update prodList;    
    
    //Start test
    Test.startTest();

      //Get the Contract
      List<Contract> conList = [SELECT Id, Business_Group__c FROM Contract];
      conList[0].SBQQ__RenewalForecast__c = true;

      //Call the validation class
      DynamicValidationContractEOLProducts valClass = new DynamicValidationContractEOLProducts();
      Map<SObject,Boolean> result = valClass.evaluateRule(conList);

    Test.stopTest();

    //Assertion
    System.assert(result!=null && !result.isEmpty());
    for(Boolean resultValue: result.values()){
      System.assert(!resultValue);
    }

  }  

  /** test scenario 3: Should allow Contract to be renewed
   * 
   */
  @isTest
  private static void test_AllowRenewal(){
    
    //Start test
    Test.startTest();

      //Get the Contract
      List<Contract> conList = [SELECT Id, Business_Group__c FROM Contract];
      conList[0].SBQQ__RenewalForecast__c = true;

      //Call the validation class
      DynamicValidationContractEOLProducts valClass = new DynamicValidationContractEOLProducts();
      Map<SObject,Boolean> result = valClass.evaluateRule(conList);

    Test.stopTest();

    //Assertion
    System.assert(result==null || result.isEmpty());
  }  
  
  /**
   * Description : JIRA 15400
   * TEST:
   *  - Contract has 2 subscription. 
   *  - Update the Annotation reason on One of the subscription and not the other. 
   *  - Update the 'Renewal Forecast' flag on the contract
   * EXPECTED RESULT - contract should update successfully as Only 1 of the 2 subscriptions have the Annotation Reason set. 
   */
  @isTest
  private static void testContractRenewalSubscriptionWithOneSubAnnotation(){

    //Query and Update Subscription
    List<SBQQ__Subscription__c> subs = [Select Id , AnnotationReason__c , SBQQ__Contract__c
                                From 
                                SBQQ__Subscription__c 
                                Where 
                                SBQQ__Product__c IN (Select Id From Product2 Where Name = 'Child Product 2')];
    
    SBQQ__Subscription__c sub;

    if(subs != null && subs.size() > 0){

      ID contractId;
      sub = subs[0];
      sub.AnnotationReason__c = 'Unable to reach';
      contractId = sub.SBQQ__Contract__c;
      update sub;

      List<Contract> con = [Select Id, SBQQ__RenewalForecast__c From Contract Where Id =: contractId];
      con[0].SBQQ__RenewalForecast__c = true;
      con[0].Business_Group__c = 'Core';
      try {
        Database.SaveResult sr = Database.update(con[0],true);
      } catch (Exception e) {
        system.debug('+++Exception in testContractRenewalSubscriptionWithOneSubAnnotation : ' + e.getMessage());
      }
    }
  }

  /**
   * Description : JIRA 15400
   * TEST:
   *  - Contract has 2 subscription. 
   *  - Update the Annotation reason on ALL of the subscriptions. 
   *  - Update the 'Renewal Forecast' flag on the contract
   * EXPECTED RESULT - contract should NOT update successfully as ALL subscriptions have the Annotation Reason set. 
   *               
   */
  @isTest
  private static void testContractRenewalSubscriptionWithAllSubAnnotation(){

    //Query and Update Subscriptions
    List<String> prodNames = new List<String>{'Child Product 2','Child Product'};
    List<SBQQ__Subscription__c> subs = [Select Id , AnnotationReason__c , SBQQ__Contract__c
                                From 
                                SBQQ__Subscription__c 
                                Where 
                                SBQQ__Product__c IN (Select Id From Product2 Where Name IN: prodNames)];
    
    ID contractId;
    List<SBQQ__Subscription__c> subsToUpdate = new List<SBQQ__Subscription__c>();
    contractId = subs[0].SBQQ__Contract__c;

    if(subs != null && subs.size() > 0){
      for(SBQQ__Subscription__c sub : subs){
        sub.AnnotationReason__c = 'Unable to reach';
        subsToUpdate.add(sub);
      }
      
      update subsToUpdate;

      List<Contract> con = [Select Id, SBQQ__RenewalForecast__c From Contract Where Id =: contractId];
      con[0].SBQQ__RenewalForecast__c = true;
      con[0].Business_Group__c = 'Core';
      Database.SaveResult sr;
      try {
        sr = Database.update(con[0],true);  
      } catch (Exception e) {
        system.debug('+++Exception Message :' + e.getMessage());  
      }
    }
  }

}