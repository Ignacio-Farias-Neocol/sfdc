@isTest
public with sharing class RenewalCheckoutHelperTest {
  //Test data set up

  @testSetup static void setup() {
    SBQQ.TriggerControl.enable();
    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');

    Account testAcc = TestDataFactory.customers[0];

    Credit_Card__c cc1 = new Credit_Card__c();
		cc1.Account__c = testAcc.Id;
		cc1.Last_4_of_CC__c = '1234';
		cc1.Card_Type__c = 	Credit_Card__c.Card_Type__c.getDescribe().getPicklistValues()[0].getValue();
		cc1.Expiration__c = '01/23';

		insert cc1;

    Contact testContact = TestDataFactory.customerContacts[0];

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
			testUser.ContactId = testContact.Id;
			insert testUser;
		}

    //Product
    Product2 testProd = TestDataFactory.products[0];
    testProd.Base_SKU__c  = 'TEST_SKU';
    testProd.ProductCode  = 'TEST_SKU';
    testProd.Name = 'TEST_NAME';
    upsert testProd;

    //Opportunity
    Opportunity testOpp = TestDataFactory.opportunities[0];
    testOpp.PurchaseOrderID__c = 'test PO';
    update testOpp;
    
    //Quote
    SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, 
                                                  SBQQ__Primary__c      = true,
                                                  SBCF_Reseller__c      = TestDataFactory.customers[0].Id,
                                                  Quote_Name__c         = 'TEST_QUOTE_NAME'
                                                  );
    insert testQuote;

    testOpp.SBQQ__PrimaryQuote__c = testQuote.Id;

    Contract testContract = new Contract(AccountId                   = TestDataFactory.customers[0].Id, 
                                         Business_Group__c           = 'Core', 
                                         SBQQ__Quote__c              = testQuote.Id, 
                                         StartDate                   = System.today(),
                                         Reseller__c                 = TestDataFactory.partners[0].Id,
                                         SBQQ__RenewalTerm__c        = 12,
                                         SBQQ__RenewalOpportunity__c = testOpp.Id);

    Country__c testCountry = new Country__c(Name = 'TEST_COUNTRY');
    insert testCountry;

    State__c testState = new State__c(Name = 'TEST_STATE',
                                      Country__c = testCountry.Id
                                     );
    insert testState;

    Address__c testShipping = new Address__c(
      Account__c = testAcc.Id,
      Street__c = 'TEST_STREET',
      State__c = testState.Id,
      City__c = 'TEST_CITY',
      Zip_Postal_Code__c = 'TEST_ZIP',
      Country__c = testCountry.Id,
      Type__c = Address__c.Type__c.getDescribe().getPicklistValues()[0].getValue()
    );

    Address__c testBilling = new Address__c(
      Account__c = testAcc.Id,
      Street__c = 'TEST_STREET',
      State__c = testState.Id,
      City__c = 'TEST_CITY',
      Zip_Postal_Code__c = 'TEST_ZIP',
      Country__c = testCountry.Id,
      Type__c = Address__c.Type__c.getDescribe().getPicklistValues()[0].getValue()
    );

    List<Address__c> testAddress = new List<Address__c>{testShipping, testBilling};
    insert testAddress;

    testContract.Shipping_Address__c = testShipping.Id;
    testContract.Billing_Address__c = testBilling.Id;
    insert testContract;


    //QuoteLines
    SBQQ__QuoteLine__c testQuoteLine1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c                   = testQuote.Id,
                                                               SBQQ__Product__c                 = testProd.Id,
                                                               SBQQ__Quantity__c                = 1,
                                                               SBQQ__StartDate__c               = System.today(),
                                                               SBQQ__EndDate__c                 = System.today().addDays(90),
                                                               Total_List_Discount__c           = 0.0,
                                                               SBCF_Serial_Number__c            = '12345'
                                                              );

    insert testQuoteLine1;

    TriggerHandler.clearAllBypasses();      
    SBQQ.TriggerControl.disable();
  }  
  @isTest static void test_shouldGetQuoteLines() {

    //get the opportunity
    Opportunity opp = [Select Id from Opportunity limit 1];
    //get Product Name
    Product2 prod = [Select Name from Product2 where ProductCode = 'TEST_SKU' Limit 1];

    //get Quote
    SBQQ__Quote__c quote = [SELECT
                            SBQQ__Opportunity2__c,
                            SBQQ__Opportunity2__r.Bill_To_Account__c,
                            SBQQ__Opportunity2__r.Bill_To_Account__r.Name,
                            Quote_Name__c,
                            Name //This is the quote number
                            FROM SBQQ__Quote__c
                            WHERE SBQQ__Opportunity2__c = :opp.Id
                            LIMIT 1
                        ];
    
    // get QuoteLineData
    SBQQ__QuoteLine__c quoteLine = [SELECT 
                            Id,
                            SBQQ__Quote__r.SBQQ__Opportunity2__c,
                            SBQQ__Quote__r.SBQQ__Opportunity2__r.Bill_To_Account__c,
                            SBQQ__Quote__r.SBQQ__Opportunity2__r.Bill_To_Account__r.Name,
                            SBQQ__Quote__r.SBQQ__Opportunity2__r.Account.Name,
                            SBQQ__Product__r.Base_SKU__c,
                            SBQQ__Product__r.Name,
                            SBQQ__Quantity__c,
                            SBQQ__StartDate__c,
                            SBQQ__EndDate__c,
                            Extended_Published_List_Price__c,
                            Total_List_Discount__c,
                            Final_Price2__c,
                            SBQQ__Quote__r.SBCF_Reseller__r.Record_Type__c,
                            SBQQ__Quote__r.SBCF_Reseller__r.Name,
                            SBQQ__Quote__r.Quote_Name__c,
                            SBCF_Serial_Number__c,
                            Product_Description__c
                            FROM SBQQ__QuoteLine__c 
                            WHERE SBQQ__Quote__c = :quote.Id LIMIT 1];

    Test.startTest();

    // Get Quotes
    RenewalCheckoutHelper.SerialQuoteLineDetail serialAndQuoteLines = RenewalCheckoutHelper.getQuoteLineDetails(quote.Id);
    
    // Quote Assertion
    System.assert(serialAndQuoteLines != null);
    System.assertEquals(quote.SBQQ__Opportunity2__c, serialAndQuoteLines.quote.SBQQ__Opportunity2__c);
    System.assertEquals(quote.SBQQ__Opportunity2__r.Bill_To_Account__c, serialAndQuoteLines.quote.SBQQ__Opportunity2__r.Bill_To_Account__c);
    System.assertEquals(quote.SBQQ__Opportunity2__r.Bill_To_Account__r.Name, serialAndQuoteLines.quote.SBQQ__Opportunity2__r.Bill_To_Account__r.Name);
    System.assertEquals(quote.Quote_Name__c, serialAndQuoteLines.quote.Quote_Name__c);
    System.assertEquals(quote.Name, serialAndQuoteLines.quote.Name);

    //Assert Serial
    String serialId = quoteLine.SBCF_Serial_Number__c;
    System.assertEquals(serialAndQuoteLines.serials[0].id, serialId);
    System.assertEquals(serialAndQuoteLines.serials[0].serialNumber, serialId);

    //Assert QuoteLine
    RenewalCheckoutHelper.QuoteLineDetail quoteLineDetail = serialAndQuoteLines.serials[0].subs[0];
    
    System.assertEquals(quoteLineDetail.endUserName, quoteLine.SBQQ__Quote__r.SBQQ__Opportunity2__r.Account.Name);
    System.assertEquals(quoteLineDetail.SKU, quoteLine.SBQQ__Product__r.Base_SKU__c);
    //quoteLine.Product_Description__c this value is null. There is data cleaning to convert null into empty string
    //System.assertEquals(quoteLineDetail.product, '');
    System.assertEquals(quoteLineDetail.quantity, quoteLine.SBQQ__Quantity__c);
    System.assertEquals(quoteLineDetail.startDate, quoteLine.SBQQ__StartDate__c);
    System.assertEquals(quoteLineDetail.endDate, quoteLine.SBQQ__EndDate__c);
    System.assertEquals(quoteLineDetail.extListPrice, quoteLine.Extended_Published_List_Price__c);
    System.assertEquals(quoteLineDetail.totalListDisc, quoteLine.Total_List_Discount__c);
    System.assertEquals(quoteLineDetail.extFinalPrice, quoteLine.Final_Price2__c);
    System.assertEquals(quoteLineDetail.resellerAccountType, quoteLine.SBQQ__Quote__r.SBCF_Reseller__r.Record_Type__c);
    System.assertEquals(quoteLineDetail.resellerAccountName, quoteLine.SBQQ__Quote__r.SBCF_Reseller__r.Name);
  }

  @isTest static void test_shouldGetAddresses() {
    SBQQ__Quote__c quoteRecord = [SELECT 
                                  Shipping_Address__c,
                                  Shipping_Address__r.Account__r.Name,
                                  Shipping_Address__r.Street__c,
                                  Shipping_Address__r.State__r.Name,
                                  Shipping_Address__r.City__c,
                                  Shipping_Address__r.Zip_Postal_Code__c,
                                  Shipping_Address__r.Country__r.Name,
                                  Billing_Address__c,
                                  Billing_Address__r.Account__r.Name,
                                  Billing_Address__r.Account__r.Bill_To_Email__c,
                                  Billing_Address__r.Street__c,
                                  Billing_Address__r.State__r.Name,
                                  Billing_Address__r.City__c,
                                  Billing_Address__r.Zip_Postal_Code__c,
                                  Billing_Address__r.Country__r.Name
                                  FROM SBQQ__Quote__c
                                  LIMIT 1];
  
    SBQQ__Quote__c quote = RenewalCheckoutHelper.getBillingShippingAddresses(quoteRecord.Id);
  
    System.assertEquals(quoteRecord.Id, quote.Id);
    System.assertEquals(quoteRecord.Shipping_Address__r.Account__r.Name, quote.Shipping_Address__r.Account__r.Name);
    System.assertEquals(quoteRecord.Shipping_Address__r.Street__c, quote.Shipping_Address__r.Street__c);
    System.assertEquals(quoteRecord.Shipping_Address__r.State__r.Name, quote.Shipping_Address__r.State__r.Name);
    System.assertEquals(quoteRecord.Shipping_Address__r.City__c, quote.Shipping_Address__r.City__c);
    System.assertEquals(quoteRecord.Shipping_Address__r.Zip_Postal_Code__c, quote.Shipping_Address__r.Zip_Postal_Code__c);
    System.assertEquals(quoteRecord.Shipping_Address__r.Country__r.Name, quote.Shipping_Address__r.Country__r.Name);
    System.assertEquals(quoteRecord.Billing_Address__r.Account__r.Name, quote.Billing_Address__r.Account__r.Name);
    System.assertEquals(quoteRecord.Billing_Address__r.Account__r.Bill_To_Email__c, quote.Billing_Address__r.Account__r.Bill_To_Email__c);
  }

  @isTest static void test_shouldGetFalseRenewalCheck() {
    //get Quote
    SBQQ__Quote__c quote = [SELECT
                            Id
                            FROM SBQQ__Quote__c
                            LIMIT 1
                            ];
    
    Boolean preCheck = RenewalCheckoutHelper.renewalPreCheck(quote.Id);
    System.assertEquals(false, preCheck);
  }

  @isTest static void test_shouldGetTrueRenewalCheck() {
    //get Quote
    SBQQ__Quote__c quote = [SELECT
                            Id
                            FROM SBQQ__Quote__c
                            LIMIT 1
                            ];
    SBQQ.TriggerControl.disable();
    quote.SBQQ__Status__c = 'Approved';
    quote.ApprovalStatus__c = 'Approved';
    update quote;
    SBQQ.TriggerControl.enable();
    
    Boolean preCheck = RenewalCheckoutHelper.renewalPreCheck(quote.Id);
    System.assertEquals(true, preCheck);
  }

  @isTest static void test_shouldGetTrueRenewalCheckAndUpdateOpp() {
    //get Quote
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    
    opp.Shipping_Address__c = null;
    opp.Billing_Address__c = null;
    update opp;

    SBQQ.TriggerControl.disable();
    quote.SBQQ__Status__c = 'Approved';
    quote.ApprovalStatus__c = 'Approved';
    quote.Shipping_Address__c = null;
    quote.Billing_Address__c = null;
    update quote;

    SBQQ.TriggerControl.enable();
    
    quote = [SELECT Id, Shipping_Address__c, Billing_Address__c  FROM SBQQ__Quote__c LIMIT 1];

    Boolean preCheck = RenewalCheckoutHelper.renewalPreCheck(quote.Id);
    System.assertEquals(true, preCheck);

    opp = [SELECT Id, Shipping_Address__c FROM Opportunity LIMIT 1];

    System.assert(opp.Shipping_Address__c != null, 'Shipping Address should be set');
  }

  @isTest static void test_shouldGetCreditCards() {
    Credit_Card__c cc = [SELECT Id FROM Credit_Card__c LIMIT 1];
    User user = [SELECT Id from User WHERE email = 'puser000@barracuda.com'];
    System.runAs(user) {
      List<Credit_Card__c> actualCC = RenewalCheckoutHelper.getCreditCards();
      System.assertEquals(cc.Id, actualCC[0].Id);
    }
  }

  @isTest static void test_isValidPONmber() {
    Opportunity opp = [SELECT Id, PurchaseOrderID__c FROM Opportunity LIMIT 1];
    
    Account account = [SELECT Id FROM Account LIMIT 1];
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
    opp.SBQQ__PrimaryQuote__c = quote.Id;
    opp.AccountId = account.Id;
    opp.Bill_To_Account__c = account.Id;
    SBQQ.TriggerControl.disable();
    update opp;
    SBQQ.TriggerControl.enable();

    Boolean isValidPOTrue = RenewalCheckoutHelper.validPONumber(opp.PurchaseOrderID__c, account.Id, quote.Id);

    System.assertEquals(true, isValidPOTrue);
  }
}