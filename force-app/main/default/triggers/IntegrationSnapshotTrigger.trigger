/**
 * Created by iyeung on 2019-06-13.
 */

trigger IntegrationSnapshotTrigger on Integration_Snapshot__c (after insert, after update, before insert, before update) {
    new IntegrationSnapshotTriggerHandler().run();
}