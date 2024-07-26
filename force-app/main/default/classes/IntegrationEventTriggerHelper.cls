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
public with sharing class IntegrationEventTriggerHelper {

    /***************************
     * Method Description: 
     * 
     * 
     * @Param: List<Integration_Event__e>
     * @return void
     */
    public static void createAppLogRecord (List<Integration_Event__e> newList){
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('IntegrationEventTriggerHelper', 'createAppLogRecord', LogModel.LOG_CATEGORY_APEX);
        system.debug('Method createAppLogRecord');
        List<AppLog__c> lstAppLog = new List<AppLog__c>();
        List<AppLog__c> lstAppLogOrder = new List<AppLog__c>();
        try{
            for(Integration_Event__e intgE : newList){
                /*****
                * This code snippet will create an AppLog record if Integration Event gets published with event type as "JUD-UPDATE".
                * This is a part of the SFDC-16853 & SFDC-16060: Judge API functionality. 
                */
               if(intgE.Event_Type__c.equalsIgnoreCase('JUD-UPDATE') && intgE.Object_Name__c.equalsIgnoreCase('Case')){
				   AppLog__c appl = new AppLog__c();
				   appl.apexClassName__c = 'DynamicBusinessRuleAPIForJudge';
				   appl.message__c = intgE.Event_Type__c;
				   appl.Records__c = intgE.Object_Payload__c != NULL ? intgE.Object_Payload__c : '';
				   appl.startTime__c = system.now();
				   appl.LogCategory__c = 'Asynchronous Process';
                   lstAppLog.add(appl);
			   }else if((intgE.Event_Type__c.equalsIgnoreCase('UPDATE') || intgE.Event_Type__c.equalsIgnoreCase('INSERT')) && intgE.Object_Name__c.equalsIgnoreCase('Case')){
				   //Need to Add more code.
                   AppLog__c appl = new AppLog__c();
				   appl.apexClassName__c = 'DynamicBusinessRuleCaseJiraIntg';
				   appl.message__c = intgE.Event_Type__c;
				   appl.Records__c = intgE.Object_Payload__c != NULL ? intgE.Object_Payload__c : '';
				   appl.startTime__c = system.now();
				   appl.LogCategory__c = 'Asynchronous Process';
                   lstAppLog.add(appl);
			   }
               /*****
                * This code snippet will create an AppLog record if Integration Event gets published with event type as "Void Order".
                * This is a part of the SFDC-15817: Void Order functionality. 
                */
               if(intgE.Event_Type__c.equalsIgnoreCase('VOID_ORDER') && intgE.Object_Name__c.equalsIgnoreCase('Order')){
                    AppLog__c applO = new AppLog__c();
                    applO.apexClassName__c = 'VoidOrderController';
                    applO.message__c = intgE.Event_Type__c;
                    //appl.Records__c = intgE.Object_Payload__c != NULL ? intgE.Object_Payload__c : '';
                    applO.startTime__c = system.now();
                    applO.LogCategory__c = 'Asynchronous Process';
                    lstAppLogOrder.add(applO);
               }
            }
            system.debug('lstAppLog is:' +lstAppLog);
            if(!lstAppLog.isEmpty()){
                insert lstAppLog;
            }
            system.debug('lstAppLogOrder is:' +lstAppLogOrder);
            if(!lstAppLogOrder.isEmpty()){
                insert lstAppLogOrder;
            }
            
        }Catch(Exception e){
            log.addExceptionLog(e);
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    }
    //New Method added as a part of SFDC-17122: START
    /***************************
     * Method Description: 
     * *********** This method contains a logic which was handled via a PB earlier. 
     *  The name of the PB is "Assigned Serial for Bucket Change".
     *  Method gets invoked after an Integration Event gets published and if the related object is "Order".
     *  If the Order record is a non core Order (Business Group = Barracuda MSP), then create assigned serials.
     *  For creating Assigned serials, this method internally invokes a queueable job.
     * ***********
     * 
     * @Param: List<Integration_Event__e>
     * @return void
     */
    public static void createAssignedSerialForMSPOrder(List<Integration_Event__e> newList){
        System.debug('Method createAssignedSerialForMSPOrder');
        LogModel log = LogModel.startLog('IntegrationEventTriggerHelper', 'createAssignedSerialForMSPOrder', LogModel.LOG_CATEGORY_APEX);
        Set<String> recordIDs = new Set<String>();
        List<Order> lstOrder = new List<Order>();
        List<ID> OrderIDList = new List<ID>();
        try{
            for(Integration_Event__e intgE : newList){
                if(intgE.Object_Name__c.equalsIgnoreCase('Order') && intgE.Record_ID__c != NULL){
                    recordIDs.add(intgE.Record_ID__c);
                }
            }
            System.debug('recordIDs is:' +recordIDs);
            if(!recordIDs.isEmpty()){
                lstOrder = [select id, Quote_Business_Group__c from Order where id in :recordIDs];
                System.debug('lstOrder is:' +lstOrder);
                if(!lstOrder.isEmpty()){
                    for(Order ord : lstOrder){
                        if(ord.Quote_Business_Group__c.equalsIgnoreCase('Barracuda MSP')){
                            OrderIDList.add(ord.id);
                        }
                    }
                    System.debug('OrderIDList is:' +OrderIDList);
                    //Call queueable batch: START
                    ID jobID = System.enqueueJob(new CreateAssignedSerialMSPOrder_Queueable(OrderIDList));
                }
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    }
    //New Method added as a part of SFDC-17122: END
}