@isTest
public with sharing class RenewalCheckoutQuoteOrderedQueueableTest {
    
    @testSetup static void setup() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
        SBQQ.TriggerControl.disable();
        Product2 testProd = TestDataFactory.products[0];
        testProd.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testProd.SBQQ__SubscriptionTerm__c = 1;
        update testProd;

        Contact testContact = TestDataFactory.customerContacts[0];
        testContact.MailingCountryCode = 'US';
        update testContact;

        Account testAccount = TestDataFactory.customers[0];
        testAccount.SBQQ__RenewalPricingMethod__c = 'Same';
        testAccount.Bill_To_Email__c = testContact.Email;
        testAccount.Bill_To_Contact__c = testContact.FirstName;
        testAccount.Ship_To_Email__c = testContact.Email;
        testAccount.Ship_To_Contact__c = testContact.FirstName;
        update testAccount;

        Account distiAccount = TestDataFactory.partnersDistributor[0];
        distiAccount.Bill_To_Email__c = 'billing@test.com';
        distiAccount.Bill_To_Contact__c = 'Billing Contact';

        update distiAccount;
        
        System.debug('##testAccount:: ' + JSON.serialize(testAccount));

        Contract testContract = new Contract(AccountId = testAccount.Id, 
            Business_Group__c = 'Core', 
            SBQQ__RenewalPricebookId__c = '01sf2000003FSkFAAW', 
            SBQQ__RenewalOpportunityRecordTypeId__c = '012f2000001261kAAA', 
            SBQQ__RenewalOpportunityStage__c = 'Not Contacted', 
            StartDate = System.Today() - 720, ContractTerm = 12);
        insert testContract;
        testContract.Status = 'Activated';
        update testContract;

        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today() - 720); 
        insert testSub;

        Opportunity testOpp = TestDataFactory.opportunities[0];
        testOpp.RecordTypeID = '012f2000001261kAAA';
        testOpp.Business_Group__c = 'Core';
        testOpp.CloseDate = System.Today();
        testOpp.SBQQ__RenewedContract__c = testContract.Id;
        testOpp.SBQQ__Renewal__c = true;
        testOpp.Contract_Error_Check__c = '123';
        testOpp.Bill_To_Account__c = testAccount.Id;
        testOpp.Type = 'Existing Business';
        update testOpp;        

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Renewal');
        testQuote.ApprovalStatus__c = 'Approved';
        testQuote.SBQQ__Status__c = 'Approved';
        testQuote.Has_Contract_Error__c = FALSE;
        testQuote.SBQQ__PricebookId__c = TestDataFactory.priceBookId;
        insert testQuote;

        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuote.Id, SBQQ__RenewedSubscription__c = testSub.Id, SBQQ__EndDate__c = System.Today() + 1, SBCF_Form_Factor__c = 'SaaS', SBQQ__DefaultSubscriptionTerm__c = 1, SBQQ__PricebookEntryId__c = TestDataFactory.priceBookEntry[0].Id);
        insert testQuoteLine;

        testOpp.SBQQ__PrimaryQuote__c = testQuote.Id;
        update testOpp;

        testContract.SBQQ__RenewalOpportunity__c = testOpp.Id;
        update testContract;
        
        TriggerHandler.clearAllBypasses();   
        SBQQ.TriggerControl.enable();
    }

    @isTest static void test_shouldQueueJob() {

        SBQQ__Quote__c quote =  [
                                SELECT
                                Id
                                FROM SBQQ__Quote__c
                                LIMIT 1
                                ];
        
        RenewalCheckoutQuoteOrderedQueueable testQueue = new RenewalCheckoutQuoteOrderedQueueable(quote.Id, null, '123', true);
        Id jobId = System.enqueueJob(testQueue);
        AsyncApexJob jobInfo = [SELECT Status FROM AsyncApexJob WHERE Id = :jobId];

        System.assert(jobInfo != null);
    }

    @isTest static void test_shouldPlaceOrder() {
        //Retrive inserted Quote
        SBQQ__Quote__c quote =  [
                                SELECT
                                Id
                                FROM SBQQ__Quote__c
                                LIMIT 1
                                ];

        RenewalCheckoutQuoteOrderedQueueable testQueue = new RenewalCheckoutQuoteOrderedQueueable(quote.Id, null, '123', true);
        testQueue.quoteOrdered();

        Opportunity opp = [
                        SELECT
                        Id,
                        stageName
                        FROM Opportunity
                        LIMIT 1
                        ];

        System.assertEquals('Closed Won', opp.stageName);
    }

}