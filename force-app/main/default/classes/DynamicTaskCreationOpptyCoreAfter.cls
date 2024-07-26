/**
* @author Aditya Padhy
* @date 2021-12-17
*
* @group DynamicTaskCreationOpptyCoreAfter
* @group-content
*
* @description:
*   SFDC-16136 CORE ONLY: Completed Task Logged when Next Step field on the Opportunity is saved
*/

public with sharing class DynamicTaskCreationOpptyCoreAfter implements DynamicBusinessRuleAction {

    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
    //system.debug('DynamicTaskCreationOpptyCoreAfter class');
        createTask(records,oldRecordMap);
  }

private void createTask(List<SObject> records, Map<id, SObject> oldRecordMap){
    	LogModel log = LogModel.startLog('DynamicTaskCreationOpptyCoreAfter', 'createTask');
        Map<id, Opportunity> mapOpportunity = new Map<id, Opportunity>();
        List<Task> lstTaskInsert = new List<Task>();        
        try{
            for(Opportunity opp :(List <Opportunity>)records){
                Opportunity oldOpp = (Opportunity)oldRecordMap.get(opp.Id);
                //system.debug('Testing MSP Task');
                /***
                 * Modified as a part of SFDC-17256: START
                 * Added an extra condition as opp.Business_Group__c == 'MSP'.
                 */
                if((oldOpp == NULL && (opp.NextStep != NULL || String.isNotBlank(opp.NextStep)) && (opp.Business_Group__c.equalsIgnoreCase('Core') || opp.Business_Group__c.equalsIgnoreCase('MSP')))
                  || (oldOpp != NULL && opp.NextStep != oldOpp.NextStep && (opp.Business_Group__c.equalsIgnoreCase('Core') || opp.Business_Group__c.equalsIgnoreCase('MSP')))){
                    //system.debug('Successful conditions'); 
                /***
                 * Modified as a part of SFDC-17256: END
                 * Added an extra condition as opp.Business_Group__c == 'MSP'.
                 */
                    mapOpportunity.put(opp.id, opp);
                }
            }
            if(!mapOpportunity.isEmpty()){
                for(ID oppId : mapOpportunity.keySet()){
                    Task tsk = new Task();
                    tsk.WhatId = oppId;
                    tsk.ActivityDate = Date.valueOf(System.today());
                    tsk.type = 'Next Step';
                    tsk.Priority = 'Normal';
                    tsk.Status = 'Completed';
                    tsk.Description = mapOpportunity.get(oppId).NextStep;
                    tsk.Subject =  mapOpportunity.get(oppId).NextStep;
                    /***
                    * Modified as a part of SFDC-17256: START
                    */
                    tsk.Business_Group__c = mapOpportunity.get(oppId).Business_Group__c;
                    /***
                    * Modified as a part of SFDC-17256: END
                    */
                    lstTaskInsert.add(tsk);
                }
                if(!lstTaskInsert.isEmpty()){
                    upsert lstTaskInsert;
                }
            }
        }Catch(Exception e){
           log.addExceptionLog(e);
        }
    }
}