/**
* @author HZ
* @date 2019
*
* @group DynmaicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to re-trigger default lead assignment rules
*   2019-10-02 : Initial creation
*/

public with sharing class DynamicBusinessRuleLeadAssgn implements DynamicBusinessRuleAction {

    /*******************************************************************************************************
    * @description  re-trigger default lead assignment rules
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext){

        System.debug('~#~~~~: starting: ' +  'DynamicBusinessRuleLeadAssgn');
        if (records == null || records.size() == 0 ){
            return;
        }

        try {
            String objectName =  records[0].getSObjectType().getDescribe().getName();

            if (objectName == 'Lead') {

                //Create DMLOptions to set the assignment rule
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.assignmentRuleHeader.useDefaultRule= true;

                //Fetech trigger context Ids
                Set <Id> ids = new Set <Id>();
                for (SObject obj : records) {
                    ids.add((Id)obj.get('Id'));
                }

                //Fetch Default_Lead_Queue and Marketo Sync/Legacy Load User Ids
                Set <Id> ownerIds = new Set <Id>();
                Id defLeadQueue = [select Id from Group where DeveloperName = 'Default_Lead_Queue' LIMIT 1].Id;
                ownerIds.add(defLeadQueue);
                for(User usrs: [select Id from User where username like 'marketo%' or username like 'legacy%']){
                    ownerIds.add(usrs.Id);
                }

                //Prepare the query
                String query = 'Select Id from Lead where Id in :ids and OwnerId in :ownerIds';

                //Execute the query
                List<SObject> recordsToBeAssigned = Database.query(query);

                //Update records to execute assignment rule
                if (recordsToBeAssigned.size() > 0) {
                    Database.SaveResult[] srList = Database.update(recordsToBeAssigned, dmo);
                }
            }

        } Catch (Exception e){
            System.debug('processRecords failed: ' + e);
        }
    }
}