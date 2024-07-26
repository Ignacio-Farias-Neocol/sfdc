/**
 * Created by iyeung on 1/30/19.
 */

trigger OrderLineTrigger on OrderItem (before insert, before update, before delete, after insert, after update, after delete) {
		
    	If(TriggerContextVariables.RUN_ORDERLINE_TRIGGER)
    		new OrderItemTriggerHandler().run();
    
}