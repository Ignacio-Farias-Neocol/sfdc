trigger QuoteLineTrigger on SBQQ__QuoteLine__c (before insert, before update, after insert, after update) {
    new QuoteLineTriggerHandler().run();
}