/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 08-07-2023
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class CaseModelAfterUpdateHelper
{
    public static boolean isExecuted=false;
    public static void afterUpdate(List<Case> newList, Map<Id, Case> oldMap){
        List<Case> XDREscalatedCaseList = new List<Case>();
        for(Case cs: newList){
            if(cs.OwnerId != oldMap.get(cs.Id).OwnerId && cs.Case_Owner_Queue_Name__c == 'XDR Escalations' && cs.XDR_Ticket_Number__c != null && (cs.XDR_Ticket_Status__c == 'Awaiting XDR Support' || cs.XDR_Ticket_Status__c == 'Solved')) {
                XDREscalatedCaseList.add(cs);
            }
            
            if(cs.Status != oldMap.get(cs.Id).Status && (cs.Status == 'Resolved' || cs.Status == 'Closed') && cs.XDR_Ticket_Number__c != null && cs.XDR_Ticket_Status__c != 'Solved'){
                XDREscalatedCaseList.add(cs);
            }
        }
        
        if(!XDREscalatedCaseList.isEmpty()){
            CaseXDREscalationHelper.createPlatformEvent(XDREscalatedCaseList);
        }
    }
    
    public static void afterUpdateClosedCaseReason(List<Case> newList, Map<Id, Case> oldMap){
        if(!TriggerContextVariables.IS_1ST_RUN_afterUpdateClosedCaseReason_COMPLETED){
            TriggerContextVariables.IS_1ST_RUN_afterUpdateClosedCaseReason_COMPLETED = true;
        } else {
            return;
        }
        
        List<Case> caseToBeUpdated = new List<Case>();
        for(Case caseRecord: newList){
            Case oldCase = oldMap.get(caseRecord.Id);
            if(oldCase.Closed_Case_Reason__c == 'Security Incident'
               && oldCase.Closed_Case_Reason__c !=caseRecord.Closed_Case_Reason__c ){
                   Case caseUpdate = new Case(Id = caseRecord.Id);
                   caseUpdate.Security_Vulnerability_Number__c ='';
                   caseUpdate.Is_the_Product_in_Production__c ='';
                   caseUpdate.How_was_the_issue_remediated__c ='';
                   caseUpdate.Migrated_off_Current_Product__c ='';
                   caseUpdate.Security_Product__c ='';
                   caseToBeUpdated.add(caseUpdate);
               }
        }
        
        if(!caseToBeUpdated.isEmpty()){
            update caseToBeUpdated;
        }
        
    }
    
}