/**
* @author Dilowar Hussain
* @date 2023-10-19
*
* @description 
* Test Class for the class, DynamicBusinessRuleCsFeedItemCreate
*
* 
* This has been added as a part of SFDC-20019
*/
@isTest
public class DynamicBusinessRuleCsFdItemCrTest {
    @isTest    
    static void testProcessRecords(){
        try{
            List<Account> newAccount = TestDataFactory.customers;
            Contact con = new Contact();
            con.LastName = 'test';
            con.AccountId = newAccount[0].id;
            insert con;
            Test.startTest();
            Id tsCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
            Case caseRecord = new Case();
            caseRecord.RecordTypeId = tsCaseRTId;
            caseRecord.Status = 'New';
            /*caseRecord.Customer_Hold_Attempt_1__c = true;
            caseRecord.Customer_Hold_Attempt_1_Date_Time__c = Datetime.newInstance(2008, 12, 1, 12, 30, 2);
            caseRecord.Customer_Hold_Attempt_2__c = false;*/
        	caseRecord.Status = 'Waiting for Customer Response';  
            caseRecord.Case_Descalation_comment__c = 'WOC 01';
            caseRecord.Jira_ID__c = 'SFDC-1234';
            caseRecord.ContactId = con.Id;
            caseRecord.AccountId = newAccount[0].id;
            caseRecord.Alternate_Email__c = 'test@test.com';
            caseRecord.BusinesGroup__c = 'Core';
            caseRecord.Case_Reason__c = 'BCC';
            //caseRecord.Closed_Case_Reason__c = 'Account Merge';
            //caseRecord.Case_Closed_Reason_WM__c = 'Expired Subscriptions';        
            insert caseRecord;    
            
            
            //caseRecord.Case_Reason__c = 'Account Management';
            //update caseRecord;
            Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception occurred:' +e.getStackTraceString());
        }
        
    }
}