trigger ComplianceLogTrigger on Compliance_Log__c (after insert, after update) {

    new ComplianceLogTriggerHandler().run();
}