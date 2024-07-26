/**
* Trigger handler for Lead Object
*
* @Author Htut
* @Date 2018/12/01
* @group Trigger
* @description  even though the trigger method is empty, the fact that this class extend the trigger handler means that additional logic e.g. busienssAction can be executed off this object
*/
public with sharing class LeadTriggerHandler extends TriggerHandler {
    public override void beforeInsert() {
        // placeHolder(Trigger.new);
    }

    public override void beforeUpdate() {
        // placeHolder((Map<Id,Account>)Trigger.oldMap, Trigger.new);
    }

    public override void afterDelete() {
    }

    public override void afterInsert() {
    }

    public override void afterUpdate() {
    }


}