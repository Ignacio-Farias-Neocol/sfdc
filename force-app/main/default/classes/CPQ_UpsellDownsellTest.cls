/**
* @author        salesforce services
* @date          2020-07-08
* @description   Unit Test class for Serial Move related classes
- CPQ_QLUpdateRenewal
- CPQ_QLUpdateAmendment
- CPQ_UpsellDownsell
* @group         Test
*
*/
@isTest
public with sharing class CPQ_UpsellDownsellTest {
    @testSetup
    static void setup() {
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
        SBQQ.TriggerControl.disable();
        
        String accountProductCode;
        String bundleProductCode;
        
        //Get the products eligible for upsell downsell
        for(Upsell_Downsell_Settings__mdt setting: [SELECT DeveloperName,
                                                    Settings_Value__c 
                                                    FROM Upsell_Downsell_Settings__mdt 
                                                    WHERE DeveloperName in ('Account_Products','Level1_Bundle')]){
                                                        
                                                        //Populate product codes
                                                        if(String.isNotBlank(setting.Settings_Value__c)){
                                                            switch on setting.DeveloperName {
                                                                when 'Account_Products' {
                                                                    accountProductCode = setting.Settings_Value__c.split(',')[0];
                                                                }	
                                                                when 'Level1_Bundle' {
                                                                    bundleProductCode = setting.Settings_Value__c.split(',')[0]; 
                                                                }
                                                                when else {
                                                                    //Do Nothing
                                                                }
                                                            }
                                                        }
                                                    }
        
        //Product list
        List<Product2> prodList = new List<Product2>();
        
        //Create Account Product
        Product2 testAccountProduct                  = new Product2();
        testAccountProduct.Name                      = 'Account Product';
        testAccountProduct.Base_SKU__c               = accountProductCode;
        testAccountProduct.ProductCode               = accountProductCode; 
        prodList.add(testAccountProduct);
        
        //Create a Bundle Parent product
        Product2 testBundleParentProduct1             = new Product2();
        testBundleParentProduct1.Name                 = 'Bundle Parent 1';
        testBundleParentProduct1.Base_SKU__c          = bundleProductCode;
        testBundleParentProduct1.ProductCode          = bundleProductCode;
        prodList.add(testBundleParentProduct1);
        
        //Create a Bundle Parent product
        Product2 testBundleParentProduct2             = new Product2();
        testBundleParentProduct2.Name                 = 'Bundle Parent 2';
        testBundleParentProduct2.Base_SKU__c          = 'Bundle_Parent2';
        testBundleParentProduct2.ProductCode          = 'Bundle_Parent2';
        prodList.add(testBundleParentProduct2);
        
        //Create a Bundle Item product
        Product2 testBundleItemProduct1             = new Product2();
        testBundleItemProduct1.Name                 = 'Bundle Item1';
        testBundleItemProduct1.Base_SKU__c          = 'Bundle_Item1';
        testBundleItemProduct1.ProductCode          = 'Bundle_Item1';
        testBundleItemProduct1.SBQQ__Component__c   = true;
        prodList.add(testBundleItemProduct1);
        
        //Create a Bundle Item product
        Product2 testBundleItemProduct2             = new Product2();
        testBundleItemProduct2.Name                 = 'Bundle Item2';
        testBundleItemProduct2.Base_SKU__c          = 'Bundle_Item2';
        testBundleItemProduct2.ProductCode          = 'Bundle_Item2';
        testBundleItemProduct2.SBQQ__Component__c   = true;
        prodList.add(testBundleItemProduct2);    
        
        insert prodList;
        
        //Create a pricebook
        Pricebook2 pb = new Pricebook2(Name = 'Test PB', Description = 'Test Pricebook', IsActive = true );
        insert pb;
        
        //pricebookentry list
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        for(Product2 prod: prodList){
            //Create the standard PricebookEntry
            PricebookEntry stdPBE = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),
                                                       Product2Id = prod.Id,
                                                       UnitPrice = 100,
                                                       IsActive = true
                                                      );
            pbeList.add(stdPBE);
            
            //Create the custom PricebookEntry
            /*PricebookEntry customPBE = new PricebookEntry(Pricebook2Id = pb.Id,
Product2Id = prod.Id,
UnitPrice = 100,
IsActive = true
);    
pbeList.add(customPBE);  */
        }
        
        insert pbeList;
        
        //Update Account Information
        Account customerAccount = TestDataFactory.customers[0];
        
        //User usr = TestDataFactory.createUser('System Administrator');
        
        User usr = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'puser000@barracuda.com', // required domain for user barracuda.com, barracudamsp.com
            Username = 'puser000@barracuda.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Business_Group__c = 'MSP'
        );
        insert usr;
        User singleUser = [Select ID from User where Email = 'puser000@barracuda.com' LIMIT 1];
        
        System.runAs(singleUser) {
            
            //Opportunity
            Opportunity testOpp = TestDataFactory.createEmptyOpportunity(customerAccount);
            
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
            
            //Quote
            SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, 
                                                          SBQQ__Primary__c      = true,
                                                          SBQQ__StartDate__c = Date.today(),
                                                          SBQQ__PricebookId__c = pb.id);
            insert testQuote;
            
            //Contract
            Contract testContract = new Contract(AccountId = customerAccount.Id, 
                                                 Business_Group__c    = 'MSP', 
                                                 StartDate            = System.today(),
                                                 SBQQ__RenewalTerm__c = 12);
            
            insert testContract;
            
            testOpp.SBQQ__RenewedContract__c = testContract.Id;
            update testOpp;
            
            //Asset
            Asset testAsset = new Asset(AccountId    = customerAccount.Id, 
                                        Name        = 'test asset', 
                                        Product2Id  = testAccountProduct.Id,
                                        Contract__c = testContract.Id); 
            
            insert testAsset;
            
            //Subscription
            SBQQ__Subscription__c testSub1 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                                       Current_Quantity__c            = 1,
                                                                       SBQQ__Contract__c              = testContract.Id, 
                                                                       SBQQ__SubscriptionStartDate__c = System.today(),
                                                                       SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                                       SBQQ__Product__c               = testBundleParentProduct1.Id,
                                                                       SBQQ__Account__c               = customerAccount.Id,
                                                                       SBQQ__OptionLevel__c           = 1);
            
            SBQQ__Subscription__c testSub2 = new SBQQ__Subscription__c(SBQQ__Quantity__c                = 1, 
                                                                       Current_Quantity__c              = 1,
                                                                       SBQQ__Contract__c                = testContract.Id, 
                                                                       SBQQ__SubscriptionStartDate__c   = System.today(),
                                                                       SBQQ__SubscriptionEndDate__c     = System.today().addDays(90),
                                                                       SBQQ__Product__c                 = testBundleItemProduct1.Id,
                                                                       SBQQ__Account__c                 = customerAccount.Id,
                                                                       SBQQ__OptionLevel__c             = 2,
                                                                       SBQQ__RequiredByProduct__c = testBundleParentProduct1.Id);                                                               
            
            List<SBQQ__Subscription__c> subs = new List<SBQQ__Subscription__c>{testSub1, testSub2}; 
                
                insert subs;
            
            SBQQ__QuoteLine__c newAccountQL = new SBQQ__QuoteLine__c();
            newAccountQL.SBQQ__Quantity__c            = 1;
            newAccountQL.SBQQ__RenewedAsset__c        = testAsset.Id; 
            newAccountQL.SBQQ__Quote__c               = testQuote.Id;
            newAccountQL.SBQQ__StartDate__c           = Date.today();
            newAccountQL.SBQQ__Existing__c            = true;
            newAccountQL.SBQQ__Number__c              = 4000;
            newAccountQL.SBQQ__Product__c             = testAccountProduct.Id;
            
            // SBQQ__QuoteLine__c newBundleQL = new SBQQ__QuoteLine__c();
            // newBundleQL.SBQQ__Quantity__c            = 1;
            // newBundleQL.SBQQ__RenewedSubscription__c = testSub2.id;    
            // newBundleQL.SBQQ__Quote__c               = testQuote.Id;
            // newBundleQL.SBQQ__StartDate__c           = Date.today();
            // newBundleQL.SBQQ__Existing__c            = true;
            // newBundleQL.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            // newBundleQL.SBQQ__Number__c              = 4000;
            // newBundleQL.SBQQ__Product__c             = testBundleParentProduct1.Id;
            
            // SBQQ__QuoteLine__c newBundleItemQL = new SBQQ__QuoteLine__c();
            // newBundleItemQL.SBQQ__Quantity__c            = 1;
            // newBundleItemQL.SBQQ__RenewedSubscription__c = testSub1.id;    
            // newBundleItemQL.SBQQ__Quote__c               = testQuote.Id;
            // newBundleItemQL.SBQQ__StartDate__c           = Date.today();
            // newBundleItemQL.SBQQ__Existing__c            = true;
            // newBundleItemQL.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            // newBundleItemQL.SBQQ__Number__c              = 4000;
            // newBundleItemQL.SBQQ__Product__c             = testBundleItemProduct1.Id;
            
            insert new List<SBQQ__QuoteLine__c> {newAccountQL};
                }
        //Enable trigger
        SBQQ.TriggerControl.enable();  
        TriggerHandler.clearAllBypasses();  
    }
    
    @isTest static void test_Renewal() {  
        //Get Quote
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        //Get product Ids
        Id testBundleParentProduct2;
        Id testBundleItemProduct2;
        for(Product2 prod: [SELECT Id, ProductCode FROM Product2 WHERE ProductCode in ('Bundle_Parent2', 'Bundle_Item2')]){
            if(prod.ProductCode == 'Bundle_Parent2'){
                testBundleParentProduct2 = prod.Id;
            }
            else{
                testBundleItemProduct2 = prod.Id;
            }
        }
        
        SBQQ__QuoteLine__c newBundleQL = new SBQQ__QuoteLine__c();
        newBundleQL.SBQQ__Quantity__c            = 1;    
        newBundleQL.SBQQ__Quote__c               = testQuote.Id;
        newBundleQL.SBQQ__StartDate__c           = Date.today();
        newBundleQL.SBQQ__Existing__c            = true;
        newBundleQL.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        newBundleQL.SBQQ__Number__c              = 4001;
        newBundleQL.SBQQ__Product__c             = testBundleParentProduct2;
        
        SBQQ__QuoteLine__c newBundleItemQL = new SBQQ__QuoteLine__c();
        newBundleItemQL.SBQQ__Quantity__c            = 1;  
        newBundleItemQL.SBQQ__Quote__c               = testQuote.Id;
        newBundleItemQL.SBQQ__StartDate__c           = Date.today();
        newBundleItemQL.SBQQ__Existing__c            = true;
        newBundleItemQL.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        newBundleItemQL.SBQQ__Number__c              = 4002;
        newBundleItemQL.SBQQ__Product__c             = testBundleItemProduct2;
        
        insert new List<SBQQ__QuoteLine__c> {newBundleQL, newBundleItemQL};
            Test.startTest();
        CPQ_QLUpdateRenewal.updateQL(new List<Id>{testQuote.Id});
        Test.stopTest();
        List<SBQQ__QuoteLine__c> qlList = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :testQuote.Id];
        System.assert(qlList!=null && !qlList.isEmpty());
        System.assertEquals(5, qlList.size());
        
    }
    
    @isTest static void test_Amendment() {  
        //Get Quote
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        //Get product Ids
        Id testBundleParentProduct2;
        Id testBundleItemProduct2;
        for(Product2 prod: [SELECT Id, ProductCode FROM Product2 WHERE ProductCode in ('Bundle_Parent2', 'Bundle_Item2')]){
            if(prod.ProductCode == 'Bundle_Parent2'){
                testBundleParentProduct2 = prod.Id;
            }
            else{
                testBundleItemProduct2 = prod.Id;
            }
        }
        
        SBQQ__QuoteLine__c newBundleQL = new SBQQ__QuoteLine__c();
        newBundleQL.SBQQ__Quantity__c            = 1;    
        newBundleQL.SBQQ__Quote__c               = testQuote.Id;
        newBundleQL.SBQQ__StartDate__c           = Date.today();
        newBundleQL.SBQQ__Existing__c            = true;
        newBundleQL.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        newBundleQL.SBQQ__Number__c              = 4001;
        newBundleQL.SBQQ__Product__c             = testBundleParentProduct2;
        
        SBQQ__QuoteLine__c newBundleItemQL = new SBQQ__QuoteLine__c();
        newBundleItemQL.SBQQ__Quantity__c            = 1;  
        newBundleItemQL.SBQQ__Quote__c               = testQuote.Id;
        newBundleItemQL.SBQQ__StartDate__c           = Date.today();
        newBundleItemQL.SBQQ__Existing__c            = true;
        newBundleItemQL.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        newBundleItemQL.SBQQ__Number__c              = 4002;
        newBundleItemQL.SBQQ__Product__c             = testBundleItemProduct2;
        
        insert new List<SBQQ__QuoteLine__c> {newBundleQL, newBundleItemQL};
            
            Test.startTest();
        CPQ_QLUpdateAmendment.updateQL(new List<Id>{testQuote.Id});
        Test.stopTest();
        List<SBQQ__QuoteLine__c> qlList = [SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :testQuote.Id];
        System.assert(qlList!=null && !qlList.isEmpty());
        System.assertEquals(3, qlList.size());
        
    }
    
}