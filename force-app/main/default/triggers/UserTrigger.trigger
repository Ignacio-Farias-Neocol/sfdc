trigger UserTrigger on User (before insert, before update, after insert, after update, after delete) {

    new UserTriggerHandler().run();
    //UserTriggerHandler.afterInsert(trigger.new);
}