@isTest
public with sharing class QuoteDetailControllerTest {

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
        testQuote.SBQQ__PrimaryContact__c = rec.Id;
        testQuote.SBQQ__BillingName__c = 'Test Billing Name';
        testQuote.Bill_To_Account_Name__c = 'Test Bill To Account Name';
        testQuote.End_User_Contact_Street__c = 'Test Street';
        testQuote.End_User_Contact_City__c = 'Test City';
        testQuote.End_User_Contact_State__c = 'Test State';
        testQuote.End_User_Contact_Zip__c = '00000';
        testQuote.End_User_Contact_Country__c = 'Test Country';
        testQuote.Ship_To_Contact_Name__c = 'Test Contact Name';
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

      @isTest static void test_shouldGetQuoteDetails() {
            List<SBQQ__Quote__c> expectedQuotes = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
            SBQQ__Quote__c expectedQuote = expectedQuotes[0];
            List<SBQQ__QuoteLine__c> expectedQL = [Select Id
                                    FROM SBQQ__QuoteLine__c 
                                    WHERE SBQQ__Quote__c = :expectedQuote.Id];
            
            PageReference pageRef = Page.QuoteDetail;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('id', expectedQuote.Id);

            Test.startTest();
            QuoteDetailController qdc = new QuoteDetailController();
            SBQQ__Quote__c actualQuote = qdc.getQuote();
            List<SBQQ__QuoteLine__c> actualQL = qdc.getQuoteLines();
            //Not sure where quote.PrimaryContactName__c not getting the FName and LName from Contact
            String expectedEndUserString = 'Customer 001<br/>null<br/>415 Mission Street<br/>San Francisco, California, 94105<br/>United States';
            String expectedBillToString = 'Test Bill To Account Name<br/>Test Billing Name<br/>415 Mission Street<br/>San Francisco, California, 94105<br/>United States';
            String expectedShipToString = 'Customer 001<br/>Test Contact Name<br/>415 Mission Street<br/>San Francisco, California, 94105<br/>United States';
            String actualEndUserString = qdc.getEndUserString();
            String actualBillToString = qdc.getBillToString();
            String actualShipToString = qdc.getShipToString();
            System.assertEquals(expectedQuote.Id, actualQuote.Id);
            System.assertEquals(expectedQL.size(), actualQL.size());
            System.assertEquals(expectedQL[0].Id, actualQL[0].Id);
            System.assertEquals(expectedEndUserString, actualEndUserString);
            System.assertEquals(expectedBillToString, actualBillToString);
            System.assertEquals(expectedShipToString, actualShipToString);

            Test.stopTest();
      }

}