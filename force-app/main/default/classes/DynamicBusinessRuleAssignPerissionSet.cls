/**
* @author Adiya
* @date 2022
* @group DynmaicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
* @description implementation of DynamicBusinessRuleAction interface to assign permission sets for community users
*/
public with sharing class DynamicBusinessRuleAssignPerissionSet implements DynamicBusinessRuleAction {


    /*******************************************************************************************************
    * @description assign partner/customer permission sets based on Contact's Account Type
    * @param trigger.new map
    * @return none
    * @example
    */
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap,List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        System.debug('inside processRecords...'+records);
        AssignPermissionSetForCommunityUsers.prepareUserIdPermissionSetMap(records);
    }

}