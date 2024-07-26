/**
* @author Abi A
* @date 2018/04/11
*
* @group DynamicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to rollup assigned serial
* SFDC-14408: Added logic to add qty in use in Assigned Serial and update Subscription
*/
public with sharing class DynamicBusinessRuleAssignedSerialRollup implements DynamicBusinessRuleAction {


    /*******************************************************************************************************
    * @description rollup to subsription the assigned serial number 
    * @param trigger.new map
    * @return none, the result should be set to subscription object
    * @example
    */
    public void processRecords(Map<Id,SObject> newRecordMap, 
                                Map<Id,SObject> oldRecordMap,
                                List <SObject> records, 
                                String jsonParameter, 
                                String triggerOrder, 
                                String triggerContext) {
  
      //Instantiate the log class to capture logs for error conditions

      // SFDC-17456 // Logging in this class is being suspended temporarily , as the logging here is contributing to millions of logs eating storage space
     // LogModel log = LogModel.startLog('DynamicBusinessRuleAssignedSerialRollup', 'processRecords', LogModel.LOG_CATEGORY_APEX);
      try{
        /** Roll up logic 
         * Loop through assigned serials passed to this method
         * Prepare a map of Sub ID and Sub object with Serial number and Quantity in Use field. Include new and old values of Sub
         * Get all active assigned serials for subs in the map.
         * Loop through these assigned serials and prepare comma separated list of Serial numbers in these assigned serials. 
         * Add quantity in use and update the summed value on Subscription
         * Update subs.
        */
        
        //Map of Subscription Id and Subscription ID object with comma separated serial number values
        Map<Id, SBQQ__Subscription__c> subscriptionMap = new Map<Id, SBQQ__Subscription__c>();
  
        for (SObject rec: records){
          Assigned_Serial__c currentASerial = (Assigned_Serial__c)rec;
  
          //Insert or Delete context
          if(triggerContext.contains('Insert') || triggerContext.contains('Delete')){
            //Add current value of the subscription ID
            if(currentASerial.Subscription__c!=null && 
                !subscriptionMap.containsKey(currentASerial.Subscription__c) && 
                String.isNotBlank(currentASerial.External_Id__c)){
                subscriptionMap.put(currentASerial.Subscription__c, 
                                    new SBQQ__Subscription__c(Id=currentASerial.Subscription__c, 
                                                  SBCF_Serial_Number__c = '',
                                                  Quantity_in_Use__c = 0));
            }
          }
  
          //Update context
          if(triggerContext.contains('Update')){
            //get old serial
            Assigned_Serial__c oldASerial     = oldRecordMap != null && oldRecordMap.size()>0? (Assigned_Serial__c)oldRecordMap.get(currentASerial.Id) : null;
            //Add current and old value of the subscription ID on the AS
            if(oldASerial != null && 
              (currentASerial.Subscription__c != oldASerial.Subscription__c || 
              currentAserial.Status__c != oldASerial.Status__c || 
              currentASerial.Qty_in_Use__c!= oldASerial.Qty_in_Use__c || 
              currentASerial.External_Id__c!= oldASerial.External_Id__c) && LegacySerialDataFixBatch.BypassQuable==FALSE){
              //Add current value
              if(!subscriptionMap.containsKey(currentASerial.Subscription__c)){
              subscriptionMap.put(currentASerial.Subscription__c, 
              new SBQQ__Subscription__c(Id=currentASerial.Subscription__c, 
                                        SBCF_Serial_Number__c = '',
                                        Quantity_in_Use__c = 0));
              }
  
              //Add old value
              if(!subscriptionMap.containsKey(oldASerial.Subscription__c)){
              subscriptionMap.put(oldASerial.Subscription__c, 
              new SBQQ__Subscription__c(Id=oldASerial.Subscription__c, 
                                        SBCF_Serial_Number__c = '',
                                        Quantity_in_Use__c = 0));
              }
            }
          }
        }
  
        //Eligible Subs
        //log.addLog('Eligible Subs: ' + subscriptionMap?.size());
  
        for(SBQQ__Subscription__c currentSub: [SELECT Id,
                                (SELECT Serial__r.Serial_Number__c,
                                        Qty_in_Use__c 
                                FROM Assigned_Serials__r 
                                WHERE Status__c = 'Active' 
                                AND Serial__r.Status__c = 'Active' 
                                AND External_Id__c !=null) 
                            FROM SBQQ__Subscription__c 
                            WHERE Id in :subscriptionMap.keyset()]){
          //Reset Serial Number and Quantity in Use
          String serialNumbers = '';
          Decimal quantityInUse = 0;
  
          //loop through assigned serials to update sub fields
          for(Assigned_Serial__c aserial: currentSub.Assigned_Serials__r){
            if(aserial.Qty_in_Use__c!=null){
              //Set quantity in use
              quantityInUse += aserial.Qty_in_Use__c;
            }
  
            //Set serial number
            if(!serialNumbers.contains(aserial.Serial__r.Serial_Number__c)){
              if(String.isNotBlank(serialNumbers)){
                serialNumbers += ',';
              }
              serialNumbers += aserial.Serial__r.Serial_Number__c;
            }
  
            subscriptionMap.get(currentSub.Id).SBCF_Serial_Number__c = serialNumbers;
            subscriptionMap.get(currentSub.Id).Quantity_in_Use__c = quantityInUse;
          }
        }
  
        //Update Subscriptions
        if(subscriptionMap!=null && !subscriptionMap.values().isEmpty() && LegacySerialDataFixBatch.BypassQuable==FALSE) {
          Database.SaveResult[] srList = Database.update(subscriptionMap.values());
          for(Database.SaveResult sr: srList){
            if(!sr.isSuccess()){
              String errorMessage = '';
              for(Database.Error error: sr.getErrors()){
                errorMessage += error.getMessage();
              }
             // log.addLog(errorMessage);
            }
          }
        }
  
        //End log
       // log.endLog('End of Roll Up log');
      }
      catch(Exception ex){
       // log.addExceptionLog(ex);
      }
  
    }
  }