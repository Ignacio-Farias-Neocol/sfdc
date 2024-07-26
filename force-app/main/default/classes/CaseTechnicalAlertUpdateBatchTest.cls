@isTest
public class CaseTechnicalAlertUpdateBatchTest {
    
    @isTest
    static void unitTest01(){
        Account acc = TestDataFactory.customers[0];
        
        Contact con = new Contact();
        con.LastName = 'Doe' + ' ' + '1234';
        con.FirstName = 'John';
        con.Email = 'John.Doe@test.com';
        con.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        con.AccountId = acc.Id;
        con.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        con.LeadSource = 'Renewal';
        insert con;        
        
        Case cse = new Case();
        cse.Description = 'Web Case 1234';
        cse.Status = 'New';
        cse.SuppliedEmail = 'test@abc.com';
        cse.Subject = 'Unit Test 1234';
        cse.Origin = 'Web';
        cse.Web_Language_of_correspondence__c = 'English';
        cse.Web_Region__c = 'Americas';
        cse.Offline_Support_Type__c = 'Sales'; 
        cse.New_Case_Notification_Sent__c = false; 
        cse.Callback_Date_Time__c = system.now();
        cse.recordTypeId =   Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Offline').getRecordTypeId();
        cse.AccountId = acc.Id;
        TriggerContextVariables.RUN_CASE_TRIGGER = false;
        insert cse;   
        
        AccountTriggerHelper.isHelperExecuted = false;
        acc.Technical_Alert__c = 'abc';
        update acc;
    }
}