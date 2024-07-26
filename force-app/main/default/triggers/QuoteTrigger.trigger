trigger QuoteTrigger on SBQQ__Quote__c (before insert, before update) {
	new QuoteTriggerHandler().run();
}