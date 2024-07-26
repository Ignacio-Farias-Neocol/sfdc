/**
* @author IY
* @date 2018
*
* @group DynmaicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to assign case
*/
public with sharing class DynamicBusinessRuleCaseAssignment implements DynamicBusinessRuleAction {


    /*******************************************************************************************************
    * @description set the contact lookup field based upon the web form fields
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap,
            List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {

        List <Id> ids = new List <Id>();
        for (SObject o: records){
            ids.add( (Id) o.get('Id'));
        }
        CaseModel.assignCase(ids);
    }

}