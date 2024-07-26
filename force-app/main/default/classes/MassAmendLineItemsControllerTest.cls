/**
* @author        salesforce services
* @date          2020-09-03
* @description   Unit Test class for MassAmendLineItemsController class
* @group         Test
*
*/
@isTest
public with sharing class MassAmendLineItemsControllerTest {

  //Data Setup
  @testSetup
  static void setup() {
    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');    

    //Create Parent Product
    Product2 testParentProduct                  = new Product2();
    testParentProduct.Name                      = 'Parent Product';
    testParentProduct.is_pst_enterprise__c      = true;
    testParentProduct.Base_SKU__c               = 'TEST_SKU';
    testParentProduct.ProductCode               = 'TEST_SKU';
    //testParentProduct.Product_Sales_Grouping__c = 'Cloud Email Services';   
    testParentProduct.Product_Sales_Grouping__c = 'ESS';   
    testParentProduct.Family                    = 'Essentials'; 
    testParentProduct.MSP_Product__c            = true;

    //Create a child product
    Product2 testChildProduct             = new Product2();
    testChildProduct.Name                 = 'Child Product';
    testChildProduct.is_pst_enterprise__c = true;
    testChildProduct.Base_SKU__c          = 'TEST_SKU_CHILD';
    testChildProduct.ProductCode          = 'TEST_SKU_CHILD';
    testChildProduct.SBQQ__Component__c   = true;
    testChildProduct.Family               = 'Essentials';
    testParentProduct.MSP_Product__c      = true;

    insert new List<Product2>{testParentProduct, testChildProduct};

    //Create product bundle
    SBQQ__ProductOption__c testPO = new SBQQ__ProductOption__c( SBQQ__Number__c = 10,
                                                                SBQQ__ConfiguredSKU__c = testParentProduct.Id,
                                                                SBQQ__OptionalSKU__c = testChildProduct.Id,
                                                                SBQQ__Type__c = 'Component');

    insert testPO;

    //Create a custom pricebook
    Pricebook2 customPB = new Pricebook2(IsActive = true,
                                         Name = 'CustomPB');
    insert customPB;

    //Create pricebook entries
    PricebookEntry[] pbeList = new PricebookEntry[] {
      new PricebookEntry (Product2ID=testParentProduct.id,Pricebook2ID=Test.getStandardPricebookId(),UnitPrice=50, isActive=true),
      new PricebookEntry (Product2ID=testChildProduct.id,Pricebook2ID=Test.getStandardPricebookId(),UnitPrice=50, isActive=true),
      new PricebookEntry (Product2ID=testParentProduct.id,Pricebook2ID=customPB.Id,UnitPrice=50, isActive=true),
      new PricebookEntry (Product2ID=testChildProduct.id,Pricebook2ID=customPB.id,UnitPrice=50, isActive=true)};
    insert pbeList;
    

    //Get Pricebook entry and prepare a map of product id and pricebook entry id
    Map<Id, Id> productPBEMap = new Map<Id, Id>();
    // for(PricebookEntry pbe: [SELECT Id, Product2Id from PriceBookEntry 
    //                           WHERE Pricebook2Id = :customPB.Id
    //                           AND Product2Id in (:testParentProduct.Id, :testChildProduct.Id)]){
    //   productPBEMap.put(pbe.Product2Id, pbe.Id);
    // }
    for(PricebookEntry pbe: pbeList){
      if(pbe.Pricebook2Id == customPB.Id){
        productPBEMap.put(pbe.Product2Id, pbe.Id);
      }
    }


    //Update Account Information
    Account partnerAccount = TestDataFactory.partners[0];
    partnerAccount.User_Na__c = 'testpartner';
    //partnerAccount.Type = 'Partner - MSP';
    partnerAccount.Type = 'Partner - Reseller';
    partnerAccount.Compliance_Status__c = 'Active';
    update partnerAccount;
    
    //Opportunity
    Opportunity testOpp = TestDataFactory.opportunities[0];
    testOpp.Pricebook2Id = customPB.Id;
    update testOpp;

    //Quote
    SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, 
                                                  SBQQ__Primary__c      = true,
                                                  SBQQ__PricebookId__c = customPB.Id);
    insert testQuote;
    Test.StartTest();
    //Add quote lines
    SBQQ__QuoteLine__c testQuoteLineParent = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c                  = testQuote.Id,
      Appliance_Line_Type__c          = 'Standard',
      SBQQ__Bundled__c                = false,
      Business_Group__c               = 'MSP',
      CPQ_Monthly_Total__c            = 0,
      ECHO_Unique_Identifier_Value__c = '1234',
      SBQQ__EndDate__c                = Date.today() + 100,
      SBQQ__Existing__c               =  true,
      SBQQ__ListPrice__c              = 10,
      New_Monthly_Total__c            = 10,
      NFR_Status__c                   = 'Not For Resale',
      SBQQ__OptionLevel__c            = 0,
      SBQQ__OptionType__c             = '',
      SBQQ__BundledQuantity__c        = 10,
      SBQQ__Bundle__c                 = true,
      SBQQ__PricebookEntryId__c       = productPBEMap.get(testParentProduct.Id),
      SBQQ__Product__c                = testParentProduct.Id,
      SBQQ__Quantity__c               =  10,
      SBQQ__RequiredBy__c             = null,
      SBCF_Serial_Number__c           = '12345',
      SBQQ__StartDate__c              = Date.today(),
      SBQQ__SubscriptionPricing__c    = 'Fixed Price',
      Universal_Order_Id__c           = '111111',
      Universal_OrderItem_Id__c       = '1111111111',
      Universal_Order_Number__c       = '123456',
      SBCF_Capacity_Unit__c           = 'qty');

    insert testQuoteLineParent;    

    SBQQ__QuoteLine__c testQuoteLineChild = new SBQQ__QuoteLine__c(
      SBQQ__Quote__c                  = testQuote.Id,
      Appliance_Line_Type__c          = 'Standard',
      SBQQ__Bundled__c                = false,
      Business_Group__c               = 'MSP',
      CPQ_Monthly_Total__c            = 0,
      ECHO_Unique_Identifier_Value__c = '12345',
      SBQQ__EndDate__c                = Date.today() + 100,
      SBQQ__Existing__c               =  true,
      SBQQ__ListPrice__c              = 10,
      New_Monthly_Total__c            = 10,
      NFR_Status__c                   = 'Not For Resale',
      SBQQ__OptionLevel__c            = 1,
      SBQQ__OptionType__c             = 'Component',
      SBQQ__BundledQuantity__c        = 10,
      SBQQ__Bundle__c                 = false,
      SBQQ__PricebookEntryId__c       = productPBEMap.get(testChildProduct.Id),
      SBQQ__Product__c                = testChildProduct.Id,
      SBQQ__ProductOption__c          = testPO.Id,
      SBQQ__Quantity__c               =  10,
      SBQQ__RequiredBy__c             = testQuoteLineParent.Id,
      SBCF_Serial_Number__c           = '12345',
      SBQQ__StartDate__c              = Date.today(),
      SBQQ__SubscriptionPricing__c    = 'Fixed Price',
      Universal_Order_Id__c           = '111111',
      Universal_OrderItem_Id__c       = '2222222222',
      Universal_Order_Number__c       = '123456',
      SBCF_Capacity_Unit__c           = 'qty');   
      
    insert testQuoteLineChild;
