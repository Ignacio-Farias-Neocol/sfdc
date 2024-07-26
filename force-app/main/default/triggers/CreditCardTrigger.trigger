/**
 * Created by iyeung on 3/19/19.
 */

trigger CreditCardTrigger on Credit_Card__c (before insert, before update, after insert, after update) {
    new CreditCardTriggerHandler().run();
}