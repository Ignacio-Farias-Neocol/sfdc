/**
* @author Salesforce Services
* @date 03/04/2020
*
* @group Test Class
*
* @description Test class for the Product List View Helper. Created as part of SFDC-9682
*
*/
@isTest
public with sharing class ProductListViewHelperTest {
  //Test data set up

  @testSetup static void setup() {

    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   

    //Product
    Product2 testProd = TestDataFactory.products[0];
    testProd.Base_SKU__c  = 'TEST_SKU';
    testProd.ProductCode  = 'TEST_SKU';
    update testProd;

    //Opportunity
    Opportunity testOpp = TestDataFactory.opportunities[0];
    
    //Quote
    SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, 
                                                  SBQQ__Primary__c      = true);
    insert testQuote;

    //Contract
    Contract testContract = new Contract(AccountId            = TestDataFactory.customers[0].Id, 
                                         Business_Group__c    = 'Core', 
                                         SBQQ__Quote__c       = testQuote.Id, 
                                         StartDate            = System.today(),
                                         Reseller__c          = TestDataFactory.partners[0].Id,
                                         SBQQ__RenewalTerm__c = 12);
    insert testContract;

    //Update opportunity to populate renewed contract
    testOpp.SBQQ__RenewedContract__c = testContract.Id;

    //Order
    Order testOrder = TestDataFactory.orders[0];
    testOrder.Active_Contract__c = testContract.Id;
    update testOrder;

    //Subscription

    SBQQ__Subscription__c testSub1 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                              SBQQ__Contract__c              = testContract.Id, 
                                                              SBQQ__SubscriptionStartDate__c = System.today(),
                                                              SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                              SBQQ__Product__c               = testProd.Id,
                                                              SBQQ__Account__c = TestDataFactory.customers[0].Id); 

    SBQQ__Subscription__c testSub2 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                              SBQQ__Contract__c              = testContract.Id, 
                                                              SBQQ__SubscriptionStartDate__c = System.today().addDays(-90),
                                                              SBQQ__SubscriptionEndDate__c   = System.today().addDays(-80),
                                                              SBQQ__Product__c               = testProd.Id,
                                                              SBQQ__Account__c = TestDataFactory.customers[0].Id); 
                                                              
    List<SBQQ__Subscription__c> subs = new List<SBQQ__Subscription__c>{testSub1, testSub2};
    insert  subs;

    //Serial
    Serial__c testSerial = new Serial__c(Serial_Number__c     = '1234567',
                                          Order__c            = testOrder.Id,
                                          Base_Product_SKU__c = 'TEST_SKU');
    insert testSerial;

    //Assigned Serial
    Assigned_Serial__c testAssigned1 = new Assigned_Serial__c(Serial__c        = testSerial.Id, 
                                                              Subscription__c = subs[0].Id);

    Assigned_Serial__c testAssigned2 = new Assigned_Serial__c(Serial__c        = testSerial.Id, 
                                                              Subscription__c = subs[1].Id);                                                              
    insert new List<Assigned_Serial__c>{testAssigned1, testAssigned2};
    TriggerHandler.clearAllBypasses();      

  }  
  @isTest static void test_shouldGetSerials() {

    //get the account
    Account acc = [Select Id from Account limit 1];

    //get Product Name
    Product2 prod = [Select Name from Product2 where ProductCode = 'TEST_SKU' Limit 1];

    //get Serial
    Serial__c serial = [SELECT Base_Product_SKU__c,
                               Order__r.Active_Contract__r.EndDate, 
                               Id,
                               Order__r.Opportunity.SBQQ__RenewedContract__r.StartDate,
                               Order__r.Active_Contract__r.Reseller__r.Name,
                               Serial_Number__c,
                               Status__c FROM Serial__c WHERE Order__r.AccountId = :acc.Id Limit 1];
    //get Assigned Serial
    List<Assigned_Serial__c> aserials = [SELECT Subscription__c, 
                                 Subscription__r.SBQQ__ProductName__c,
                                 Subscription__r.SBQQ__Quantity__c,
                                 Subscription__r.SBQQ__SubscriptionStartDate__c,
                                 Subscription__r.SBQQ__SubscriptionEndDate__c,
                                 Subscription__r.Active__c
                          FROM Assigned_Serial__c 
                          WHERE Serial__c = :serial.Id 
                          AND Subscription__c!=null]; 
    

    System.debug('Account Id: ' + acc.Id);
    System.debug('Serial Id: ' + serial);

    Test.startTest();

    //Get Serials
    ProductListViewHelper.SerialSubDetail serialAndSubs = ProductListViewHelper.getSerialSubDetailsUsingAccountId(acc.Id, 'Customer');

    //Get Subs 
    List<ProductListViewHelper.SubDetail> subs = ProductListViewHelper.getSubscriptions(serial.Id);
    Test.stopTest();

    //Serial Assertion
    System.assert(serialAndSubs!=null);
    System.assert(serialAndSubs.serials!=null && serialAndSubs.serials.size() == 1);
    System.assertEquals(serial.Base_Product_SKU__c.toLowerCase(),serialAndSubs.serials[0].baseProductSKU.toLowerCase());
    System.assertEquals(System.today().addDays(90),serialAndSubs.serials[0].contractEndDate);
    System.assertEquals(prod.Name,serialAndSubs.serials[0].productName);
    System.assertEquals(1,serialAndSubs.serials[0].quantity);
    System.assertEquals(serial.Serial_Number__c,serialAndSubs.serials[0].serialNumber);

    //Subscription Assertion
    System.assert(subs!=null && subs.size() == 2);
    System.assertEquals(aserials[0].Subscription__r.SBQQ__ProductName__c,subs[0].productName);
    System.assertEquals(aserials[0].Subscription__r.SBQQ__Quantity__c,subs[0].quantity);
    System.assertEquals(aserials[0].Subscription__r.SBQQ__SubscriptionEndDate__c,subs[0].subEndDate);
    System.assertEquals(aserials[0].Subscription__r.SBQQ__SubscriptionStartDate__c,subs[0].subStartDate);
  }

  @isTest static void test_shouldGetURL() {

    Test.startTest();

    String url = ProductListViewHelper.getUrl('testpage');

    Test.stopTest();

    //Serial Assertion
    System.assert(String.isNotBlank(url));
    System.assert(url.contains('testpage'));
  }

   @isTest static void testGetUrlcertWithValidInputs() {
        Serial__c testSerial = [SELECT Id FROM Serial__c Limit 1];
        String pageName = 'TestPage';
        
        Test.startTest();
        String result = ProductListViewHelper.getUrlcert(pageName, testSerial.Id);
        Test.stopTest();
        
        // Verify the URL - Adjust this assertion based on whether the test is running in a community or not
        String expectedUrl = URL.getSalesforceBaseUrl().toExternalForm()+'/apex/'+pageName;
        System.assertEquals(expectedUrl, result);
    }
}