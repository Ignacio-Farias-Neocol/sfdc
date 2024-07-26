trigger ExternalIDHistoryTrigger on External_ID_History__c (before insert, before update, after insert, after update, after delete, after undelete)  {

    new ExternalIDHistoryTriggerHandler().run();
    
}