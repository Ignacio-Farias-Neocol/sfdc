/**
* @author Dilowar Hussain
* @date 2022-03-03
*
* @description 
* This Apex Class gets invoked by Platform event subscriber trigger. The name of the plateform event is 
* "Integration_Event__e". 
*
* 
* This has been added as a part of SFDC-16060
*/
public with sharing class IntegrationEventTriggerHandler extends TriggerHandler {
    public IntegrationEventTriggerHandler() {

    }
    /***************************
     * Method Description: 
     * Gets invoked post a record gets inserted into the platform event, "Integration_Event__e".
     * 
     * @Param: 
     * @return void
     */
    public override void afterInsert() {
        System.debug('##IntegrationEventTriggerHandler afterInsert');
		IntegrationEventTriggerHelper.createAppLogRecord(Trigger.new);
        IntegrationEventTriggerHelper.createAssignedSerialForMSPOrder(Trigger.new);
	}
}