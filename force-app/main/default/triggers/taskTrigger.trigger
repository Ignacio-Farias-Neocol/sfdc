trigger taskTrigger on Task (before Insert, before Update, after insert, after update) {
    
    ByPassObjectTriggers__mdt taskTriggerMetadata = [Select Id, DeveloperName, ByPassCustomTriggers__c From ByPassObjectTriggers__mdt Where DeveloperName = 'Task'];
    
    if(taskTriggerMetadata.ByPassCustomTriggers__c == false)
    {
        if((trigger.isinsert || trigger.isafter) && trigger.isafter ){
            list<id> caseIds = new list<id>();
            String case_prefix = Schema.SObjectType.case.getKeyPrefix();
            for(task t:trigger.new){
                if(t.whatId != null){   
                if(string.valueof(t.whatId).startswith(case_prefix))
                    caseIds.add(t.whatId);
                }
            }
            
            list<case> casesToUpdate = new list<Case>();
            for(case c : [select id,(select id, status from tasks where status = 'Not Started') from case where Id in : caseIds]){
                
                
                if(c.tasks.size()>0){casesToupdate.add(new case(id=c.Id,Prof_Service_Task_Created__c = true));}else{casesToupdate.add(new case(id=c.Id,Prof_Service_Task_Created__c = false));}
                
                
            }
            update casesToUpdate;
            
        }
    }
    //  SFDC-14523 CORE ONLY: Total Time to Response (TTR) for Opportunities Reporting in SFDC  
    // Added updateCSMLastTouchDate method call to update Account's CSMLastTouchDate
    if(trigger.isAfter){
        if(trigger.isInsert){             
            TaskTriggerHelper.updateOpportunityFirstResponseTime(trigger.new , null);
            TaskTriggerHelper.updateCSMLastTouchDate(trigger.new , null);
        }else if(trigger.isUpdate) {
            TaskTriggerHelper.updateOpportunityFirstResponseTime(trigger.new , trigger.oldMap);
            TaskTriggerHelper.updateCSMLastTouchDate(trigger.new , trigger.oldMap);
        }
    }
    /***
    * Code added as a part of SFDC-17589:
    */
    if(TRIGGER.isBefore){
        if(TRIGGER.isInsert){
        //Call Helper Class for the business logic.
         TaskTriggerHelper.updateActivityTypeReport(TRIGGER.NEW, TRIGGER.OLDMAP);
        }
        if(trigger.isUpdate){
        //Call Helper Class for the business logic.
         TaskTriggerHelper.updateActivityTypeReport(TRIGGER.NEW, TRIGGER.OLDMAP);
        
        }
    }
}