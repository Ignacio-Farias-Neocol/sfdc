/**
 * Created by iyeung on 1/30/19.
 */

trigger SubscriptionTrigger on SBQQ__Subscription__c (before insert, before update, before delete, after insert, after update, after delete) {

    new SubscriptionTriggerHandler().run();

}