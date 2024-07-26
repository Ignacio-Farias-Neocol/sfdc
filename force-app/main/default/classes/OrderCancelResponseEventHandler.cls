/**
* @author Dilowar Hussain
* @date 2022-03-24
*
* @description 
* This Apex Class gets invoked by Platform event subscriber trigger. The name of the plateform event is 
* "Order_Cancellation_Response__e". 
*
* 
* This has been added as a part of SFDC-15817
*/
public with sharing class OrderCancelResponseEventHandler extends TriggerHandler{
    public OrderCancelResponseEventHandler() {

    }
    /***************************
     * Method Description: 
     * Gets invoked post a record gets inserted into the platform event, "Order_Cancellation_Response__e".
     * 
     * @Param: 
     * @return void
     */
    public override void afterInsert(){
        System.debug('##OrderCancelResponseEventHandler afterInsert');
		OrderCancelResponseEventHelper.createLogsForOrder(Trigger.new);
	}
}