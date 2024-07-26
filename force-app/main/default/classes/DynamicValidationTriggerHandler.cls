public with sharing class DynamicValidationTriggerHandler extends TriggerHandler {


    public override void beforeInsert() {
        System.debug('~~~ before insert trigger fired');
        DynamicValidationRuleEngine.validateRecords(null,  null, Trigger.new, false);
    }
    
    public override void beforeUpdate() {
        DynamicValidationRuleEngine.validateRecords(Trigger.oldMap,   Trigger.newMap, Trigger.new, false);
    }

    public override void beforeDelete() {
        DynamicValidationRuleEngine.validateRecords(null, Trigger.oldMap, Trigger.old, true);
    }

}