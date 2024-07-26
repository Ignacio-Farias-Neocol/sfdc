@isTest
public class CaseClosureBatchTest {
	
    @isTest
    static void testMethod01(){
        Contact con = new Contact();
        con.LastName = 'test';
        insert con;
        
        Id webMessageRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();
        Case caseRecord = new Case();
        caseRecord.RecordTypeId = webMessageRTId;
        caseRecord.Status = 'Waiting for Customer Response';
        caseRecord.Customer_Hold_Attempt_1__c = true;
        caseRecord.Customer_Hold_Attempt_1_Date_Time__c = Datetime.newInstance(2008, 12, 1, 12, 30, 2);
        caseRecord.Customer_Hold_Attempt_2__c = false;
        caseRecord.WOC_Reason__c = 'Serial Verification';
        caseRecord.ContactId = con.Id;
        caseRecord.Alternate_Email__c = 'test@test.com';
        caseRecord.BusinesGroup__c = 'Core';
        caseRecord.Case_Reason__c = 'BCC';
        caseRecord.Closed_Case_Reason__c = 'Account Merge';
        caseRecord.Case_Closed_Reason_WM__c = 'Expired Subscriptions';        
		insert caseRecord;    
        
        caseRecord.Status = 'Resolved';  
        caseRecord.Case_Closed_Reason__c = 'Administrator Setup';
        caseRecord.Case_Reason__c = 'Account Management';
        update caseRecord;
        
        Test.startTest();        
        CaseClosureSchedule sh1 = new CaseClosureSchedule();    
        WebMessageCleanUpScheduler webSchedule=new WebMessageCleanUpScheduler();
        String sch = '0 0 23 * * ?';
        system.schedule('Test check', sch, sh1);  
        system.schedule('Test check1', sch, webSchedule);  
        Test.stopTest();
    }
}