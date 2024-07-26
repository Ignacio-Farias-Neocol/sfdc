trigger AssignedSerialTrigger on Assigned_Serial__c (before insert, before update, after insert, after update, after delete) {

    new AssignedSerialTriggerHandler().run();

}