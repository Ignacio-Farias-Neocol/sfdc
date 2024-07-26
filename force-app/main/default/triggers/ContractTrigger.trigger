trigger ContractTrigger on Contract (before insert, before update, after insert, after update, after delete) {
	new ContractTriggerHandler().run();
}