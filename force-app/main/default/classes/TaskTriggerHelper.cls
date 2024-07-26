/**
* @author Aditya Padhy
* @date 2021-12-22
*
* @group Task Trigger Helper
* @group-content This Helper is for Task Trigger for the updateOpportunityFirstResponseTime
*
* @description:
*   SFDC-14523 CORE ONLY: Total Time to Response (TTR) for Opportunities Reporting in SFDC  
*/

public class TaskTriggerHelper{
    //Updating the First Response time of the Opportunity after completion of Task
    public static void updateOpportunityFirstResponseTime(List<Task> lstOfTasks, Map<Id, Task> mapOfOldTasks){
        LogModel log = LogModel.startLog('TaskTriggerHelper', 'updateOpportunityFirstResponseTime');
        try{
            Task oldTaskRec;
            Set<Id> setOfOppIds = new Set<Id>();
            Id whatId;
            String objectType;
            for(Task tsk : lstOfTasks){
                oldTaskRec = (mapOfOldTasks != null) ? mapOfOldTasks.get(tsk.Id) : null;
                whatId = tsk.WhatId;
                objectType = String.isNotBlank(tsk.WhatId) ? String.valueOf(whatId.getsobjecttype()) : '';
                if(((oldTaskRec == null && tsk.Status == 'Completed') || (oldTaskRec != null && tsk.Status != oldTaskRec.Status && tsk.Status == 'Completed')) && String.isNotBlank(tsk.WhatId) && objectType == 'Opportunity'){
                    setOfOppIds.add(tsk.WhatId);
                }
            }
            if(!setOfOppIds.isEmpty()){
                Set<String> setOfExcludedRoles = new Set<String>();
                Set<String> setOfExcTaskTypes = new Set<String>();
                List<Opportunity> lstOfOppsToUpdate = new List<Opportunity>();
                Opportunity oppToUpdate;
                for(First_Response_Calc_Excluded_Roles__mdt excludedRoles : First_Response_Calc_Excluded_Roles__mdt.getAll().values()){
                    setOfExcludedRoles.add(excludedRoles.Role_Name__c);
                }
                
                for(First_Response_Calc_Excluded_Task_Type__mdt excludedTypes : First_Response_Calc_Excluded_Task_Type__mdt.getAll().values()){
                    setOfExcTaskTypes.add(excludedTypes.Type_Name__c);
                }
                
                for(Opportunity opp : [SELECT Id, First_Respond_Time__c,CreatedDate, (SELECT Id,CompletedDateTime,CreatedDate FROM Tasks where Owner.UserRole.Name NOT IN: setOfExcludedRoles AND Type NOT IN: setOfExcTaskTypes AND Status =  'Completed' ORDER BY CompletedDateTime ASC) FROM Opportunity WHERE Id IN: setOfOppIds AND Business_Group__c = 'Core']){
                    for(Task tsk : opp.Tasks){
                        if(opp.First_Respond_Time__c != tsk.CompletedDateTime && tsk.CreatedDate >= opp.CreatedDate){
                            oppToUpdate = new opportunity();
                            oppToUpdate.Id = opp.Id;
                            oppToUpdate.First_Respond_Time__c = tsk.CompletedDateTime;
                            lstOfOppsToUpdate.add(oppToUpdate);
                            break;
                        }
                    }
                }
                if(!lstOfOppsToUpdate.isEmpty()){
                    update lstOfOppsToUpdate;
                }
            }
        }catch(Exception ex){
            log.addExceptionLog(ex);
        }
    }
    /***
     * Method Name:
     * Description: This method just copies the Activity type field (standard) value and pastes 
     * it on the field, "Activity_Type_reporting__c".
     * This method has been added as a part SFDC-17589.
     * 
     * @Param
     * @return none
     *  
     */
    public static void updateActivityTypeReport(List<Task> newList, Map<id, Task> mapTask){
        LogModel log = LogModel.startLog('TaskTriggerHelper', 'updateActivityTypeReport', LogModel.LOG_CATEGORY_APEX);
        try{
            for(Task tsk: newList){
                System.debug('Task type is:'+tsk.Type);
                if(tsk.Type != NULL || (tsk.Type != NULL && !mapTask.isEmpty() && mapTask.get(tsk.id).Type != tsk.Type 
                    && mapTask.get(tsk.id).Type != NULL)){
                    System.debug('Activity Type is:' +String.valueOf(tsk.Type));
                    tsk.Activity_Type_reporting__c = String.valueOf(tsk.Type); 
                    System.debug('Activity Reporting Type is:' +tsk.Activity_Type_reporting__c);
                }
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            System.debug('Exception occurred at:' +e.getStackTraceString());
        }
    }

    // Update Account's CSM_Last_Touch_DateTime__c
    // Condition Task is Completed by Apollo: Custom - Customer Success Profile Users
    public static void updateCSMLastTouchDate(List<Task> lstOfTasks, Map<Id, Task> mapOfOldTasks){
        System.debug('inside updateCSMLastTouchDate...');
        LogModel log = LogModel.startLog('TaskTriggerHelper', 'updateCSMLastTouchDate');
        try{
            Task oldTaskRec;
            Set<Id> setOfAccIds = new Set<Id>();
            Id whatId;
            String objectType;
            Id profileId = UserInfo.getProfileId();
            String profileName =[Select Id, Name from Profile where Id=:profileId].Name;
            //for(Task tsk : lstOfTasks)
            for(Task tsk : [Select Id,WhatId,Status,CreatedBy.Name from Task where Id=:lstOfTasks]){
                oldTaskRec = (mapOfOldTasks != null) ? mapOfOldTasks.get(tsk.Id) : null;
                whatId = tsk.WhatId;
                objectType = String.isNotBlank(tsk.WhatId) ? String.valueOf(whatId.getsobjecttype()) : '';
                if(((oldTaskRec == null && tsk.Status == 'Completed') || (oldTaskRec != null && tsk.Status != oldTaskRec.Status && tsk.Status == 'Completed')) && String.isNotBlank(tsk.WhatId) && objectType == 'Account' && (profileName == System.Label.Apollo_Custom_Customer_Success_Profile || tsk.CreatedBy.Name == 'Gainsight Service')){
                    setOfAccIds.add(tsk.WhatId);
                }
            }
            List<Account> lstOfAcctsToUpdate = new List<Account>();
            if(!setOfAccIds.isEmpty()){
                for(Account acc : [SELECT Id, CSM_Last_Touch_DateTime__c FROM Account WHERE Id IN: setOfAccIds]){
                    Account accToUpdate = new Account();
                    accToUpdate.Id = acc.Id;
                    accToUpdate.CSM_Last_Touch_DateTime__c = System.today();
                    lstOfAcctsToUpdate.add(accToUpdate);
                }
                if(!lstOfAcctsToUpdate.isEmpty()){
                    update lstOfAcctsToUpdate;
                }
            }
        }catch(Exception ex){
            log.addExceptionLog(ex);
        }
    }
}