/**
* @author PS
* @date 09/24/2019
*
* @group DynamicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to update the sync status on 
* Order record based on the value sent from BOS/Netsuite. Created as part of SFDC-8116.
*
* @Modification
* SFDC-9397: Changed code to update Order only for BOS and NS Integration Snapshot records

* @Modification
* SFDC-13633: Changed code to include sync Status for ZAB/ECHP 

*/
public with sharing class DynamicBusinessRuleOrderSyncStatus implements DynamicBusinessRuleAction {
  /*******************************************************************************************************
  * @description: Use the Integration Snapshot records created for BOS and Netsuite Order sync 
  *               to update respective status (Success/Failure) on the order record. 
  * @param trigger.new map
  * @return none, the result should be set to the records itself
  */
  public void processRecords(Map<Id,SObject> newRecordMap, 
                              Map<Id,SObject> oldRecordMap,
                              List <SObject> records, 
                              String jsonParameter, 
                              String triggerOrder, 
                              String triggerContext) {

    //Instantiate the log class to capture logs for error conditions
    LogModel log = LogModel.startLog('DynamicBusinessRuleOrderSyncStatus', 'processRecords');

    try {

      /*Using a Map to get the sync status for a given order. 
        The key is the concatenation of order Id and system name and the value is the status*/
      Map <String, Map<String, String>> orderSyncStatusMap = new Map <String, Map<String,String>>();

      //List of Order to be updated with sync status
      List<Order> orderUpdateList = new List<Order>();
      String syncStatus='';
      //Loop through the Integration snapshot records.   
      for (SObject obj : records) {
        //Cast the sObject instance to Integration Snapshot instance
        Integration_Snapshot__c snapshot = (Integration_Snapshot__c) obj;
        
        //Look for Integration Snashot records for Orders*/        
        if (snapshot.Object_Name__c == 'Order' && 
            (snapshot.System_Name__c.equalsIgnoreCase('BOS') || snapshot.System_Name__c.equalsIgnoreCase('Netsuite') || 
             snapshot.System_Name__c.equalsIgnoreCase('ZAB') || snapshot.System_Name__c.equalsIgnoreCase('ECHO')) && //SFDC-13633
            (String.isNotBlank(snapshot.Sync_Status__c) || String.isNotBlank(snapshot.System_Record_Id__c)))
        { 
          /*Check if System Record Id is populated. If it is not populated, mark the sync failed 
            in Order object as true else mark it as false*/
          if(snapshot.System_Name__c.equalsIgnoreCase('BOS') || snapshot.System_Name__c.equalsIgnoreCase('Netsuite'))
          {
           syncStatus = String.isNotBlank(snapshot.System_Record_ID__c) ? 'Success' : 'N/A';
          }
          else if(snapshot.System_Name__c.equalsIgnoreCase('ZAB') || snapshot.System_Name__c.equalsIgnoreCase('ECHO'))
          {
           syncStatus=String.isNotBlank(snapshot.Sync_Status__c) ? snapshot.Sync_Status__c : 'N/A';
          }
          /*Check if this Order Id exists in the Map. If it does, '
          then add the system name and status to the internal map.*/
          if(orderSyncStatusMap.containsKey(snapshot.Record_Id__c)){
            orderSyncStatusMap.get(snapshot.Record_Id__c).put(snapshot.System_Name__c,syncStatus);
          }
          /* If Order Id does not exist in the map, 
          then create a new internal map and add the value*/
          else{
            orderSyncStatusMap.put(snapshot.Record_Id__c, 
                                    new Map<String, String>{snapshot.System_Name__c => syncStatus});
          }
        }
      }

      //Process orders if the map is not empty
      if(orderSyncStatusMap!=null && !orderSyncStatusMap.isEmpty()){
        //Prepare the list of orders to be updated
        for(Id orderId: orderSyncStatusMap.keySet()){
          Order orderToBeUpdated = new Order(Id= orderId);
          for(String systemName : orderSyncStatusMap.get(orderId).keySet()){
            if(systemName.equalsIgnoreCase('BOS')){
              orderToBeUpdated.BOS_Sync_Status__c = orderSyncStatusMap.get(orderId).get(systemName);
            }
            else if(systemName.equalsIgnoreCase('Netsuite')){
              orderToBeUpdated.Netsuite_Sync_Status__c = orderSyncStatusMap.get(orderId).get(systemName);
            }
              //SFDC-13633
            else if(systemName.equalsIgnoreCase('ZAB')){
              orderToBeUpdated.ZAB_Sync_Status__c = orderSyncStatusMap.get(orderId).get(systemName);
            }
            else if(systemName.equalsIgnoreCase('ECHO')){
              orderToBeUpdated.ECHO_Sync_Status__c = orderSyncStatusMap.get(orderId).get(systemName);
            }
          } //END for loop for system names
          //SFDC-9397: Add the order for update only when the sync status is populated
          if(String.isNotBlank(orderToBeUpdated.BOS_Sync_Status__c) || String.isNotBlank(orderToBeUpdated.Netsuite_Sync_Status__c)||
             String.isNotBlank(orderToBeUpdated.ZAB_Sync_Status__c) || String.isNotBlank(orderToBeUpdated.ECHO_Sync_Status__c)){ //SFDC-13633
             orderUpdateList.add(orderToBeUpdated);
          }
        }//END for loop for order Ids
      }

      //Update Order records
      Database.SaveResult[] srList = withoutSharingDML.save(orderUpdateList, false, null);
      // for(Database.SaveResult sr: results){
      //   if(!sr.isSuccess()){
      //     String errorMessage = 'Order Snapshot Sync Error: ';
      //     //Operation failed
      //     for(Database.Error err : sr.getErrors()) {
      //         errorMessage += err.getMessage();
      //     }
      //     log.addErrorLog(errorMessage);
      //   }
      //   else{
      //     log.addLog(sr.getId());
      //   }
      // }     

    } Catch (Exception e){
      log.addExceptionLog(e);
    }
  }
}