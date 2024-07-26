@isTest
public with sharing class ProductListViewHelperExternalTest {
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

    SBQQ__Subscription__c testSub3 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                              SBQQ__Contract__c              = testContract.Id, 
                                                              SBQQ__SubscriptionStartDate__c = System.today().addDays(70),
                                                              SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                              SBQQ__Product__c               = testProd.Id,
                                                              SBQQ__Account__c = TestDataFactory.customers[0].Id); 
                                                              
    List<SBQQ__Subscription__c> subs = new List<SBQQ__Subscription__c>{testSub1, testSub2, testSub3};
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

    Assigned_Serial__c testAssigned3 = new Assigned_Serial__c(Serial__c        = testSerial.Id, 
                                                              Subscription__c = subs[2].Id);                                                              
    insert new List<Assigned_Serial__c>{testAssigned1, testAssigned2, testAssigned3};

    Contact testContact = [SELECT Id FROM Contact LIMIT 1];
    testContact.AccountId = TestDataFactory.customers[0].Id;
    update testContact;
    
    Id testContactId = testContact.Id;
	
    User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ]; 
    System.runAs ( thisUser ) {  
                //User
        User testUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Barracuda Partner Core'].Id,
            LastName = 'last',
            Email = 'puser000@barracuda.com', // required domain for user barracuda.com, barracudamsp.com
            Username = 'puser000@barracuda.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            );
        testUser.ContactId = testContactId;
        insert testUser;
    }

    TriggerHandler.clearAllBypasses();      

  }  
  @isTest static void test_shouldGetSerials() {

    //get the account
    Account acc = [Select Id from Account limit 1];

    //get Product Name
    Product2 prod = [Select Name from Product2 where ProductCode = 'TEST_SKU' Limit 1];

    Date fromDate = System.today().addDays(60);
    Date toDate = System.today().addDays(120);

    String fromDateString = fromDate.year() + '-' + String.valueOf(fromDate.month()).leftPad(2, '0') + '-' + String.valueOf(fromDate.day()).leftPad(2, '0');
    String toDateString = toDate.year() + '-' + String.valueOf(toDate.month()).leftPad(2, '0') + '-' + String.valueOf(toDate.day()).leftPad(2, '0');

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
                                AND Subscription__c!=null
                                AND Subscription__r.SBQQ__SubscriptionEndDate__c >= :System.today().addDays(60)
                                AND Subscription__r.SBQQ__SubscriptionEndDate__c <= :System.today().addDays(120)]; 
    

    System.debug('Account Id: ' + acc.Id);
    System.debug('Serial Id: ' + serial);

    User user = [SELECT Id from User WHERE email = 'puser000@barracuda.com'];

    Test.startTest();
    ProductListViewHelperExternal.SerialSubDetail serialAndSubs;
    System.runAs(user){
        //Get Serials
        serialAndSubs = ProductListViewHelperExternal.getSerialSubDetails('Customer', fromDateString, toDateString,'','','');
    }

    Test.stopTest();

    System.assert(aserials != null);
    System.assert(aserials.size() > 0);

    //Serial Assertion
    System.assert(serialAndSubs!=null);
    System.debug(serialAndSubs);
    System.assert(serialAndSubs.serials!=null && serialAndSubs.serials.size() > 0);
    System.assertEquals(serial.Base_Product_SKU__c.toLowerCase(),serialAndSubs.serials[0].baseProductSKU.toLowerCase());
    System.assertEquals(System.today().addDays(90),serialAndSubs.serials[0].contractEndDate);
    System.assertEquals(prod.Name,serialAndSubs.serials[0].productName);
    System.assertEquals(1,serialAndSubs.serials[0].quantity);
    System.assertEquals(serial.Serial_Number__c,serialAndSubs.serials[0].serialNumber);

  }

  @isTest static void test_shouldGetSerialsForReseller() {

    //get the account
    Account acc = [Select Id from Account limit 1];

    //get Product Name
    Product2 prod = [Select Name from Product2 where ProductCode = 'TEST_SKU' Limit 1];

    Date fromDate = System.today().addDays(60);
    Date toDate = System.today().addDays(120);

    String fromDateString = fromDate.year() + '-' + String.valueOf(fromDate.month()).leftPad(2, '0') + '-' + String.valueOf(fromDate.day()).leftPad(2, '0');
    String toDateString = toDate.year() + '-' + String.valueOf(toDate.month()).leftPad(2, '0') + '-' + String.valueOf(toDate.day()).leftPad(2, '0');

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
                                AND Subscription__c!=null
                                AND Subscription__r.SBQQ__SubscriptionEndDate__c >= :System.today().addDays(60)
                                AND Subscription__r.SBQQ__SubscriptionEndDate__c <= :System.today().addDays(120)]; 
    

    System.debug('Account Id: ' + acc.Id);
    System.debug('Serial Id: ' + serial);

    User user = [SELECT Id from User WHERE email = 'puser000@barracuda.com'];

    Test.startTest();
    ProductListViewHelperExternal.SerialSubDetail serialAndSubs;
    System.runAs(user){
        //Get Serials
        serialAndSubs = ProductListViewHelperExternal.getSerialSubDetails('Reseller', fromDateString, toDateString,'','','');
    }

    Test.stopTest();

    System.assert(aserials != null);
    System.assert(aserials.size() > 0);

    //Serial Assertion
    System.assert(serialAndSubs!=null);
    System.debug(serialAndSubs);
    System.assert(serialAndSubs.serials!=null && serialAndSubs.serials.size() > 0);
    System.assertEquals(serial.Base_Product_SKU__c.toLowerCase(),serialAndSubs.serials[0].baseProductSKU.toLowerCase());
    System.assertEquals(System.today().addDays(90),serialAndSubs.serials[0].contractEndDate);
    System.assertEquals(prod.Name,serialAndSubs.serials[0].productName);
    System.assertEquals(1,serialAndSubs.serials[0].quantity);
    System.assertEquals(serial.Serial_Number__c,serialAndSubs.serials[0].serialNumber);

  }

  @isTest static void test_shouldGetSerialsForDisti() {

    //get the account
    Account acc = [Select Id from Account limit 1];

    //get Product Name
    Product2 prod = [Select Name from Product2 where ProductCode = 'TEST_SKU' Limit 1];

    Date fromDate = System.today().addDays(60);
    Date toDate = System.today().addDays(120);

    String fromDateString = fromDate.year() + '-' + String.valueOf(fromDate.month()).leftPad(2, '0') + '-' + String.valueOf(fromDate.day()).leftPad(2, '0');
    String toDateString = toDate.year() + '-' + String.valueOf(toDate.month()).leftPad(2, '0') + '-' + String.valueOf(toDate.day()).leftPad(2, '0');

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
                                AND Subscription__c!=null
                                AND Subscription__r.SBQQ__SubscriptionEndDate__c >= :System.today().addDays(60)
                                AND Subscription__r.SBQQ__SubscriptionEndDate__c <= :System.today().addDays(120)]; 
    

    System.debug('Account Id: ' + acc.Id);
    System.debug('Serial Id: ' + serial);

    User user = [SELECT Id from User WHERE email = 'puser000@barracuda.com'];

    Test.startTest();
    ProductListViewHelperExternal.SerialSubDetail serialAndSubs;
    System.runAs(user){
        //Get Serials
        serialAndSubs = ProductListViewHelperExternal.getSerialSubDetails('Distributor', fromDateString, toDateString,'','','');
    }

    Test.stopTest();

    System.assert(aserials != null);
    System.assert(aserials.size() > 0);

    //Serial Assertion
    System.assert(serialAndSubs!=null);
    System.debug(serialAndSubs);
    System.assert(serialAndSubs.serials!=null && serialAndSubs.serials.size() > 0);
    System.assertEquals(serial.Base_Product_SKU__c.toLowerCase(),serialAndSubs.serials[0].baseProductSKU.toLowerCase());
    System.assertEquals(System.today().addDays(90),serialAndSubs.serials[0].contractEndDate);
    System.assertEquals(prod.Name,serialAndSubs.serials[0].productName);
    System.assertEquals(1,serialAndSubs.serials[0].quantity);
    System.assertEquals(serial.Serial_Number__c,serialAndSubs.serials[0].serialNumber);

  }

  @isTest static void test_shouldGetSerialsForNoAccountType() {

    //get the account
    Account acc = [Select Id from Account limit 1];

    //get Product Name
    Product2 prod = [Select Name from Product2 where ProductCode = 'TEST_SKU' Limit 1];

    Date fromDate = System.today().addDays(60);
    Date toDate = System.today().addDays(120);

    String fromDateString = fromDate.year() + '-' + String.valueOf(fromDate.month()).leftPad(2, '0') + '-' + String.valueOf(fromDate.day()).leftPad(2, '0');
    String toDateString = toDate.year() + '-' + String.valueOf(toDate.month()).leftPad(2, '0') + '-' + String.valueOf(toDate.day()).leftPad(2, '0');

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
                                AND Subscription__c!=null
                                AND Subscription__r.SBQQ__SubscriptionEndDate__c >= :System.today().addDays(60)
                                AND Subscription__r.SBQQ__SubscriptionEndDate__c <= :System.today().addDays(120)]; 
    

    System.debug('Account Id: ' + acc.Id);
    System.debug('Serial Id: ' + serial);

    User user = [SELECT Id from User WHERE email = 'puser000@barracuda.com'];

    Test.startTest();
    ProductListViewHelperExternal.SerialSubDetail serialAndSubs;
    System.runAs(user){
        //Get Serials
        serialAndSubs = ProductListViewHelperExternal.getSerialSubDetails('asdf', fromDateString, toDateString,'','','');
    }

    Test.stopTest();

    System.assert(aserials != null);
    System.assert(aserials.size() > 0);

    //Serial Assertion
    System.assert(serialAndSubs!=null);
    System.debug(serialAndSubs);
    System.assert(serialAndSubs.serials!=null && serialAndSubs.serials.size() > 0);
    System.assertEquals(serial.Base_Product_SKU__c.toLowerCase(),serialAndSubs.serials[0].baseProductSKU.toLowerCase());
    System.assertEquals(System.today().addDays(90),serialAndSubs.serials[0].contractEndDate);
    System.assertEquals(prod.Name,serialAndSubs.serials[0].productName);
    System.assertEquals(1,serialAndSubs.serials[0].quantity);
    System.assertEquals(serial.Serial_Number__c,serialAndSubs.serials[0].serialNumber);

  }
}