Test.StopTest();
    TriggerHandler.clearAllBypasses();  
  }

  //SCENARIOS FOR MassAmendLineItemsController CLASS
  /** Scenario1 : New QL should be created when copy quotelines methos is called
   */
  @isTest static void test_shouldCreateNewQL() {

    //Get the quote
    SBQQ__Quote__c testQuote = [Select Id from SBQQ__Quote__c limit 1];

    //Get the parent QL
    SBQQ__QuoteLine__c parentQuoteLine = [Select Id from SBQQ__QuoteLine__c where SBQQ__Bundle__c = true limit 1];

    Test.startTest();
        PageReference pageRef = Page.MassAmendLineItems;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', testQuote.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(testQuote);
        MassAmendLineItemsController quoteExtension = new MassAmendLineItemsController(sc);
        System.debug('***MESSAGE**' + quoteExtension.message);

        System.assert(quoteExtension.quoteLineIds!=null && !quoteExtension.quoteLineIds.isEmpty());
        System.assert(quoteExtension.getMassAmendQL()!=null && !quoteExtension.getMassAmendQL().isEmpty());
        System.assert(quoteExtension.getFSMList()!=null && !quoteExtension.getFSMList().isEmpty());

        //Select quote line before calling copy method
        for(MassAmendLineItemsController.QuoteLineSelection ql: quoteExtension.quoteLineIds){
            if(ql.id == parentQuoteLine.Id){
                ql.checkBox = true;
            }
        }

        //Call copy method
        quoteExtension.copyQuoteLineItems();
    Test.stopTest();

    //Get the new quote lines
    List<SBQQ__QuoteLine__c> qlList = [Select Id from SBQQ__QuoteLine__c where SBQQ__Quote__c = :testQuote.Id and Is_Bucket_Change__c = true];

    //Assertion
    System.assert(qlList!=null && qlList.size()==4, '***Error: ' + quoteExtension.message);
  }   

  /** Scenario 2: Quote lines do not satisy condition defined in custom metadata
   */
  @isTest static void test_shouldNotReturnOriginalQL(){


    Test.startTest();
      //Get the quote
      SBQQ__Quote__c testQuote = [Select Id from SBQQ__Quote__c limit 1];
  
      //List of Quote lines
      List<SBQQ__QuoteLine__c> testQuoteLines = [Select Id from SBQQ__QuoteLine__c where SBQQ__Quote__c = :testQuote.Id];
      for(SBQQ__QuoteLine__c ql: testQuoteLines){
        ql.Is_Bucket_Change__c = true;
      }
  
      update testQuoteLines;
      PageReference pageRef = Page.MassAmendLineItems;
      Test.setCurrentPage(pageRef);
      pageRef.getParameters().put('Id', testQuote.Id);
      ApexPages.StandardController sc = new ApexPages.StandardController(testQuote);
      MassAmendLineItemsController quoteExtension = new MassAmendLineItemsController(sc);
    Test.stopTest();

    System.assertEquals(System.Label.Mass_Amend_No_Quote_Lines, quoteExtension.message);
  }

  /** Scenario 3: Exception handling
   */
  @isTest static void test_shouldCatchException(){
    //Get the quote
    SBQQ__Quote__c testQuote = [Select Id from SBQQ__Quote__c limit 1];

    //Get the parent QL
    SBQQ__QuoteLine__c parentQuoteLine = [Select Id from SBQQ__QuoteLine__c where SBQQ__Bundle__c = true limit 1];

    Test.startTest();
      PageReference pageRef = Page.MassAmendLineItems;
      Test.setCurrentPage(pageRef);
      pageRef.getParameters().put('Id', testQuote.Id);
      ApexPages.StandardController sc = new ApexPages.StandardController(testQuote);
      MassAmendLineItemsController quoteExtension = new MassAmendLineItemsController(sc);

      //Select quote line before calling copy method
      for(MassAmendLineItemsController.QuoteLineSelection ql: quoteExtension.quoteLineIds){
          if(ql.id == parentQuoteLine.Id){
              ql.checkBox = true;
          }
      }

      //Force an exception
      quoteExtension.testRunningFlag = true;

      //Call copy method
      quoteExtension.copyQuoteLineItems();
    Test.stopTest();
    //Get the new quote lines
    List<SBQQ__QuoteLine__c> qlList = [Select Id from SBQQ__QuoteLine__c where SBQQ__Quote__c = :testQuote.Id and Is_Bucket_Change__c = true];

    System.assert(qlList==null || qlList.isEmpty());
  } 
  
  /** Scenario 4: Assigned Serial creation for subscriptions
   */
  @isTest static void test_shouldCreateAssignedSerials(){    

    Test.startTest();
      //Get the parent product
      Product2 product = [Select Id from Product2 where ProductCode = 'TEST_SKU'];

      //Get quote
      SBQQ__Quote__c testQuote = [Select Id, SBQQ__Opportunity2__c from SBQQ__Quote__c Limit 1];   

      //Get QuoteLine
      SBQQ__QuoteLine__c ql = [Select id, Is_bucket_change__C from SBQQ__QuoteLine__c where SBQQ__Product__c = :product.Id];
      ql.Is_Bucket_change__c = true;
      update ql;   
      
      //Get PBE
      // PricebookEntry pbe = [SELECT Id, Product2Id from PriceBookEntry 
      //                       WHERE Pricebook2Id = :Test.getStandardPricebookId()
      //                       AND Product2Id = :product.Id];      
      
      TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');  

Account PartnerAccount = [Select Id from account where Type = 'Partner - Reseller' and Partner_Number__c = 12345 limit 1];
      //Create contract
      Contract testContract = new Contract(AccountId            = PartnerAccount.Id, 
                                           Business_Group__c    = 'MSP', 
                                           SBQQ__Quote__c       = testQuote.Id, 
                                           StartDate            = System.today(),
                                           Reseller__c          = PartnerAccount.Id,
                                           SBQQ__RenewalTerm__c = 12);
      
      insert testContract;
                             
      //Create an Order
      Order testOrder              = new Order();
      testOrder.AccountId          = PartnerAccount.Id;
      testOrder.EffectiveDate      = Date.today();
      testOrder.Pricebook2Id       = TestDataFactory.priceBookId;
      testOrder.description        = 'Test Order';
      testOrder.Status             = 'Draft';
      testOrder.Type               = 'New'; // new order
      testOrder.Active_Contract__c = testContract.Id;
      testOrder.OpportunityId      = testQuote.SBQQ__Opportunity2__c;

      insert testOrder;

      //Add order item
      TestDataFactory.addOrderItem(new List<Order>{testOrder});

      //Get order line Id
      OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
      oi.SBCF_Serial_Number__c = '1234567';
      oi.SBQQ__QuoteLine__c = ql.id;
      update oi;

      //Serial
      Serial__c testSerial = new Serial__c(Serial_Number__c    = '1234567',
                                          Status__c           = 'Active',
                                          Capacity__c         = 1,
                                          Order__c            = testOrder.Id,
                                          Base_Product_SKU__c = 'TEST_SKU');
      insert testSerial;    

      //Create subscription
      SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                                Current_Quantity__c            = 1,
                                                                SBQQ__Contract__c              = testContract.Id, 
                                                                SBQQ__SubscriptionStartDate__c = System.today(),
                                                                SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                                SBQQ__Product__c               = product.Id,
                                                                SBQQ__Account__c               = PartnerAccount.Id,
                                                                Related_Order__c               = testOrder.Id,
                                                                SBQQ__OrderProduct__c          = oi.Id,
                                                                SBCF_Serial_Number__c          = '1234567',
                                                                SBQQ__RevisedSubscription__c   = null,
                                                                Renewed_By_Subscription__c     = null
                                                                );   

      insert testSub;                                                                

      TriggerHandler.clearAllBypasses();    
      MassAmendLineItemsController.createAssignedSerial(new List<Id>{testOrder.id});
    Test.stopTest();
    //Get the new quote lines
    List<Assigned_Serial__c> aslist = [Select Id from Assigned_Serial__c];

    System.assert(aslist!=null && !aslist.isEmpty());
  }    
}