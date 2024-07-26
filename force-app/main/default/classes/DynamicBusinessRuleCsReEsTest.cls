/**
* @author Dilowar Hussain
* @date 2023-10-18
*
* @description 
* Test Class for the class, "DynamicBusinessRuleCsReEscalation"
* 
* This has been added as a part of SFDC-20019
*/
@isTest
public with sharing class DynamicBusinessRuleCsReEsTest {
    
    @isTest
    static void testProcessRecordsWithJIRAUser(){
        try{

			TriggerContextVariables.RUN_CASE_TRIGGER = false;            
            String jiraIntgUserName = Label.Jira_Integration_UserName;
            User jiraUser = [select id, email from user where username = : jiraIntgUserName];
            List<Group> lstGrp = [select id, name from Group where name  = 'Backup Dev'];
            List<Account> newAccount = TestDataFactory.customers;
            Contact con = new Contact();
            Case caseRecord = new Case();
            Test.startTest();
            //system.debug('Execute as Jira');
            con.LastName = 'test';
            con.AccountId = newAccount[0].id;
            insert con;
            Id tsCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
            caseRecord.RecordTypeId = tsCaseRTId;
            caseRecord.Status = 'New';  
            caseRecord.Case_Descalation_comment__c = 'WOC 01';
            caseRecord.Jira_ID__c = 'SFDC-1234';
            caseRecord.ContactId = con.Id;
            caseRecord.AccountId = newAccount[0].id;
            caseRecord.Alternate_Email__c = 'test@test.com';
            caseRecord.BusinesGroup__c = 'Core';
            caseRecord.Case_Reason__c = 'BCC';
            caseRecord.Engineering_Escalation__c = false;
            caseRecord.Product_Family_List__c = 'Barracuda CloudSecurity Guardian';
            caserecord.Missing_Serial_Number__c = '123456';
            caseRecord.Escalation_Reason__c = 'Test Escalation';
            caseRecord.OwnerId = lstGrp[0].id;        
            insert caseRecord; 
            String caseJSON = '{"attributes":{"type":"CasSe","url":"/services/data/v25.0/sobjects/Case/'+caseRecord.id+'"},"Id":"'+caseRecord.id+'","lastModifiedById":"'+jiraUser.id+'","Escalation_Reason__c":"Test Escalation","Case_Owner_Queue_Name__c":"BackUp Dev","Case_Descalation_comment__c":"WOC 01", "recordTypeID":"'+tsCaseRTId+'"}'; 
            system.debug('caseJSON is:' +caseJSON);
            Case c = (Case) JSON.deserialize(caseJSON, Case.class); 
            /*system.debug('Lastly Modified by : ' +c.LastModifiedById);
system.debug('Escalation_Reason__c is : ' +c.Escalation_Reason__c);
system.debug('Case_Owner_Queue_Name__c is : ' +c.Case_Owner_Queue_Name__c);
system.debug('Case_Descalation_comment__c is : ' +c.Case_Descalation_comment__c);
system.debug('Case RecordType is : ' +c.recordTypeID);*/
            Map<id, Case> mapCs = new Map<Id, Case>();
            mapCs.put(c.id, c);
            List<Case> lstCS = new List<Case>();
            lstCS.add(c);
            DynamicBusinessRuleCsReEscalation dbre = new DynamicBusinessRuleCsReEscalation();
            dbre.processRecords(mapCs, NULL, lstCS, NULL, NULL, 'Insert');
                        
            caseRecord.OwnerId = UserInfo.getUserId();
            update caseRecord;
            
            System.debug('###updating to dev queue');
            TriggerContextVariables.RUN_CASE_TRIGGER = true;
            caseRecord.OwnerId = lstGrp[0].id; 
            caseRecord.Case_Descalation_comment__c = 'test';
            caseRecord.Engineering_Escalation__c = true;
            update caseRecord;            
            Test.stopTest();
            //}
        }Catch(Exception e){
            System.debug('Exception occurred'+e.getMessage()+'at' +e.getStackTraceString());
        }
    }
    
}