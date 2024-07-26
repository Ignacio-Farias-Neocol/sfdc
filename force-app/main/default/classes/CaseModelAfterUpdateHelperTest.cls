@isTest
public class CaseModelAfterUpdateHelperTest {
    
    @testSetup
    public static void insertCase(){
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
        rec.Use_Alt_Email_for_Case__c = true;
        rec.Alternative_Email__c = 'abc@test.com';
        insert rec;
        
        Case caseRecord = new Case();
        caseRecord.RecordTypeId = CaseModel.TECH_SUPPORT_RECORD_TYPE_ID;
        caseRecord.Origin = 'Web';
        caseRecord.Product_Family_List__c='XDR';
        caseRecord.ContactId = rec.Id;
        caseRecord.Subject='test';
        caseRecord.XDR_Ticket_Number__c = '123';
        caseRecord.Closed_Case_Reason__c='Security Incident';
        insert caseRecord;
    }
    
    @isTest
    static void unitTest01(){
        Test.startTest();
        Account customer = [select Id From Account limit 1];
        Contact rec = [SELECT Id FROM Contact Limit 1];
        
        Case caseRecord = new Case();
        caseRecord.RecordTypeId = CaseModel.WEB_MESSAGE_RECORD_TYPE_ID;
        caseRecord.Origin = 'Web';
        caseRecord.ContactId = rec.Id;
        caseRecord.subject = '123';
        caseRecord.XDR_Ticket_Number__c = '123';
        insert caseRecord;
        
        Group grp = [Select Id, Name, Type from Group where Name = 'XDR Escalations' and Type = 'Queue' limit 1];
        caseRecord.OwnerId = grp.Id;
        caseRecord.XDR_Ticket_Number__c = '123';
        caseRecord.subject = '12355';
        caseRecord.XDR_Ticket_Status__c = 'Awaiting XDR Support';
        update caseRecord;
        Test.stopTest();
    }
    
    @isTest
    static void unitTest02(){
        Test.startTest();
       	Case caseRecord =[select Id from case limit 1];
        caseRecord.XDR_Ticket_Number__c = '123';
        caseRecord.Subject='test update Subject';
        caseRecord.Engineering_Escalated_By__c=UserInfo.getUserId();
        caseRecord.XDR_Ticket_Status__c = 'Pending';
         update caseRecord;
        Test.stopTest();
    }
    
     @isTest
    static void afterUpdateClosedCaseReasonTest(){
         Test.startTest();        
        Case caseRecord =[select Id from case limit 1];
        caseRecord.Closed_Case_Reason__c='Bug';
        update caseRecord;
        Test.stopTest();
        
    }
}