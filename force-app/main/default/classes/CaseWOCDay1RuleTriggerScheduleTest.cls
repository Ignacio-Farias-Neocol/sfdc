@isTest
public class CaseWOCDay1RuleTriggerScheduleTest {
    
    @testSetup 
    static void methodName(){
        Contact con = new Contact();
        con.LastName = 'test';
        insert con;
        
        List<Case> caseList = new List<Case>();
        Id technicalSupportRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
        Id webMessageRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();
        Case caseRecord = new Case();
        caseRecord.RecordTypeId = technicalSupportRTId;
        caseRecord.Status = 'Waiting for Customer Response';
        caseRecord.Customer_Hold_Attempt_1__c = true;
        caseRecord.Customer_Hold_Attempt_1_Date_Time__c = Datetime.newInstance(2008, 12, 1, 12, 30, 2);
        caseRecord.Customer_Hold_Attempt_2__c = false;
        caseRecord.WOC_Reason__c = 'Call back';
        caseRecord.ContactId = con.Id;
        caseRecord.Alternate_Email__c = 'test@test.com';
        caseRecord.BusinesGroup__c = 'Core';
        caseRecord.Product_Family_List__c = 'Backup Server/Service';
        caseRecord.Missing_Serial_Number__c = 'abc';
        caseRecord.Case_Reason__c = 'BCC';
        caseRecord.Closed_Case_Reason__c = 'Account Merge';
        caseList.add(caseRecord); 
                       
        insert caseList;
    }
    	
    @isTest
    static void testBatch(){
        Test.startTest();
        CaseWOCDay1RuleTriggerSchedule sh1 = new CaseWOCDay1RuleTriggerSchedule();      
        String sch = '0 0 23 * * ?';
        system.schedule('Test check', sch, sh1);           
        Test.stopTest();
    }
}