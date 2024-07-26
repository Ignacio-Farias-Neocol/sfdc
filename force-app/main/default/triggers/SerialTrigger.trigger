trigger SerialTrigger on Serial__c (after insert, after update, before insert, before update) {
	new SerialTriggerHandler().run();
}