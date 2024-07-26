@IsTest
private class CPQQuoteLineCategorizationTest {
    @testSetup static void setup() {
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');// among other things, keep the contact status as active
        
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            SBCF_Product_Segment__c = 'Test Segment',
            ProductCode = 'TestCode',
            Family = 'Test Family');
        
        Account acc = new Account();
        acc.Name = 'TESH ACC';
        acc.Type = 'Partner - MSP';
        acc.Bill_To_Contact__c='test';
        acc.Bill_To_Email__c='Test@gmail.com';
        insert acc;
        
        List<Account> acc1=new List<Account>();
        acc1.add(acc);
        update acc1;
        List <Opportunity> opportunities = TestDataFactory.opportunities;
        TriggerHandler.clearAllBypasses();
        opportunities[0].Bill_To_Account__c = acc1[0].Id;
        opportunities[0].Business_Group__c='Core';
        update opportunities[0];
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opportunities[0].Id, SBQQ__Primary__c = true);
        insert testQuote;
        
        Contract testContract = new Contract(
            AccountId = acc1[0].Id,
            EndDate = System.today().addMonths(2)
        );
        insert testContract;
        
        
    }
    
    @IsTest
    static  void unitTestOther() {
        Product2 testProd = new Product2(
            Name = 'Test Product',
            SBCF_Product_Segment__c = 'other',
            ProductCode = 'TestCode',
            Family = 'Test Family');
        Insert testProd;
        
        SBQQ__Quote__c testQuote = [Select ID, SBQQ__PaymentTerms__c, ApprovalStatus__c, SBQQ__Status__c, SBQQ__Opportunity2__c From SBQQ__Quote__c][0];
        
        Account testAccount = [Select ID From Account][0];
        Opportunity testOpp = [Select ID From Opportunity][0];
        
        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, EndDate = System.today().addMonths(-36) );
        insert testContract;
        
        List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Account__c=testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
                new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
                new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36))
                }; 
                    insert testSubs;
        testSubs[0].Renewed_By_Subscription__c = testSubs[1].Id;
        update testSubs[0];
        
        List<SBQQ__QuoteLine__c> testQuoteLines = new List<SBQQ__QuoteLine__c> {
            new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2,Business_Group__c='Core', SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 0, SBQQ__RenewedSubscription__c = testSubs[0].Id)
                };
                    insert testQuoteLines;
         TriggerHandler.clearAllBypasses();   
        Test.startTest();
        CPQQuoteLineCategorization.getQuote(new List<ID> {testQuote.Id});
        Test.stopTest();
         TriggerHandler.clearAllBypasses();   
        
    }   
    @IsTest
    static  void unitTestProfessionalservice() {
        Product2 testProd = new Product2(
            Name = 'Test Product',
            SBCF_Product_Segment__c = 'Professional Services',
            ProductCode = 'TestCode',
            Family = 'Test Family');
        Insert testProd;
        
        SBQQ__Quote__c testQuote = [Select ID, SBQQ__PaymentTerms__c, ApprovalStatus__c, SBQQ__Status__c, SBQQ__Opportunity2__c From SBQQ__Quote__c][0];
        Account testAccount = [Select ID From Account][0];
        Opportunity testOpp = [Select ID From Opportunity][0];
        
        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, EndDate = System.today().addMonths(-36) );
        insert testContract;
        
        List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Account__c=testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
                new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
                new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36))
                }; 
                    insert testSubs;
        testSubs[0].Renewed_By_Subscription__c = testSubs[1].Id;
        update testSubs[0];
        
        List<SBQQ__QuoteLine__c> testQuoteLines = new List<SBQQ__QuoteLine__c> {
            new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2,Business_Group__c='Core', SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 0, SBQQ__RenewedSubscription__c = testSubs[0].Id)
                };
                    insert testQuoteLines;
         TriggerHandler.clearAllBypasses();   
        Test.startTest();
        CPQQuoteLineCategorization.getQuote(new List<ID> {testQuote.Id});
        Test.stopTest();
         TriggerHandler.clearAllBypasses();   
    }
    @IsTest
    static  void unitTestNetTotal() {
        Product2 testProd = TestDataFactory.products[0];
        
        SBQQ__Quote__c testQuote = [Select ID, SBQQ__PaymentTerms__c, ApprovalStatus__c, SBQQ__Status__c, SBQQ__Opportunity2__c From SBQQ__Quote__c][0];
        Account testAccount = [Select ID From Account][0];
        Opportunity testOpp = [Select ID From Opportunity][0];
        
        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, EndDate = System.today().addMonths(-36) );
        insert testContract;
        
        /* List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Account__c=testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36))
}; 
insert testSubs;
testSubs[0].Renewed_By_Subscription__c = testSubs[1].Id;
update testSubs[0];*/
        
        List<SBQQ__QuoteLine__c> testQuoteLines = new List<SBQQ__QuoteLine__c> {
            new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2,Business_Group__c='Core', SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 0)
                };
                    insert testQuoteLines;
         TriggerHandler.clearAllBypasses();   
        Test.startTest();
        CPQQuoteLineCategorization.getQuote(new List<ID> {testQuote.Id});
        Test.stopTest();
         TriggerHandler.clearAllBypasses();   
    }
    @IsTest
    static  void unitTestNetNew() {
        Product2 testProd = TestDataFactory.products[0];
        
        SBQQ__Quote__c testQuote = [Select ID, SBQQ__PaymentTerms__c, ApprovalStatus__c, SBQQ__Status__c, SBQQ__Opportunity2__c From SBQQ__Quote__c][0];
        Account testAccount = [Select ID From Account][0];
        Opportunity testOpp = [Select ID From Opportunity][0];
        
        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, EndDate = System.today().addMonths(-36) );
        insert testContract;
        
        /* List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Account__c=testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36))
}; 
insert testSubs;
testSubs[0].Renewed_By_Subscription__c = testSubs[1].Id;
update testSubs[0];*/
        
        List<SBQQ__QuoteLine__c> testQuoteLines = new List<SBQQ__QuoteLine__c> {
            new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2,Business_Group__c='Core', SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 10)
                };
                    insert testQuoteLines;
        Test.startTest();
        CPQQuoteLineCategorization.getQuote(new List<ID> {testQuote.Id});
        Test.stopTest();
        
    }
      @IsTest
    static  void unitTestRenewaSub() {
        Product2 testProd = new Product2(
            Name = 'Test Product',
            SBCF_Product_Segment__c = 'Data Protection',
            ProductCode = 'TestCode',
            Family = 'Test Family');
        Insert testProd;
        
        SBQQ__Quote__c testQuote = [Select ID, SBQQ__PaymentTerms__c, ApprovalStatus__c, SBQQ__Status__c, SBQQ__Opportunity2__c From SBQQ__Quote__c][0];
        
        Account testAccount = [Select ID From Account][0];
        Opportunity testOpp = [Select ID From Opportunity][0];
        
        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, EndDate = System.today().addMonths(-36) );
        insert testContract;
        
        List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Account__c=testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
                new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
                new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36))
                }; 
                    insert testSubs;
        testSubs[0].Renewed_By_Subscription__c = testSubs[1].Id;
        update testSubs[0];
        
        List<SBQQ__QuoteLine__c> testQuoteLines = new List<SBQQ__QuoteLine__c> {
            new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2,EndUserAccount__c=testAccount.Id,Business_Group__c='Core', SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 10, SBQQ__RenewedSubscription__c = testSubs[0].Id)
                };
                    insert testQuoteLines;
        
         TriggerHandler.clearAllBypasses();   
        Test.startTest();
        CPQQuoteLineCategorization.getQuote(new List<ID> {testQuote.Id});
        Test.stopTest();
         TriggerHandler.clearAllBypasses();   
        
    }
    @IsTest
    static  void unitTestUpsell() {
        Product2 testProd = new Product2(
            Name = 'Test Product',
            SBCF_Product_Segment__c = 'Data Protection',
            ProductCode = 'TestCode',
            Family = 'Test Family');
        Insert testProd;
       // Contact testContact;
        SBQQ__Quote__c testQuote = [Select ID, SBQQ__PaymentTerms__c, ApprovalStatus__c, SBQQ__Status__c, SBQQ__Opportunity2__c From SBQQ__Quote__c][0];
        
        Account testAccount = [Select ID From Account][0];
        Opportunity testOpp = [Select ID From Opportunity][0];
        //testContact=new Contact(LastName='TestContact', AccountId=testAccount.Id);
        //insert testContact;
        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, EndDate = System.today().addMonths(-36) );
        insert testContract;
        
        List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Account__c=testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
                new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
                new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36))
                }; 
                    insert testSubs;
        testSubs[0].Renewed_By_Subscription__c = testSubs[1].Id;
        update testSubs[0];
       //Asset testAsset=new Asset(Name='TestAsset',ContactId=testContact.Id,AccountId=testAccount.Id,Product2Id=testProd.Id);
        //insert testAsset;
        
        List<SBQQ__QuoteLine__c> testQuoteLines = new List<SBQQ__QuoteLine__c> {
            new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2,EndUserAccount__c=testAccount.Id,Business_Group__c='Core', SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 10, SBQQ__UpgradedSubscription__c = testSubs[0].Id )
                };
                    insert testQuoteLines;
         TriggerHandler.clearAllBypasses();   
        Test.startTest();
        CPQQuoteLineCategorization.getQuote(new List<ID> {testQuote.Id});
        Test.stopTest();
         TriggerHandler.clearAllBypasses();   
    }
    @IsTest
    static  void unitTestCrosssell() {
        Product2 testProd = new Product2(
            Name = 'Test Product',
            SBCF_Product_Segment__c = 'Data Protection',
            ProductCode = 'TestCode',
            Family = 'Test Family');
        Insert testProd;
        Product2 testProd2 = new Product2(
            Name = 'Test Product',
            SBCF_Product_Segment__c = 'Web Security',
            ProductCode = 'TestCode',
            Family = 'Test Family');
        Insert testProd2;
       // Contact testContact;
        SBQQ__Quote__c testQuote = [Select ID, SBQQ__PaymentTerms__c, ApprovalStatus__c, SBQQ__Status__c, SBQQ__Opportunity2__c From SBQQ__Quote__c][0];
        
        Account testAccount = [Select ID From Account][0];
        Opportunity testOpp = [Select ID From Opportunity][0];
        //testContact=new Contact(LastName='TestContact', AccountId=testAccount.Id);
        //insert testContact;
        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, EndDate = System.today().addMonths(-36) );
        insert testContract;
        
        List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Account__c=testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
                new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
                new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36))
                }; 
                    insert testSubs;
        testSubs[0].Renewed_By_Subscription__c = testSubs[1].Id;
        update testSubs[0];
       //Asset testAsset=new Asset(Name='TestAsset',ContactId=testContact.Id,AccountId=testAccount.Id,Product2Id=testProd.Id);
        //insert testAsset;
        
        List<SBQQ__QuoteLine__c> testQuoteLines = new List<SBQQ__QuoteLine__c> {
            new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd2.Id, SBQQ__Quantity__c = 2,EndUserAccount__c=testAccount.Id,Business_Group__c='Core', SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 10, SBQQ__UpgradedSubscription__c = testSubs[0].Id )
                };
                    insert testQuoteLines;
         TriggerHandler.clearAllBypasses();   
        Test.startTest();
        CPQQuoteLineCategorization.getQuote(new List<ID> {testQuote.Id});
        Test.stopTest();
         TriggerHandler.clearAllBypasses();   
    }
   /* @IsTest
    static  void unitTestUpgradeSub() {
        Product2 testProd = new Product2(
            Name = 'Test Product',
            SBCF_Product_Segment__c = 'Data Protection',
            ProductCode = 'TestCode',
            Family = 'Test Family');
        Insert testProd;
       // Contact testContact;
        SBQQ__Quote__c testQuote = [Select ID, SBQQ__PaymentTerms__c, ApprovalStatus__c, SBQQ__Status__c, SBQQ__Opportunity2__c From SBQQ__Quote__c][0];
        
        Account testAccount = [Select ID From Account][0];
        Opportunity testOpp = [Select ID From Opportunity][0];
        //testContact=new Contact(LastName='TestContact', AccountId=testAccount.Id);
        //insert testContact;
        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, EndDate = System.today().addMonths(-36) );
        insert testContract;
        
        List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Account__c=testAccount.Id, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
                new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36)),
                new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1,SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionEndDate__c = System.today().addMonths(-36))
                }; 
                    insert testSubs;
        testSubs[0].Renewed_By_Subscription__c = testSubs[1].Id;
        update testSubs[0];
       //Asset testAsset=new Asset(Name='TestAsset',ContactId=testContact.Id,AccountId=testAccount.Id,Product2Id=testProd.Id);
        //insert testAsset;
        
        List<SBQQ__QuoteLine__c> testQuoteLines = new List<SBQQ__QuoteLine__c> {
            new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 0,EndUserAccount__c=testAccount.Id,Business_Group__c='Core', SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = -1, SBQQ__UpgradedSubscription__c = testSubs[0].Id )
                };
                    insert testQuoteLines;
        
        Test.startTest();
        CPQQuoteLineCategorization.getQuote(new List<ID> {testQuote.Id});
        Test.stopTest();
    }*/

    
}