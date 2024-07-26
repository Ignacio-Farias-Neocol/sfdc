/**
 * Created by rmigwani on 5/18/22.
 */

trigger AssetTrigger on Asset (before insert, before update, before delete, after insert, after update, after delete) {

    new AssetTriggerHandler().run();

}