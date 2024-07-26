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
*/public with sharing class OrderCancelResponseEventHelper {
    public OrderCancelResponseEventHelper() {

    }
    /***************************
     * Method Description: 
     * 
     * 
     * @Param: List<Order_Cancellation_Response__e>
     * @return void1
     */
    public static void createLogsForOrder(List<Order_Cancellation_Response__e> newList){
        LogModel log = LogModel.startLog('OrderCancelResponseEventHelper', 'createLogsForOrder', LogModel.LOG_CATEGORY_APEX);
        system.debug('Method createLogsForOrder');
        List<AppLog__c> lstAppLog = new List<AppLog__c>();
        List<Integration_Snapshot__c> snapShotsBOS = new List<Integration_Snapshot__c>();
        List<Integration_Snapshot__c> snapShotsNTST = new List<Integration_Snapshot__c>();
        Set<String> orderIDSuc = new Set<String>();
        List<Order> lstOrderSuc = new List<Order>();
        List<Order> lstOrderSucUpdate = new List<Order>();
        List<Order> lstOrderSucUpdate02 = new List<Order>();
        Set<String> orderIDFail = new Set<String>();
        List<Order> lstOrderFail = new List<Order>();
        List<Order> lstOrderFailUpdate = new List<Order>();
        try{
            for(Order_Cancellation_Response__e ordCalE : newList){
                /*****
                * This code snippet will create an AppLog record if Event gets published 
                */
                AppLog__c appl = new AppLog__c();
				appl.apexClassName__c = 'OrderCalResEventTrigger';
				appl.message__c = ordCalE.OrderId__c != NULL ? 'Order_'+ordCalE.OrderId__c : '';
				appl.Records__c = ordCalE.Transaction_Id__c != NULL ? 'Order_Transaction_ID_'+ordCalE.Transaction_Id__c : '';
				appl.startTime__c = system.now();
				appl.LogCategory__c = 'Asynchronous Process';
                lstAppLog.add(appl);
                /*****
                * This code snippet will create an Integration Snapshot record if Event gets published.
                * This code is for BOS response.
                */
                if(ordCalE.BOS_Cancellation_Status__c != NULL && ordCalE.BOS_Cancellation_Status__c != ''){
                    Integration_Snapshot__c snapshotBOS = new Integration_Snapshot__c();
                    snapshotBOS.External_ID__c = ordCalE.OrderId__c != NULL ? 'Order_SF_Platform_BOS'+ordCalE.OrderId__c : '';
                    snapshotBOS.Integration_App__c = 'ORDER CANCELLATION BOS';
                    snapshotBOS.System_Name__c = 'Salesforce BOS ORDER CANCELLATION response';
                    if(ordCalE.BOS_Cancellation_Status__c.equalsIgnoreCase('TRUE')){
                        snapshotBOS.Sync_Status__c = 'SUCCESS';
                        //Store the Order IDs if BOS Cancellation status is 'TRUE'.
                        orderIDSuc.add(String.valueOf(ordCalE.OrderId__c));
                    }else{
                        snapshotBOS.Sync_Status__c = 'FAILED';
                        //Store the Order IDs if BOS Cancellation status is 'FALSE'.
                        orderIDFail.add(String.valueOf(ordCalE.OrderId__c));
                    }
                    snapshotBOS.Record_ID__c = ordCalE.OrderId__c != NULL ? ordCalE.OrderId__c : '';
                    snapshotBOS.System_Record_ID__c = ordCalE.OrderId__c != NULL ? ordCalE.OrderId__c : '';
                    snapshotBOS.Object_Name__c = 'Order';
                    snapshotBOS.Message_Payload__c = ordCalE.BOS_Cancellation_message__c != NULL ? ordCalE.BOS_Cancellation_message__c : '';
                    snapShotsBOS.add(snapshotBOS);
                }
                /*****
                * This code snippet will create an Integration Snapshot record if Event gets published.
                * This code is for Netsuite response.
                */
                if(ordCalE.NETSUITE_Cancellation_Status__c != NULL && ordCalE.NETSUITE_Cancellation_Status__c != ''){
                    Integration_Snapshot__c snapshotNT = new Integration_Snapshot__c();
                    snapshotNT.External_ID__c = ordCalE.OrderId__c != NULL ? 'Order_SF_Platform_NETSUITE'+ordCalE.OrderId__c : '';
                    snapshotNT.Integration_App__c = 'ORDER CANCELLATION Netsuite';
                    snapshotNT.System_Name__c = 'Salesforce NTST ORDER CANCELLATION response';
                    if(ordCalE.NETSUITE_Cancellation_Status__c.equalsIgnoreCase('TRUE')){
                        snapshotNT.Sync_Status__c = 'SUCCESS';
                    }else{
                        snapshotNT.Sync_Status__c = 'FAILED'; 
                    }
                    snapshotNT.Record_ID__c = ordCalE.OrderId__c != NULL ? ordCalE.OrderId__c : '';
                    snapshotNT.System_Record_ID__c = ordCalE.OrderId__c != NULL ? ordCalE.OrderId__c : '';
                    snapshotNT.Object_Name__c = 'Order';
                    snapshotNT.Message_Payload__c = ordCalE.NETSUITE_Cancellation_message__c != NULL ? ordCalE.NETSUITE_Cancellation_message__c : '';
                    snapShotsNTST.add(snapshotNT);
                }
            }
            /****
             * Logic to update the Order record status to "Cancelled".
             */
            System.debug('orderIDSuc are:' +orderIDSuc);
            if(!orderIDSuc.isEmpty()){
                lstOrderSuc = [select id, Status, SBQQ__Contracted__c from Order where id in :orderIDSuc];
                System.debug('lstOrderSuc is:' +lstOrderSuc);
                list<OrderItem> lstorditem = [Select id,SBQQ__Activated__c,SBQQ__Contracted__c from OrderItem where orderId in :orderIDSuc];
                list<OrderItem> lstorditemtoupd = new list<OrderItem>();
                if(lstorditem.size() >0){
                    for(OrderItem od:lstorditem){
                        //OrderItem oi = new OrderItem();
                        //oi.Id = od.id;
                        od.SBQQ__Activated__c = false;
                        od.SBQQ__Contracted__c = false;
                        lstorditemtoupd.add(od);
                    }
                }
                if(!lstorditemtoupd.isEmpty()){
                    update lstorditemtoupd;
                }
                for(Order ordS: lstOrderSuc){
                    //ordS.Status = 'Cancelled';
                    ordS.SBQQ__Contracted__c = FALSE;
                    //ordS.Pending_Cancellation__c = FALSE;
                    lstOrderSucUpdate.add(ordS);
                }
                System.debug('lstOrderSucUpdate is:' +lstOrderSucUpdate);
                if(!lstOrderSucUpdate.isEmpty()){
                    update lstOrderSucUpdate;
                    for(Order ord02: lstOrderSucUpdate){
                        //ord02.Status = 'Cancelled';
                        ord02.Is_Order_Cancelled__c = TRUE;
                        ord02.Pending_Cancellation__c = FALSE;
						ord02.Do_not_lock_Order_record__c = FALSE;
                        lstOrderSucUpdate02.add(ord02);
                    }if(!lstOrderSucUpdate02.isEmpty()){
                        update lstOrderSucUpdate02;
                    }
                }
            }
            /****
             * Logic to update the Order record status to "Cancelled".
             */
            System.debug('orderIDFail are:' +orderIDFail);
            if(!orderIDFail.isEmpty()){
                lstOrderFail = [select id, Status from Order where id in :orderIDFail];
                System.debug('lstOrderSuc is:' +lstOrderFail);
                for(Order ordF: lstOrderFail){
                    //ordF.Status = 'Placed';
                    ordF.Pending_Cancellation__c = FALSE;
                    lstOrderFailUpdate.add(ordF);
                }
                System.debug('lstOrderFailUpdate is:' +lstOrderFailUpdate);
                if(!lstOrderFailUpdate.isEmpty()){
                    update lstOrderFailUpdate;
                }
            }
            System.debug('lstAppLog is:' +lstAppLog);
            if(!lstAppLog.isEmpty()){
                insert lstAppLog;
            }
            System.debug('snapShotsBOS is:' +snapShotsBOS);
            if(!snapShotsBOS.isEmpty()){
                upsert snapShotsBOS;
            }
            System.debug('snapShotsNTST is:' +snapShotsNTST);
            if(!snapShotsNTST.isEmpty()){
                upsert snapShotsNTST;
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    }
}