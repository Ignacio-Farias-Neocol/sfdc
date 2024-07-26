@isTest
public with sharing class QuoteEditorFooterHelperTest {
    
    @testSetup static void setup() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
        SBQQ.TriggerControl.disable();
        Product2 testProd = TestDataFactory.products[0];
        testProd.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testProd.SBQQ__SubscriptionTerm__c = 1;
        update testProd;

        Account testAccount = TestDataFactory.customers[0];
        Contact testContact = TestDataFactory.customerContacts[0];
        List<Address__c> addresses = [SELECT Id, Type__c FROM Address__c WHERE Account__c = :testAccount.Id];

        Address__c billingAddress;
        Address__c shippingAddress;
        for(Address__c addy : addresses) {
            if(addy.Type__c == 'Billing') {
                billingAddress = addy;
            } else if(addy.Type__c == 'Shipping') {
                shippingAddress = addy;
            }
        }

        testAccount.SBQQ__RenewalPricingMethod__c = 'Same';
        testAccount.Bill_To_Email__c = testContact.Email;
        testAccount.Bill_To_Contact__c = testContact.FirstName;
        testAccount.Ship_To_Email__c = testContact.Email;
        testAccount.Ship_To_Contact__c = testContact.FirstName;
        update testAccount;
        
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
        testOpp.Billing_Address__c = billingAddress.Id;
        testOpp.Ship_To_Account__c = testAccount.Id;
        testOpp.Shipping_Address__c = shippingAddress.Id;
        update testOpp;        

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Renewal');
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

    @isTest
    static void itShouldApproveQuote(){
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        QuoteEditorFooterHelper.approveQuote(quote.Id);

        quote = [SELECT Id, ApprovalStatus__c FROM SBQQ__Quote__c LIMIT 1];

        System.assertEquals('Approved', quote.ApprovalStatus__c, 'Quote should be Approved');
    }

}