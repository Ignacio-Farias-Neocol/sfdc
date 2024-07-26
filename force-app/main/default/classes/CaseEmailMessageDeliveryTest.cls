@isTest
public class CaseEmailMessageDeliveryTest {
	
    @isTest
    static void unitTest01(){
        
        Account customer = new Account();
        customer.Is_Unit_Test__c  = true;
        customer.Name = 'Customer' + ' ' + 'abc';
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
        insert customer;
        
        Contact rec = new Contact();
        rec.LastName = 'Doe' + ' ' + 'abc';
        rec.FirstName = 'John';
        //rec.FirstName__c = 'John';
        //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
        rec.Email = 'John.Doe@test.com';
        rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        rec.AccountId = customer.Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal'; 
        rec.Alternative_Email__c = 'sample@test.com';
        rec.Use_Alt_Email_for_Case__c = true;
        insert rec;
        
        String INTERNAL_TICKET_COMMUNITIES_QUEUE_ID = [Select Id, Name, Type from Group where Name = 'Internal Ticket - Communities' and Type = 'Queue'].Id;
        Case cse = new Case();
        cse.Description = 'Web Case 1234';
        cse.Status = 'New';
        cse.Subject = 'Unit Test 1234';
        cse.Origin = 'Web';
        cse.Web_Language_of_correspondence__c = 'English';
        cse.Web_Region__c = 'Americas';
        cse.Offline_Support_Type__c = 'Sales'; 
        cse.New_Case_Notification_Sent__c = false; 
        cse.OwnerId = INTERNAL_TICKET_COMMUNITIES_QUEUE_ID;
        cse.Additional_Recipient_Email__c = 'test@abc.com; test2@abc.com';
        cse.ContactId = rec.Id;
        insert cse; 
        
        CaseEmailMessageDelivery.FlowInputs inputs = new CaseEmailMessageDelivery.FlowInputs();   
        inputs.caseId = cse.Id;
        inputs.emailTemplateName = 'Case_Consolidated_WOC_Notification_CB_Attempt2';
        CaseEmailMessageDelivery.sendEmail(new List<CaseEmailMessageDelivery.FlowInputs>{inputs});
    }
    
    @isTest
    static void unitTest02(){
        
        Account customer = new Account();
        customer.Is_Unit_Test__c  = true;
        customer.Name = 'Customer' + ' ' + 'abc';
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
        insert customer;
        
        Contact rec = new Contact();
        rec.LastName = 'Doe' + ' ' + 'abc';
        rec.FirstName = 'John';
        //rec.FirstName__c = 'John';
        //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
        rec.Email = 'John.Doe@test.com';
        rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        rec.AccountId = customer.Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal'; 
        rec.Alternative_Email__c = 'sample@test.com';
        rec.Use_Alt_Email_for_Case__c = false;
        insert rec;
        
        String INTERNAL_TICKET_COMMUNITIES_QUEUE_ID = [Select Id, Name, Type from Group where Name = 'Internal Ticket - Communities' and Type = 'Queue'].Id;
        Case cse = new Case();
        cse.Description = 'Web Case 1234';
        cse.Status = 'New';
        cse.Subject = 'Unit Test 1234';
        cse.Origin = 'Web';
        cse.Web_Language_of_correspondence__c = 'English';
        cse.Web_Region__c = 'Americas';
        cse.Offline_Support_Type__c = 'Sales'; 
        cse.New_Case_Notification_Sent__c = false; 
        cse.OwnerId = INTERNAL_TICKET_COMMUNITIES_QUEUE_ID;
        cse.Additional_Recipient_Email__c = 'test@abc.com; test2@abc.com';
        cse.ContactId = rec.Id;
        insert cse; 
        
        CaseEmailMessageDelivery.FlowInputs inputs = new CaseEmailMessageDelivery.FlowInputs();   
        inputs.caseId = cse.Id;
        inputs.emailTemplateName = 'Case_Consolidated_WOC_Notification_CB_Attempt2';
        CaseEmailMessageDelivery.sendEmail(new List<CaseEmailMessageDelivery.FlowInputs>{inputs});
    }
    
}