@isTest
public class CaseWOCDay1RuleTriggerBatchTest {
    
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
               
        Case caseRecord2 = new Case();
        caseRecord2.RecordTypeId = technicalSupportRTId;
        caseRecord2.Status = 'Waiting for Customer Response';
        caseRecord2.Customer_Hold_Attempt_1__c = true;
        caseRecord2.Customer_Hold_Attempt_1_Date_Time__c = Datetime.newInstance(2008, 12, 1, 12, 30, 2);
        caseRecord2.Customer_Hold_Attempt_2__c = false;
        caseRecord2.WOC_Reason__c = 'Call back';
        caseRecord2.ContactId = con.Id;
        caseRecord2.Alternate_Email__c = 'test@test.com';
        caseRecord2.BusinesGroup__c = 'MSP';
        caseRecord2.Product_Family_List__c = 'Backup Server/Service';
        caseRecord2.Missing_Serial_Number__c = 'abc';
        caseRecord2.Case_Reason__c = 'BCC';
        caseRecord2.Closed_Case_Reason__c = 'Account Merge';
        caseList.add(caseRecord2);  
        
        Case caseRecord3 = new Case();
        caseRecord3.RecordTypeId = technicalSupportRTId;
        caseRecord3.Status = 'Waiting for Customer Response';
        caseRecord3.Customer_Hold_Attempt_1__c = true;
        caseRecord3.Customer_Hold_Attempt_1_Date_Time__c = Datetime.newInstance(2008, 12, 1, 12, 30, 2);
        caseRecord3.Customer_Hold_Attempt_2__c = false;
        caseRecord3.WOC_Reason__c = 'Pending Additional Information';
        caseRecord3.ContactId = con.Id;
        caseRecord3.Alternate_Email__c = 'test@test.com';
        caseRecord3.BusinesGroup__c = 'MSP';
        caseRecord3.Product_Family_List__c = 'Backup Server/Service';
        caseRecord3.Missing_Serial_Number__c = 'abc';
        caseRecord3.Case_Reason__c = 'BCC';
        caseRecord3.Closed_Case_Reason__c = 'Account Merge';
        caseList.add(caseRecord3);   

        Case caseRecord4 = new Case();
        caseRecord4.RecordTypeId = technicalSupportRTId;
        caseRecord4.Status = 'Waiting for Customer Response';
        caseRecord4.Customer_Hold_Attempt_1__c = true;
        caseRecord4.Customer_Hold_Attempt_1_Date_Time__c = Datetime.newInstance(2008, 12, 1, 12, 30, 2);
        caseRecord4.Customer_Hold_Attempt_2__c = false;
        caseRecord4.WOC_Reason__c = 'Resolution Offered';
        caseRecord4.ContactId = con.Id;
        caseRecord4.Alternate_Email__c = 'test@test.com';
        caseRecord4.BusinesGroup__c = 'MSP';
        caseRecord4.Product_Family_List__c = 'Backup Server/Service';
        caseRecord4.Missing_Serial_Number__c = 'abc';
        caseRecord4.Case_Reason__c = 'BCC';
        caseRecord4.Closed_Case_Reason__c = 'Account Merge';
        caseList.add(caseRecord4);  
        
        Case caseRecord5 = new Case();
        caseRecord5.RecordTypeId = technicalSupportRTId;
        caseRecord5.Status = 'Waiting for Customer Response';
        caseRecord5.Customer_Hold_Attempt_1__c = true;
        caseRecord5.Customer_Hold_Attempt_1_Date_Time__c = Datetime.newInstance(2008, 12, 1, 12, 30, 2);
        caseRecord5.Customer_Hold_Attempt_2__c = false;
        caseRecord5.WOC_Reason__c = 'Pending Additional Information';
        caseRecord5.ContactId = con.Id;
        caseRecord5.Alternate_Email__c = 'test@test.com';
        caseRecord5.BusinesGroup__c = 'Core';
        caseRecord5.Product_Family_List__c = 'Backup Server/Service';
        caseRecord5.Missing_Serial_Number__c = 'abc';
        caseRecord5.Case_Reason__c = 'BCC';
        caseRecord5.Closed_Case_Reason__c = 'Account Merge';
        caseList.add(caseRecord5);   
        
        Case caseRecord6 = new Case();
        caseRecord6.RecordTypeId = technicalSupportRTId;
        caseRecord6.Status = 'Waiting for Customer Response';
        caseRecord6.Customer_Hold_Attempt_1__c = true;
        caseRecord6.Customer_Hold_Attempt_1_Date_Time__c = Datetime.newInstance(2008, 12, 1, 12, 30, 2);
        caseRecord6.Customer_Hold_Attempt_2__c = false;
        caseRecord6.WOC_Reason__c = 'Call back';
        caseRecord6.ContactId = con.Id;
        caseRecord6.Alternate_Email__c = 'test@test.com';
        caseRecord6.BusinesGroup__c = 'Sonian';
        caseRecord6.Product_Family_List__c = 'Backup Server/Service';
        caseRecord6.Missing_Serial_Number__c = 'abc';
        caseRecord6.Case_Reason__c = 'BCC';
        caseRecord6.Closed_Case_Reason__c = 'Account Merge';
        caseList.add(caseRecord6);   

