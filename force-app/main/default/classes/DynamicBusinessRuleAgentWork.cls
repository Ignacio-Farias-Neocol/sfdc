/**
* @author Salesforce Services
* @date 10/28/2019
*
* @group DynamicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description Implementation of DynamicBusinessRuleAction interface to update the Case status when someone accepts the case via Omni channel.
* Created as part of SFDC-8141.
*
*/

public with sharing class DynamicBusinessRuleAgentWork implements DynamicBusinessRuleAction{
  /*******************************************************************************************************
  * @description: This method is invoked when the AgentWork status is changed to Opened.
  *               Get all New Technical Support cases using the WorkItemId on AgentWork. Update the status to In Progress.
  * @param trigger.new map
           trigger.old map
           Object records
           Apex JSON Parameter
           Trigger Order (Before or After)
           Trigger Context (Insert/Update/Delete/UnDelete)
  * @return none, the result should be set to the records itself
  */
  public void processRecords(Map<Id,SObject> newRecordMap, 
                             Map<Id,SObject> oldRecordMap,
                             List <SObject> records, 
                             String jsonParameter, 
                             String triggerOrder, 
                             String triggerContext) {

    //Instantiate the log class to capture logs for error conditions
    LogModel log = LogModel.startLog('DynamicBusinessRuleAgentWorkUpdate', 'processRecords');

    //List of Case Ids
    List<Id> workItemIdList = new List<Id>();

    try {
      //Loop through AgentWork records to get a list of Case Ids using the WorkItemId field
      for(SObject obj : records){
        //Cast the sObject instance to Integration Snapshot instance
        AgentWork aw = (AgentWork) obj;
        workItemIdList.add(aw.WorkItemId);
      }

      //Get Technical Support Cases that are in New status
      List<Case> newTechSupportCaseList = [Select Id,
                                                  Status 
                                           From Case 
                                           Where Id in :workItemIdList 
                                           And RecordType.DeveloperName = 'Technical_Support' 
                                           And Status = 'New'];

      //If there are new Technical Support cases that were accepted, change the status to 'In Progress'
      if(newTechSupportCaseList!=null && !newTechSupportCaseList.isEmpty()){
        //Loop through the cases and update the status to 'In Progress'
        for(Case newCase: newTechSupportCaseList){
          newCase.Status = 'In Progress';
          newCase.Take_Ownership_TS_DateTime__c = Datetime.now();
        }

        //Update cases
        update newTechSupportCaseList;
        
      }

    } Catch (Exception e){
      log.addExceptionLog(e);
    }
  }
}