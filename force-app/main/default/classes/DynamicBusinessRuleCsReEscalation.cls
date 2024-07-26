/**
* @author Dilowar Hussain
* @date 2024-03-08
*
* @description
* 
* This has been added as a part of SFDC-20019
*/
public with sharing class DynamicBusinessRuleCsReEscalation implements DynamicBusinessRuleAction{
    // public static Boolean executeLogic = FALSE;
    /**
    * Method description:
    * @param
    * @Return
    * This has been added as a part of
    */
    public void processRecords(Map<Id,SObject> newRecordMap, 
                                                            Map<Id,SObject> oldRecordMap,
                                                            List <SObject> records, 
                                                            String jsonParameter, 
                                                            String triggerOrder, 
                                                            String triggerContext) {
                                                                System.debug('###after the owner is updated back to dev queue');
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('DynamicBusinessRuleCsReEscalation', 'processRecords', LogModel.LOG_CATEGORY_APEX); 
        //system.debug('Invoke implements DynamicBusinessRuleCsReEscalation Apex Class');
        Map<Id, Case> mapCase = new Map<Id, Case>();
        try{
            //Get the Case record types.
            Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
            Id caseRTProfId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
            //Get the users. This will be used to distinguish between Jira Integration user and 
            List<User> jiraIntgUser = new List<User>();
            String jiraIntgUserName = Label.Jira_Integration_UserName;
            if(jiraIntgUserName != NULL){
                jiraIntgUser = [select id, email from user where username = : jiraIntgUserName];
            }
            List<User> loggedInUserList = [Select id from User where id =: UserInfo.getUserId()];
            if(triggerContext.contains('Update') || triggerContext.contains('Insert')){
                for(SObject rec: records){
                    Case cs = (Case)rec;
                    Case cs2 = oldRecordMap == null ? null : (Case)oldRecordMap.get(cs.Id);
                    if (cs2 == null){cs2 = new Case();}
                    System.debug('#####cs::: ' + JSON.serialize(cs));
                    // for non integration user and updating the owner to dev queue
                    if(loggedInUserList[0].id != jiraIntgUser[0].id && cs.Engineering_Escalation__c == FALSE && cs.Case_Owner_Queue_Name__c != NULL 
                           && (String.valueOf(cs.Case_Owner_Queue_Name__c).endsWith('DEV') 
                               || String.valueOf(cs.Case_Owner_Queue_Name__c).endsWith('Dev') || String.valueOf(cs.Case_Owner_Queue_Name__c).endsWith('dev')|| String.valueOf(cs.Case_Owner_Queue_Name__c).equalsIgnoreCase('Phishline'))){
                                   //System.debug('Final match');
                                   cs.Engineering_Escalated_By__c = loggedInUserList[0].id; //updated by chaitanya after P0
                                   //cs.Engineering_Escalated_By__c = cs.LastModifiedById;
                                   cs.Escalated_Date_Time__c = system.now();
                                   cs.Escalated_End_Date_Time__c = NULL;
                                   cs.Engineering_Escalation__c = TRUE;                               
                        // for non integration user and updating the owner to non dev queue
                    }else if(loggedInUserList[0].id != jiraIntgUser[0].id && caseRecordTypeId != NULL && caseRTProfId != NULL && (String.valueOf(caseRecordTypeId).equals(String.valueOf(cs.recordTypeID))||String.valueOf(caseRTProfId).equals(String.valueOf(cs.recordTypeID)))
                             && cs.Case_Owner_Queue_Name__c != NULL && cs.Case_Descalation_comment__c != NULL && cs.Escalation_Reason__c != NULL && (String.valueOf(cs.Case_Owner_Queue_Name__c).endsWith('DEV') 
                               || String.valueOf(cs.Case_Owner_Queue_Name__c).endsWith('Dev') || String.valueOf(cs.Case_Owner_Queue_Name__c).endsWith('dev')|| String.valueOf(cs.Case_Owner_Queue_Name__c).equalsIgnoreCase('Phishline'))){
                                 
                                 //cs.Engineering_Escalated_By__c = loggedInUserList[0].id;
                                 cs.Engineering_Escalated_By__c = loggedInUserList[0].id; 
                                 cs.Engineering_Escalation__c = TRUE;
                                 cs.Escalated_Date_Time__c = system.now();
                                 cs.Escalated_End_Date_Time__c = NULL;
                             }
                }
            }
            //executeLogic = TRUE;
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception' +e.getMessage()+'occurred at:' +e.getStackTraceString());
        }
    }
}