        Case caseRecord7 = new Case();
        caseRecord7.RecordTypeId = technicalSupportRTId;
        caseRecord7.Status = 'Waiting for Customer Response';
        caseRecord7.Customer_Hold_Attempt_1__c = true;
        caseRecord7.Customer_Hold_Attempt_1_Date_Time__c = Datetime.newInstance(2008, 12, 1, 12, 30, 2);
        caseRecord7.Customer_Hold_Attempt_2__c = false;
        caseRecord7.WOC_Reason__c = 'Pending Additional Information';
        caseRecord7.ContactId = con.Id;
        caseRecord7.Alternate_Email__c = 'test@test.com';
        caseRecord7.BusinesGroup__c = 'Sonian';
        caseRecord7.Product_Family_List__c = 'Backup Server/Service';
        caseRecord7.Missing_Serial_Number__c = 'abc';
        caseRecord7.Case_Reason__c = 'BCC';
		caseRecord7.Closed_Case_Reason__c = 'Account Merge';
        caseList.add(caseRecord7);  
        
        Case caseRecord8 = new Case();
        caseRecord8.RecordTypeId = technicalSupportRTId;
        caseRecord8.Status = 'Waiting for Customer Response';
        caseRecord8.Customer_Hold_Attempt_1__c = true;
        caseRecord8.Customer_Hold_Attempt_1_Date_Time__c = Datetime.newInstance(2008, 12, 1, 12, 30, 2);
        caseRecord8.Customer_Hold_Attempt_2__c = false;
        caseRecord8.WOC_Reason__c = 'Resolution Offered';
        caseRecord8.ContactId = con.Id;
        caseRecord8.Alternate_Email__c = 'test@test.com';
        caseRecord8.BusinesGroup__c = 'Sonian';
        caseRecord8.Product_Family_List__c = 'Backup Server/Service';
        caseRecord8.Missing_Serial_Number__c = 'abc';
        caseRecord8.Case_Reason__c = 'BCC';
        caseRecord8.Closed_Case_Reason__c = 'Account Merge';
        caseList.add(caseRecord8);    
        
        Case caseRecord9 = new Case();
        caseRecord9.RecordTypeId = webMessageRTId;
        caseRecord9.Status = 'Waiting for Customer Response';
        caseRecord9.Customer_Hold_Attempt_1__c = true;
        caseRecord9.Customer_Hold_Attempt_1_Date_Time__c = Datetime.newInstance(2008, 12, 1, 12, 30, 2);
        caseRecord9.Customer_Hold_Attempt_2__c = false;
        caseRecord9.WOC_Reason__c = 'Serial Verification';
        caseRecord9.ContactId = con.Id;
        caseRecord9.Alternate_Email__c = 'test@test.com';
        caseRecord9.Product_Family_List__c = 'Backup Server/Service';
        caseRecord9.Missing_Serial_Number__c = 'abc';
        caseRecord9.Case_Reason__c = 'BCC';
        caseRecord9.Closed_Case_Reason__c = 'Account Merge';
        caseList.add(caseRecord9);        
        
        Case caseRecord10 = new Case();
        caseRecord10.RecordTypeId = webMessageRTId;
        caseRecord10.Status = 'Waiting for Customer Response';
        caseRecord10.Customer_Hold_Attempt_1__c = true;
        caseRecord10.Customer_Hold_Attempt_1_Date_Time__c = Datetime.newInstance(2008, 12, 1, 12, 30, 2);
        caseRecord10.Customer_Hold_Attempt_2__c = false;
        caseRecord10.WOC_Reason__c = 'Contact Verification';
        caseRecord10.ContactId = con.Id;
        caseRecord10.Alternate_Email__c = 'test@test.com';
        caseRecord10.Product_Family_List__c = 'Backup Server/Service';
        caseRecord10.Missing_Serial_Number__c = 'abc';
        caseRecord10.Case_Reason__c = 'BCC';
        caseRecord10.Closed_Case_Reason__c = 'Account Merge';
        caseList.add(caseRecord10);  
        
        Case caseRecord11 = new Case();
        caseRecord11.RecordTypeId = technicalSupportRTId;
        caseRecord11.Status = 'Waiting for Customer Response';
        caseRecord11.Customer_Hold_Attempt_1__c = true;
        caseRecord11.Customer_Hold_Attempt_1_Date_Time__c = Datetime.newInstance(2008, 12, 1, 12, 30, 2);
        caseRecord11.Customer_Hold_Attempt_2__c = true;
        caseRecord11.Customer_Hold_Attempt_3__c = true;
        caseRecord11.WOC_Reason__c = 'Resolution Offered';
        caseRecord11.ContactId = con.Id;
        caseRecord11.Alternate_Email__c = 'test@test.com';
        caseRecord11.BusinesGroup__c = 'Core';
        caseRecord11.Product_Family_List__c = 'Backup Server/Service';
        caseRecord11.Missing_Serial_Number__c = 'abc';
        caseRecord11.Case_Reason__c = 'BCC';
        caseRecord11.Closed_Case_Reason__c = 'Account Merge';
        caseList.add(caseRecord11);                    
        
        insert caseList;
    }
    	
    @isTest
    static void testBatch(){
        Test.startTest();
        CaseWOCDay1RuleTriggerBatch batch = new CaseWOCDay1RuleTriggerBatch();
        DataBase.executeBatch(batch);
        //CaseWOCDay1RuleTriggerSchedule sh1 = new CaseWOCDay1RuleTriggerSchedule();      
        //String sch = '0 0 23 * * ?';
        //system.schedule('Test check', sch, sh1);           
        Test.stopTest();
    }
}