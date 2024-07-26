/**
 * Created by iyeung on 11/21/18.
 */

public interface DynamicBusinessRuleAction {

    void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext);
    
}