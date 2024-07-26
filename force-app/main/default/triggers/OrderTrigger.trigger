trigger OrderTrigger on Order (before insert, before update, after insert, after update, after delete) {
    System.debug('#### order trigger fired'); 
    if(TriggerContextVariables.RUN_ORDER_TRIGGER)
    	new OrderTriggerHandler().run();
}