/**
* @author Yuli Fintescu
* @date 2019-9-29
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description implementation of DynamicBusinessRuleAction interface to Assigned Serial trigger
* SFDC-10890 update Business Group on Assigned Serial
*/
public class DynamicBusinessRuleAssignedSerialBefore implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        if (triggerContext.contains('Insert'))
            SetBusinessGroup(records);
    }

    private static void SetBusinessGroup(List <SObject> records) {
        List<Assigned_Serial__c> candidates = new List<Assigned_Serial__c>();
        Set<String> serailIds = new Set<String>();

        for (Assigned_Serial__c s : (List<Assigned_Serial__c>)records){
            if (String.isEmpty(s.Business_Group__c)) {
                candidates.add(s);
                serailIds.add(s.Serial__c);
            }
        }

        if (!candidates.isEmpty()) {
            Map<String, Serial__c> serials = new Map<String, Serial__c>([Select ID, Business_Group__c From Serial__c Where ID in: serailIds]);
            for (Assigned_Serial__c assigned : candidates) {
                Serial__c s = serials.get(assigned.Serial__c);
                assigned.Business_Group__c = s.Business_Group__c;
            }
        }
    }
}