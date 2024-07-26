/**
* @author Dilowar Hussain
* @date 2022-06-03
*
* @description 
* This queueable job gets invoked from IntegrationEventTriggerHelper.
*
* 
* This has been added as a part of SFDC-17122
*/
public with sharing class CreateAssignedSerialMSPOrder_Queueable implements queueable{
    /****
     * Variable to hold the Order ID's.
     */
    public List<ID> orderIDList; 
    /**
     * Cosntructor
     */
    public CreateAssignedSerialMSPOrder_Queueable(List<ID> orderIdList) {
        this.orderIDList = orderIDList;
    }
    /***********
     * Method: Execute
     * 
     * @Param: QueueableContext context
     * @Return: none
     */
    public void execute(QueueableContext context){
        if(!orderIDList.isEmpty()){
            System.debug('Call createAssignedSerial method');
            MassAmendLineItemsController.createAssignedSerial(orderIDList);
        }
    }
}