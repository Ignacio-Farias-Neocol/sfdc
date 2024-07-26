public with sharing class DynamicBusinessRuleActionTriggerHandler extends TriggerHandler {

    
    public override void beforeInsert() {
        System.debug('----- business action after insert  ------ ');
        DynamicBusinessRuleActionRuleEngine.validateAndExecuteRecords(null, null, Trigger.new,  DynamicBusinessRuleActionRuleEngine.CONTEXT_TYPE_BULK_INSERT,   DynamicBusinessRuleActionRuleEngine.TRIGGER_ORDER_PRE);
    }

    public override void beforeUpdate() {
        DynamicBusinessRuleActionRuleEngine.validateAndExecuteRecords(Trigger.newMap,  Trigger.oldMap, Trigger.new, DynamicBusinessRuleActionRuleEngine.CONTEXT_TYPE_BULK_UPDATE,   DynamicBusinessRuleActionRuleEngine.TRIGGER_ORDER_PRE );
    }


    public override void afterInsert() {

        System.debug('----- business action after insert  ------ ');
        DynamicBusinessRuleActionRuleEngine.validateAndExecuteRecords(Trigger.newMap, null, Trigger.new,  DynamicBusinessRuleActionRuleEngine.CONTEXT_TYPE_BULK_INSERT,   DynamicBusinessRuleActionRuleEngine.TRIGGER_ORDER_POST);
    }

    public override void afterUpdate() {
        DynamicBusinessRuleActionRuleEngine.validateAndExecuteRecords(Trigger.newMap, Trigger.oldMap,  Trigger.new, DynamicBusinessRuleActionRuleEngine.CONTEXT_TYPE_BULK_UPDATE,   DynamicBusinessRuleActionRuleEngine.TRIGGER_ORDER_POST );
    }

    public override void afterDelete() {
        DynamicBusinessRuleActionRuleEngine.validateAndExecuteRecords(null, Trigger.oldMap,   Trigger.old, DynamicBusinessRuleActionRuleEngine.CONTEXT_TYPE_BULK_DELETE,   DynamicBusinessRuleActionRuleEngine.TRIGGER_ORDER_POST);
    }

}