/**
 * Created by iyeung on 12/19/18.
 */

trigger AddressTrigger on Address__c (before insert, before update, before delete, after insert, after update) {

    new AddressTriggerHandler().run();

}