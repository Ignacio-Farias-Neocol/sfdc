/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-07-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class CancelBucketLineItemsControllerTest {

  @testSetup
  static void setup() {
    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');    

    Product2 testParentProduct                  = new Product2();
    testParentProduct.Name                      = 'Parent Product';
    testParentProduct.is_pst_enterprise__c      = true;
    testParentProduct.Base_SKU__c               = 'TEST_SKU';
    testParentProduct.ProductCode               = 'TEST_SKU'; 
    testParentProduct.Product_Sales_Grouping__c = 'ESS';   
    testParentProduct.Family                    = 'Essentials'; 
    testParentProduct.MSP_Product__c            = true;

    Product2 testChildProduct             = new Product2();
    testChildProduct.Name                 = 'Child Product';
    testChildProduct.is_pst_enterprise__c = true;
    testChildProduct.Base_SKU__c          = 'TEST_SKU_CHILD';
    testChildProduct.ProductCode          = 'TEST_SKU_CHILD';
    testChildProduct.SBQQ__Component__c   = true;
    testChildProduct.Family               = 'Essentials';
    testParentProduct.MSP_Product__c      = true;

    insert new List<Product2>{testParentProduct, testChildProduct};
   
    SBQQ__ProductOption__c testPO = new SBQQ__ProductOption__c( SBQQ__Number__c = 10,
                                                                SBQQ__ConfiguredSKU__c = testParentProduct.Id,
                                                                SBQQ__OptionalSKU__c = testChildProduct.Id,
                                                                SBQQ__Type__c = 'Component');

    insert testPO;  
    Pricebook2 customPB = new Pricebook2(IsActive = true,
                                         Name = 'CustomPB');
    insert customPB;

 
    PricebookEntry[] pbeList = new PricebookEntry[] {
      new PricebookEntry (Product2ID=testParentProduct.id,Pricebook2ID=Test.getStandardPricebookId(),UnitPrice=50, isActive=true),
      new PricebookEntry (Product2ID=testChildProduct.id,Pricebook2ID=Test.getStandardPricebookId(),UnitPrice=50, isActive=true),
      new PricebookEntry (Product2ID=testParentProduct.id,Pricebook2ID=customPB.Id,UnitPrice=50, isActive=true),
      new PricebookEntry (Product2ID=testChildProduct.id,Pricebook2ID=customPB.id,UnitPrice=50, isActive=true)};
    insert pbeList;    

    Map<Id, Id> productPBEMap = new Map<Id, Id>();
   
    for(PricebookEntry pbe: pbeList){
      if(pbe.Pricebook2Id == customPB.Id){
        productPBEMap.put(pbe.Product2Id, pbe.Id);
      }
    }
Test.startTest();
    Account partnerAccount = TestDataFactory.partners[0];
    partnerAccount.User_Na__c = 'testpartner';   
    partnerAccount.Type = 'Partner - Reseller';
    partnerAccount.Compliance_Status__c = 'Active';
    update partnerAccount;
   
    Opportunity testOpp = TestDataFactory.opportunities[0];
    testOpp.Pricebook2Id = customPB.Id;
    update testOpp;

    SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, 
                                                  SBQQ__Primary__c      = true,
                                                  SBQQ__PricebookId__c = customPB.Id);
    insert testQuote;

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
    Test.StopTest();
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

    TriggerHandler.clearAllBypasses();  
  }

  @isTest static void test_shouldCreateNewQL() {

    SBQQ__Quote__c testQuote = [Select Id from SBQQ__Quote__c limit 1];

    SBQQ__QuoteLine__c parentQuoteLine = [Select Id from SBQQ__QuoteLine__c where SBQQ__Bundle__c = true limit 1];

    //Test.startTest();
        PageReference pageRef = Page.CancelBucketLineItems;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', testQuote.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(testQuote);
        CancelBucketLineItemsController quoteExtension = new CancelBucketLineItemsController(sc);
        System.debug('***MESSAGE**' + quoteExtension.message);

        System.assert(quoteExtension.quoteLineIds!=null && !quoteExtension.quoteLineIds.isEmpty());
        System.assert(quoteExtension.getCancelBucketQL()!=null && !quoteExtension.getCancelBucketQL().isEmpty());
        System.assert(quoteExtension.getFSMList()!=null && !quoteExtension.getFSMList().isEmpty());
        Test.startTest();
        for(CancelBucketLineItemsController.QuoteLineSelection ql: quoteExtension.quoteLineIds){
            if(ql.id == parentQuoteLine.Id){
                ql.checkBox = true;
            }
        }

        quoteExtension.cancelBucketLineItems();
    Test.stopTest();

    List<SBQQ__QuoteLine__c> qlList = [Select Id,Terminate_Serials__c,SBQQ__Quantity__c from SBQQ__QuoteLine__c where SBQQ__Quote__c = :testQuote.Id];

    //System.assert(qlList!=null && qlList[0].Terminate_Serials__c==True && qlList[0].SBQQ__Quantity__c==0, '***Error: ' + quoteExtension.message);
  }    
}