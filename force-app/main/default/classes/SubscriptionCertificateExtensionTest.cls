@isTest
public with sharing class SubscriptionCertificateExtensionTest {
    @testSetup static void setup() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
    
        //Product
        Product2 testProd = TestDataFactory.products[0];
        testProd.Base_SKU__c  = 'TEST_SKU';
        testProd.ProductCode  = 'TEST_SKU';
        update testProd;
    
        //Opportunity
        Opportunity testOpp = TestDataFactory.createOpportunity(TestDataFactory.customers[0]);
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
                                      WHERE Account__c = :TestDataFactory.customers[0].Id ]){
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
        Order testOrder              = new Order();
        testOrder.AccountId          = TestDataFactory.customers[0].Id;
        testOrder.EffectiveDate      = Date.today();
        testOrder.Pricebook2Id       = TestDataFactory.priceBookId;
        testOrder.description        = 'Test Order';
        testOrder.Status             = 'Draft';
        testOrder.Type               = 'New'; // new order
        testOrder.Active_Contract__c = testContract.Id;
        testOrder.OpportunityId      = testOpp.Id;
    
        insert testOrder;
    
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
                                                                  SBQQ__SubscriptionStartDate__c = System.today(),
                                                                  SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                                  SBQQ__Product__c               = testProd.Id,
                                                                  SBQQ__Account__c = TestDataFactory.customers[0].Id); 
    
        SBQQ__Subscription__c testSub4 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                                  SBQQ__Contract__c              = testContract.Id, 
                                                                  SBQQ__SubscriptionStartDate__c = System.today().addDays(-90),
                                                                  SBQQ__SubscriptionEndDate__c   = System.today().addDays(-80),
                                                                  SBQQ__Product__c               = testProd.Id,
                                                                  SBQQ__Account__c = TestDataFactory.customers[0].Id); 

        SBQQ__Subscription__c testSub5 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                                  SBQQ__Contract__c              = testContract.Id, 
                                                                  SBQQ__SubscriptionStartDate__c = System.today(),
                                                                  SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                                  SBQQ__Product__c               = testProd.Id,
                                                                  SBQQ__Account__c = TestDataFactory.customers[0].Id); 
    
        SBQQ__Subscription__c testSub6 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                                  SBQQ__Contract__c              = testContract.Id, 
                                                                  SBQQ__SubscriptionStartDate__c = System.today().addDays(-90),
                                                                  SBQQ__SubscriptionEndDate__c   = System.today().addDays(-80),
                                                                  SBQQ__Product__c               = testProd.Id,
                                                                  SBQQ__Account__c = TestDataFactory.customers[0].Id); 

        SBQQ__Subscription__c testSub7 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                                  SBQQ__Contract__c              = testContract.Id, 
                                                                  SBQQ__SubscriptionStartDate__c = System.today(),
                                                                  SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                                  SBQQ__Product__c               = testProd.Id,
                                                                  SBQQ__Account__c = TestDataFactory.customers[0].Id); 
    
        SBQQ__Subscription__c testSub8 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                                  SBQQ__Contract__c              = testContract.Id, 
                                                                  SBQQ__SubscriptionStartDate__c = System.today().addDays(-90),
                                                                  SBQQ__SubscriptionEndDate__c   = System.today().addDays(-80),
                                                                  SBQQ__Product__c               = testProd.Id,
                                                                  SBQQ__Account__c = TestDataFactory.customers[0].Id);                                                                   
                                                                  
        List<SBQQ__Subscription__c> subs = new List<SBQQ__Subscription__c>{testSub1, 
                                                                           testSub2, 
                                                                           testSub3, 
                                                                           testSub4, 
                                                                           testSub5, 
                                                                           testSub6, 
                                                                           testSub7, 
                                                                           testSub8};
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
    
        Assigned_Serial__c testAssigned4 = new Assigned_Serial__c(Serial__c        = testSerial.Id, 
                                                                  Subscription__c = subs[3].Id); 

        Assigned_Serial__c testAssigned5 = new Assigned_Serial__c(Serial__c        = testSerial.Id, 
                                                                  Subscription__c = subs[4].Id);
    
        Assigned_Serial__c testAssigned6 = new Assigned_Serial__c(Serial__c        = testSerial.Id, 
                                                                  Subscription__c = subs[5].Id);      
                                                                  
        Assigned_Serial__c testAssigned7 = new Assigned_Serial__c(Serial__c        = testSerial.Id, 
                                                                  Subscription__c = subs[6].Id);
    
        Assigned_Serial__c testAssigned8 = new Assigned_Serial__c(Serial__c        = testSerial.Id, 
                                                                  Subscription__c = subs[7].Id);                                                                                                                                       
        insert new List<Assigned_Serial__c>{testAssigned1, 
                                            testAssigned2, 
                                            testAssigned3,
                                            testAssigned4,
                                            testAssigned5,
                                            testAssigned6,
                                            testAssigned7,
                                            testAssigned8};
        TriggerHandler.clearAllBypasses();      
    
      } 
      
      @isTest static void test_shouldGetSubs() {

        //get the account
        Account acc = [Select Id from Account limit 1];

        //Get the serial
        Serial__c serial = [Select Id from Serial__c limit 1];
    
        List<Sub_Cert_Settings__mdt> certSettings = [SELECT First_Page_Lines__c,
                                                            Subsequent_Page_Lines__c
                                                    FROM Sub_Cert_Settings__mdt 
                                                    WHERE DeveloperName='Default'];

        PageReference pageRef = Page.SubscriptionCertificate;
        Test.setCurrentPage(pageRef);

        pageRef.getParameters().put('Id', serial.Id);
        // pageRef.getParameters().put('aId', acc.Id);
        // pageRef.getParameters().put('productName', 'Test Product Name');
        pageRef.getParameters().put('partner', 'test partner');
        pageRef.getParameters().put('accountType', 'Reseller');
        ApexPages.StandardController sc = new ApexPages.StandardController(serial);
        SubscriptionCertificateExtension serialExtension = new SubscriptionCertificateExtension(sc);
        Test.startTest();
        List<SubscriptionCertificateExtension.SubscriptionWrapper[]> subArray = serialExtension.getSubsArray();
        Integer firstBreak = serialExtension.getFirstBreak();
        Integer subBreak = serialExtension.getSubseqBreak();
        Test.stopTest();
   
        //Serial Assertion
        System.assert(subArray!=null && subArray.size()==2);
        System.assert(subArray[0]!=null && subArray[0].size() == 6);
        System.assert(subArray[1]!=null && subArray[1].size() == 2);
        System.assertEquals((Integer)certSettings[0].First_Page_Lines__c, firstBreak);
        System.assertEquals((Integer)certSettings[0].Subsequent_Page_Lines__c, subBreak);
        System.assertEquals('Distributor', serialExtension.getPartnerLabel());
        
      }      
}