trigger CaseTrigger on Case (before insert, before update, after insert, after update, after delete) {
    System.debug('###Case trigger:: ' + Trigger.operationType);
    System.debug('###Case trigger.new:: ' +JSON.serialize(Trigger.new));    
    If(TriggerContextVariables.RUN_CASE_TRIGGER)
    	new CaseTriggerHandler().run();
}