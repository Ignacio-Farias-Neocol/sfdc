/**
* @author IY
* @date 2018
*
* @group DynmaicBusinessRuleAction
*
* @description implementation of DynamicBusinessRuleAction interface to interface with web integration:
*            Deal reg
*            Account update
*            Contact update
*/
public with sharing class DynamicBusinessRuleAccountWeb implements DynamicBusinessRuleAction {

    /*******************************************************************************************************
     * @description handle either the contact or account changes
     * @param trigger.new map
     * @return none, the result should be set to the records itself
     * @example
     */
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {

        System.debug('~#~~~~: starting: ' +  'DynamicBusinessRuleAccountWeb');
        if(!(System.isBatch() || System.isFuture()))
        {
            PartnerPortalUpdateHelper.processRecordChanges( oldRecordMap, records );
        }

    }


}