@isTest
public with sharing class RenewSubscriptionHelperTest {

    @testSetup static void setup() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
    
        //Product
        Product2 testProd = TestDataFactory.products[0];
        testProd.Base_SKU__c  = 'TEST_SKU';
        testProd.ProductCode  = 'TEST_SKU';
        testProd.Lifecycle_Status__c = 'Released';
        update testProd;

        Account customer = new Account();
        customer.Is_Unit_Test__c  = true;
        customer.Name = 'Customer 001';
        customer.billingStreet = '415 Mission Street';
        customer.billingCity = 'San Francisco';
        customer.BillingCountryCode = 'US';
        customer.billingStateCode = 'CA';
        customer.billingPostalCode = '94105'; 
        customer.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        customer.Status__c = 'Active';
        customer.Territory_ID__c = '123';
        customer.AccountSource = 'Renewal';
        customer.Terr_Theater__c = 'APAC';
        INSERT customer;

        Country__c testCountry = new Country__c(Name = 'TEST_COUNTRY',
                                                Country_ISO__c = 'US'
                                                );
        insert testCountry;
    
        State__c testState = new State__c(Name = 'TEST_STATE',
                                          Country__c = testCountry.Id
                                         );
        insert testState;

        Address__c testAddress = new Address__c(
          Account__c = customer.Id,
          Street__c = 'TEST_STREET',
          State__c = testState.Id,
          City__c = 'TEST_CITY',
          Zip_Postal_Code__c = 'TEST_ZIP',
          Country__c = testCountry.Id,
          Type__c = Address__c.Type__c.getDescribe().getPicklistValues()[0].getValue()
        );
        
        Contact rec = new Contact();
        rec.LastName = 'Test';
        rec.FirstName = 'Test';
        rec.Email = 'test.test@test.com';
        rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        rec.AccountId = customer.Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';
        INSERT rec;

        customer.Primary_Contact__c = rec.Id;
        UPDATE customer;
                
        //Opportunity
        Opportunity testOpp1 = new Opportunity();
        testOpp1.Name ='Oppty 001';
        testOpp1.AccountID = customer.Id;
        testOpp1.Bill_To_Account__c = customer.Id;
        testOpp1.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        testOpp1.Model_Series__c = 'API';
        testOpp1.StageName = 'Accepted';
        testOpp1.Amount = 3000;
        testOpp1.CloseDate = System.today();
        testOpp1.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        testOpp1.Bypass_Validation__c = true;
        testOpp1.Is_Unit_Test__c = true;
        testOpp1.LeadSource = 'Renewal';
        testOpp1.BypassBusinessGroupValidation__c = True;
        testOpp1.Billing_Address__c = testAddress.Id;
        testOpp1.Street__c = testAddress.Street__c;
        testOpp1.City__c = testAddress.City__c;
        testOpp1.State__c = testState.Name;
        testOpp1.Country__c = testCountry.Name;
        testOpp1.Country_ISO_Code__c = testCountry.Country_ISO__c;
        testOpp1.Zip_Postal_Code__c = testAddress.Zip_Postal_Code__c;
        testOpp1.Shipping_Address__c = testAddress.Id;
        testOpp1.Ship_To_Street__c = testAddress.Street__c;
        testOpp1.Ship_To_City__c = testAddress.City__c;
        testOpp1.Ship_To_State__c = testState.Name;
        testOpp1.Ship_To_Country__c = testCountry.Name;
        testOpp1.Shipping_Country_ISO_Code__c = testCountry.Country_ISO__c;
        testOpp1.Ship_To_Zip_Postal_Code__c = testAddress.Zip_Postal_Code__c;
        INSERT testOpp1;
        
        //Quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp1.Id, 
                                                      SBQQ__Primary__c      = true);
        insert testQuote;
    
        //Contract
        Contract testContract = new Contract(AccountId            = customer.Id, 
                                             Business_Group__c    = 'Core', 
                                             SBQQ__Quote__c       = testQuote.Id, 
                                             StartDate            = System.today(),
                                             Reseller__c          = customer.Id,
                                             SBQQ__RenewalTerm__c = 12);
        Contract testContract2 = new Contract(AccountId            = customer.Id, 
                                             Business_Group__c    = 'Core', 
                                             SBQQ__Quote__c       = testQuote.Id, 
                                             StartDate            = System.today(),
                                             Reseller__c          = customer.Id,
                                             SBQQ__RenewalTerm__c = 12);
        insert new List<Contract>{testContract, testContract2};
    
        //Order
        Order testOrder = TestDataFactory.orders[0];
        testOrder.Active_Contract__c = testContract.Id;
        update testOrder;
    
        //Subscription
    
        SBQQ__Subscription__c testSub1 = new SBQQ__Subscription__c(SBQQ__Quantity__c             = 1, 
                                                                  SBQQ__Contract__c              = testContract.Id, 
                                                                  SBQQ__SubscriptionStartDate__c = System.today().addDays(150),
                                                                  SBQQ__SubscriptionEndDate__c   = System.today().addDays(190),
                                                                  SBQQ__Product__c               = testProd.Id,
                                                                  SBQQ__Account__c               = customer.Id); 
    
        SBQQ__Subscription__c testSub2 = new SBQQ__Subscription__c(SBQQ__Quantity__c             = 1, 
                                                                  SBQQ__Contract__c              = testContract.Id, 
                                                                  SBQQ__SubscriptionStartDate__c = System.today().addDays(250),
                                                                  SBQQ__SubscriptionEndDate__c   = System.today().addDays(280),
                                                                  SBQQ__Product__c               = testProd.Id,
                                                                  SBQQ__Account__c               = customer.Id); 
        
        SBQQ__Subscription__c testSub3 = new SBQQ__Subscription__c(SBQQ__Quantity__c             = 1, 
                                                                  SBQQ__Contract__c              = testContract2.Id, 
                                                                  SBQQ__SubscriptionStartDate__c = System.today().addDays(250),
                                                                  SBQQ__SubscriptionEndDate__c   = System.today().addDays(280),
                                                                  SBQQ__Product__c               = testProd.Id,
                                                                  SBQQ__Account__c               = customer.Id);
                                                                  
        List<SBQQ__Subscription__c> subs = new List<SBQQ__Subscription__c>{testSub1, testSub2, testSub3};
        insert subs;
    
        //Serial
        Serial__c testSerial1 = new Serial__c(Serial_Number__c     = '1234567',
                                              Order__c            = testOrder.Id,
                                              Base_Product_SKU__c = 'TEST_SKU');

        // Serial__c testSerial2 = new Serial__c(Serial_Number__c     = '1234568',
        //                                       Order__c            = testOrder.Id,
        //                                       Base_Product_SKU__c = 'TEST_SKU');
        insert new List<Serial__c>{testSerial1};
    
        //Assigned Serial
        Assigned_Serial__c testAssigned1 = new Assigned_Serial__c(Serial__c        = testSerial1.Id, 
                                                                  Subscription__c = subs[0].Id);
    
        Assigned_Serial__c testAssigned2 = new Assigned_Serial__c(Serial__c        = testSerial1.Id, 
                                                                  Subscription__c = subs[1].Id);

        Assigned_Serial__c testAssigned3 = new Assigned_Serial__c(Serial__c        = testSerial1.Id, 
                                                                  Subscription__c = subs[2].Id);

        insert new List<Assigned_Serial__c>{testAssigned1, testAssigned2, testAssigned3};

        testContract.SBQQ__RenewalOpportunity__c = testOpp1.Id;
        update testContract;

        TriggerHandler.clearAllBypasses();      
    
      }

      @isTest static void test_shouldGetQuoteAndContractIds() {

        Serial__c serial = [SELECT Id FROM Serial__c LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Contract contract = [SELECT Id FROM Contract LIMIT 1];

        RenewSubscriptionHelper.ContractQuoteIds contractQuoteId = RenewSubscriptionHelper.getRenewalQuote(serial.Id);
        System.assertEquals(quote.Id, contractQuoteId.quoteId);
        System.assertEquals(contract.Id, contractQuoteId.contractId);
      }

      @isTest static void test_shouldSetPortalFlagTrue() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        RenewSubscriptionHelper.makeQuoteAvailableOnPortal(quote.Id);
        SBQQ__Quote__c quote1 = [SELECT Id,Available_on_Portal__c FROM SBQQ__Quote__c LIMIT 1];
        System.assertEquals(true, quote1.Available_on_Portal__c);
      }

      @isTest static void test_shouldApproveQuote() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        RenewSubscriptionHelper.approveGeneratedQuote(new List<Id>{quote.Id});
        Test.stopTest();
        SBQQ__Quote__c quote1 = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];
        System.assertEquals('Approved', quote1.SBQQ__Status__c);
      }

      @isTest static void test_shouldGetMainRenewalQuote() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Profile pr = [SELECT Id,Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User();
        testUser.Alias = 'usertest';
        testUser.Email = 'UserTest@test.com';
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.LastName = 'UserTest';
        testUser.LanguageLocaleKey = 'en_US';
        testUser.LocaleSidKey = 'en_US';
        testUser.ProfileId = pr.Id;
        testUser.TimeZoneSidKey = 'America/Los_Angeles';
        testUser.UserName = 'TestUser@barracudatest.com';
        System.runAs(thisUser) {
          insert testUser;
        }

        Account account = [SELECT Id FROM Account LIMIT 1];
        AccountShare newAcctShare = new AccountShare();
        //Id of record being shared
        newAcctShare.AccountId = account.Id;
        newAcctShare.UserOrGroupId = testUser.Id;
        newAcctShare.AccountAccessLevel = 'Edit';
        newAcctShare.ContactAccessLevel = 'Edit';
        newAcctShare.OpportunityAccessLevel = 'Edit';

        insert newAcctShare;

        Serial__c serial = [SELECT Id FROM Serial__c LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        Test.startTest();
        System.runAs(testUser) {
          String mainQuoteId = RenewSubscriptionHelper.renewSubscriptions(serial.Id);
          System.assertEquals(quote.Id, mainQuoteId);
        }
        Test.stopTest();
      }

      @isTest static void test_shouldPollExistingQuote() {
        SBQQ.TriggerControl.disable();
        Contract contract = [SELECT Id, SBQQ__RenewalOpportunity__r.SBQQ__PrimaryQuote__c FROM Contract LIMIT 1];
        contract.SBQQ__RenewalQuoted__c = true;
        update contract;
        SBQQ.TriggerControl.enable();

        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        String actualQuoteId = RenewSubscriptionHelper.pollRenewalQuote(contract.Id);
        System.assertEquals(quote.Id, actualQuoteId);
      }

      @isTest static void test_shouldNonPollExistingQuote() {
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        delete quote;
        String actualQuoteId = RenewSubscriptionHelper.pollRenewalQuote(contract.Id);
        System.assertEquals(null, actualQuoteId);
      }
    
    @isTest static void test_callQuoteCalculator() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        Boolean resBool = RenewSubscriptionHelper.callQuoteCalculator(quote.Id);
        Test.stopTest();
    }
    
    @isTest static void test_pollCalculatedQuote() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Test.startTest();
        Boolean resBool = RenewSubscriptionHelper.pollCalculatedQuote(quote.Id);
        Test.stopTest();
    }

}