/**
* @author Dilowar Hussain
* @date 2022/01/13
*
* @description This is a Test class for the main class, "DynamicBusinessRuleAPIForJudge".
* This is a part of Jira "SFDC-16060" implementation
*/
@isTest
public with sharing class DynamicBusinessRuleAPIForJudgeTest {
    @isTest static void testUpdateCase(){
        List<Case> caseRecordListUpdate = new List<Case>(); 
        Map<Id, Case> mapCase = new Map<Id, Case>();
        Case caseRec = TestDataFactory.webCases[0];
        System.debug('caseRec is:' +caseRec);
        Id CaseRecordID = caseRec.id;
        System.debug('CaseRecordID is:' +CaseRecordID);
        
        if(CaseRecordID != NULL){
            List<Case> caseRecordList = [select id, caseNumber, serial_number__c, status, Case_Owner_Person__c, Engineering_Escalated_By__c, Escalated_To__c, Escalation_Approver__c, Escalated_to_support_escalations_by__c, RMA_Submitted_By__c, RMA_Approval_1__c, RMA_Approval_2__c from Case where id = :CaseRecordID];
            //system.debug('caseRecordList is:' +caseRecordList);
            for(Case cs02 : caseRecordList){
                mapCase.put(cs02.id, cs02);
                caseRecordListUpdate.add(cs02);
            }
            //system.debug('caseRecordListUpdate is:' +caseRecordListUpdate); 
            //Call the process records method
            DynamicBusinessRuleAPIForJudge businessRule = new DynamicBusinessRuleAPIForJudge();
            businessRule.processRecords(null, mapCase, caseRecordListUpdate, null, null, 'Insert');
            //Fetch the updated Case
            Case updatedCase = [Select Status
                From Case 
                Where Id = :caseRecordListUpdate[0].Id 
                Limit 1];
            //system.debug('updatedCase status is:' +updatedCase.Status); 
            //Assertions
            System.assertEquals('New', updatedCase.Status);
        }
    }
}