/**
* Trigger handler for Contact Object
*
* @Author Ivan Yeung
* @Date 2018/10/15
* @group Trigger
*/
public with sharing class ContactTriggerHandler extends TriggerHandler {

    public override void beforeInsert() {
        // placeHolder(Trigger.new);
	}

	public override void beforeUpdate() {
		// placeHolder((Map<Id,Account>)Trigger.oldMap, Trigger.new);
	}

	public override void afterDelete() {
		// 11/30/2018- move to DynamicBusinessRuleAction framework and control by Business_Rule_Action__mdt
		// PlatformEventHelper.publishObject( PlatformEventHelper.EVENT_TYPE_DELETE,  Trigger.old);
	}

    public override void afterInsert() {
		// 11/30/2018- move to DynamicBusinessRuleAction framework and control by Business_Rule_Action__mdt
        // PlatformEventHelper.publishObject( PlatformEventHelper.EVENT_TYPE_INSERT,  Trigger.new);
	}

    public override void afterUpdate() {
        ContactModel.afterUpdate();
		// 11/30/2018- move to DynamicBusinessRuleAction framework and control by Business_Rule_Action__mdt
        // PlatformEventHelper.publishObject( PlatformEventHelper.EVENT_TYPE_UPDATE, Trigger.new);
	}

}