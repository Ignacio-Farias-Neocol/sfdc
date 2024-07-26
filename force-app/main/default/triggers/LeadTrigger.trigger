/**
 * Created by iyeung on 12/4/18.
 */

trigger LeadTrigger on Lead (before insert, before update, before delete, after insert, after update, after delete) {

    new LeadTriggerHandler().run();

}