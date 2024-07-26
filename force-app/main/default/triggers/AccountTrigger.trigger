trigger AccountTrigger on Account (before insert, before update, after insert, after update, after delete, after undelete) {
    System.debug('###Account trigger:: ' + Trigger.operationType);
    System.debug('###Account trigger.new:: ' +JSON.serialize(Trigger.new));   
    If(TriggerContextVariables.RUN_ACCOUNT_TRIGGER)
        new AccountTriggerHandler().run();
}