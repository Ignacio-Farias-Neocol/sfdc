/**
* @author        Rajesh Wani
* @date          2024-02-02
* @description   Class for JumbledSerialTrackingTrigger,JumbledSerialTrackingTrigger 
* @group         To populate Serial and Contract End date
*
*/
trigger JumbledSerialTrackingTrigger on Jumbled_Serial_Tracking__c (before insert) {
    
    JumbledSerialTrackingTriggerClass.afterInsertAction(trigger.new);
   
}