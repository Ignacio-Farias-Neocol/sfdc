@isTest
public with sharing class QuoteListViewHelperTest {
    
    @testSetup static void setup() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        
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
        
        Contact rec = new Contact();
        rec.LastName = 'Test';
        rec.FirstName = 'TEst';
        rec.Email = 'test.test@test.com';
        rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        rec.AccountId = customer.Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';
        INSERT rec;
                
        //Opportunity
        Opportunity oppt = new Opportunity();
        oppt.Name ='Oppty 001';
        oppt.AccountID = customer.Id;
        oppt.Bill_To_Account__c = customer.Id;
        oppt.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt.Model_Series__c = 'API';
        oppt.StageName = 'Accepted';
        oppt.Amount = 3000;
        oppt.CloseDate = System.today();
        oppt.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        oppt.Bypass_Validation__c = true;
        oppt.Is_Unit_Test__c = true;
        oppt.LeadSource = 'Renewal';
        oppt.BypassBusinessGroupValidation__c = True;
        INSERT oppt;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Opportunity2__c = oppt.Id; 
        testQuote.SBQQ__Primary__c = true;
        testQuote.SBQQ__Status__c = 'Approved';
        testQuote.SBQQ__Type__c ='Renewal';
        testQuote.Original_Contract_End_Date__c=System.today();
        testQuote.Available_on_Portal__c = true;
        insert testQuote;
        
        SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c();
        qli.SBQQ__StartDate__c = System.today()-10;
        qli.SBQQ__EndDate__c = System.today()+10;
        qli.SBQQ__Quote__c = testQuote.Id;
        qli.SBCF_Serial_Number__c = 'SERIAL001';
        SBQQ.TriggerControl.disable();
        insert qli;
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();      

    } 
    
    @isTest static void test_getQuotesAccount() {
        Account acc = [Select Id from Account limit 1];
        SBQQ__Quote__c quote = [SELECT Id,Name,SBQQ__Status__c,SBQQ__Type__c,Original_Contract_End_Date__c, 
                                (SELECT Id,SBQQ__StartDate__c,SBQQ__EndDate__c,Extended_Published_List_Price__c,SBCF_Serial_Number__c FROM SBQQ__LineItems__r) FROM SBQQ__Quote__c];
        quote.Original_Contract_End_Date__c = System.today()+30;
        update quote;
        Test.startTest();
        Date today = System.today() + 30;
		String fromDate = today.year() + '-' + String.valueOf(today.month()).leftPad(2, '0') + '-' + String.valueOf(today.day()).leftPad(2, '0');
		String toDate = today.year() + '-' + String.valueOf(today.month()).leftPad(2, '0') + '-' + String.valueOf(today.day()).leftPad(2, '0');
        List<SBQQ__Quote__c> listOfQuote = QuoteListViewHelper.getQuotes(acc.Id, 'Customer', fromDate, toDate);
        System.assert(listOfQuote!=null);
        System.assert(listOfQuote!=null && listOfQuote.size() == 1);
        System.assertEquals(listOfQuote[0].SBQQ__Status__c,quote.SBQQ__Status__c);
        Test.stopTest();
    }

}