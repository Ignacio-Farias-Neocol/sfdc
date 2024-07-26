/**
 * Created by pshetty on 2019-11-27
 * Added as part of SFDC-8683
 * A trigger is required for the business action rule
 */
trigger HotListTrigger on Hot_List__c (after insert, after update) {
    new HotListTriggerHandler().run();
}