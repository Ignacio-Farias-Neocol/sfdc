/**
 * @description       : 
 * @author            : Ignacio F.
 * @group             : 
 * @last modified on  : 07-01-2024
 * @last modified by  : Ignacio F.
**/
trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update, after delete) {
    if(TriggerContextVariables.RUN_OPPORTUNITY_TRIGGER)
        new OpportunityTriggerHandler().run();  
}