/**
* @author Salesforce Services
* @date 02/14/2021
* 
* @group Business Rule Action apex class
*
* @description SFDC-14048: Class used to implement logic as part of OrderItem after trigger
* @description SFDC-15874: Updated the Logic for Send Sub Cert Button On Order
*
*/
public with sharing class DynamicBusinessRuleOrderItemAfter implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, 
                               Map<Id,SObject> oldRecordMap, 
                               List <SObject> records, 
                               String jsonParameter, 
                               String triggerOrder, 
                               String triggerContext) {
      if(triggerContext.contains('Update')) {
        //Identify orders that are eligible for the sub cert email
        updateOrderForCertEmail(records, oldRecordMap); 
      }
    }
  
    private void updateOrderForCertEmail(List <SObject> records, Map<Id,SObject> oldRecordMap){
  
      //Log Instance 
    //  LogModel log = LogModel.startLog('DynamicBusinessRuleOrderItemAfter','updateOrderForCertEmail');
  
      /*Loop through records to check if the SBCF_Serial_Number__c has been updated from blank value to some value.
        If this field changed, then add the order to the list of Orders to be checked for sending email 
        For the orders identified in the previous step, get the list of order items that have need serial = true.
        For these order items check if Serial is populated.
        If serial is not populated even for 1 order item then order is not qualified for email*/
  
      //Set of Order Ids that need to be evaluated
      Set<Id> orderIdSet = new Set<Id>();
      List<Id> orderIdList = new List<Id>();
  
      //List of orders to be updated
      List<Id> ordersToBeUpdated = new List<Id>();
      
      for (OrderItem oi : (List<OrderItem>)records) {
        //Get the old version of the record
        OrderItem oldOI = (OrderItem)oldRecordMap.get(oi.Id);
  
        if (String.isNotBlank(oi.SBCF_Serial_Number__c)) {
          orderIdSet.add(oi.OrderId);
          orderIdList.add(oi.OrderId);
        }
      } //END OF ORDERITEM LOOP      
  
      if(orderIdSet!=null && !orderIdSet.isEmpty()){
  
        sendSubCerts(orderIdList,true);
      }      
    }
   
    @AuraEnabled
    public static DynamicBusinessRuleOrderItemAfter.sendSubCertResult sendSubCerts(List<Id> orderIdList,Boolean isFromTrigger){
      
         // LogModel log = LogModel.startLog('DynamicBusinessRuleOrderItemAfter','sendSubCerts');
  
          DynamicBusinessRuleOrderItemAfter.sendSubCertResult updateResult = new DynamicBusinessRuleOrderItemAfter.sendSubCertResult(); 
  
          updateResult.result  = true;  
          updateResult.message='';
          String SOQL;
          Date subCertCutOffDate = null;
          Date pamCutOffDate = null;
          List<Id> ordersToBeUpdated = new List<Id>();
          List<Order> ordersEligible = new List<Order>();
          List<Id> ordersToSendSubCert = new List<Id>();
          List<Id> ordersToTriggerPAM = new List<Id>();
          List<Order> OrderList = new List<Order>();  
          Set<Id> orderIdSet = new Set<Id>();
  
          try {
  
            for(Id id : orderIdList)
            {    
              orderIdSet.add(id);
            }    
        
            List<Sub_Cert_Configs__mdt> subconfigs = [Select ID, DeveloperName, MasterLabel, Value__c From Sub_Cert_Configs__mdt];
        
            for (Sub_Cert_Configs__mdt subconfig : subconfigs) {
              if ((subconfig.DeveloperName == 'Sub_Certs_Cut_Off_Date' && (subconfig.Value__c!=null)) ) {
                  try {
                    subCertCutOffDate = subconfig.Value__c;
                  } catch (Exception e) {}
              }
            }

            List<PAM_Trigger_Config__mdt> pamconfigs = [Select ID, DeveloperName, MasterLabel, PAM_Trigger_CutOff_Date__c From PAM_Trigger_Config__mdt];
        
            for (PAM_Trigger_Config__mdt pamconfig : pamconfigs) {
              if ((pamconfig.DeveloperName == 'PAM_Trigger_CutOff_Date' && (pamconfig.PAM_Trigger_CutOff_Date__c!=null)) ) {
                  try {
                    pamCutOffDate = pamconfig.PAM_Trigger_CutOff_Date__c;
                  } catch (Exception e) {}
              }
            }
    
            // OrderList=isFromTrigger==true? [SELECT Id, Send_Order_Certificate_Email__c,Account_Theater_Region__c,Active_Contract__c,
            //                            (SELECT SBCF_Serial_Number__c 
            //                            FROM OrderItems 
            //                            WHERE Serial_Available_For_Core__c = true) 
            //                            FROM Order WHERE DAY_ONLY(createddate)> :subCertCutOffDate 
            //                            AND Status='Placed' AND Send_Order_Certificate_Email__c=false AND Id in :orderIdSet ]
            //                               :
            //                            [SELECT Id, Send_Order_Certificate_Email__c,Account_Theater_Region__c,Active_Contract__c,
            //                            (SELECT SBCF_Serial_Number__c 
            //                            FROM OrderItems 
            //                            WHERE Serial_Available_For_Core__c = true) 
            //                            FROM Order WHERE Status='Placed' AND Id in :orderIdSet ];

            OrderList=isFromTrigger==true? [SELECT Id, Send_Order_Certificate_Email__c,PAM_Trigger__c,Account_Theater_Region__c,Active_Contract__c,CreatedDate,
                                       (SELECT SBCF_Serial_Number__c 
                                       FROM OrderItems 
                                       WHERE Serial_Available_For_Core__c = true) 
                                       FROM Order WHERE Status='Placed' AND Id in :orderIdSet ]
                                          :
                                       [SELECT Id, Send_Order_Certificate_Email__c,PAM_Trigger__c,Account_Theater_Region__c,Active_Contract__c,CreatedDate,
                                       (SELECT SBCF_Serial_Number__c 
                                       FROM OrderItems 
                                       WHERE Serial_Available_For_Core__c = true) 
                                       FROM Order WHERE Status='Placed' AND Id in :orderIdSet ];
    
            for(Order currentOrder: OrderList){    
        
            //Initialize boolean variable to track if the order should be added for update
            Boolean sendEmail = currentOrder.OrderItems!=null && !currentOrder.OrderItems.isEmpty();
    
            // If Order does not have an Contract ex for Demo and Cold Spares, then Skip the Order
               if(currentOrder.Active_Contract__c==null)
                  break;

            //Loop through order items
            for(OrderItem currentOI: currentOrder.OrderItems){
              /*If serial number is blank, then it means that order item has not been fulfilled
                Therefore, we set the flag to false and break out of the loop*/
               // System.debug('Current Serial #:'+currentOI.Id);
                if(String.isBlank(currentOI.SBCF_Serial_Number__c)){
                  sendEmail = false;
                  break;
                }
               
            } //END OF ORDERITEM LOOP

           // System.debug('sendEmailNew ::' +sendEmail);
                  
            if(sendEmail){
                //ordersToBeUpdated.add(currentOrder.Id);
                ordersEligible.add(currentOrder);
              }
          } //END OF ORDER LOOP
       
          //Update orders
          // if(ordersToBeUpdated!=null && !ordersToBeUpdated.isEmpty()){
          //   updateOrderEmailFieldFuture(ordersToBeUpdated,isFromTrigger);          
          //   sendPlatformEventPAM(ordersToBeUpdated,isFromTrigger);  // SFDC-17164

          // }

          if(ordersEligible!=null && !ordersEligible.isEmpty()){

            for( Order o :ordersEligible){

              if(o.CreatedDate> subCertCutOffDate && o.Send_Order_Certificate_Email__c==false){
                ordersToSendSubCert.add(o.Id);

              }

              if(o.CreatedDate>= pamCutOffDate && o.PAM_Trigger__c==false){

                ordersToTriggerPAM.add(o.Id);
              }
            }
              if(ordersToSendSubCert!=null && !ordersToSendSubCert.isEmpty()){

                updateOrderEmailFieldFuture(ordersToSendSubCert,isFromTrigger);  
              }

              if(ordersToTriggerPAM!=null && !ordersToTriggerPAM.isEmpty()){

                sendPlatformEventPAM(ordersToTriggerPAM,isFromTrigger);
              }


          }
          else if(ordersEligible==null || ordersEligible.isEmpty())
          {
            updateResult.result =false;
            updateResult.message=System.Label.Sub_Cert_Error_Message;
          }       
            
          } catch (Exception ex) {
  
            updateResult.result =false;
            updateResult.message=System.Label.Sub_Cert_Error_Message;  
            //log.addExceptionLog(ex);    
            System.debug('Exception'+ ex.getMessage()+'occurred at:' +ex.getStackTraceString());        
          }

          return updateResult;       
    }    
  
     //Future method to update Send_Order_Certificate_Email__c on eligible orders
     @future
     public static void updateOrderEmailFieldFuture(List<Id> orderIdList, Boolean isFromTrigger){
  
       //Log Instance 
      // LogModel log = LogModel.startLog('DynamicBusinessRuleOrderItemAfter','updateOrderEmailFieldFuture');
       Map<String, Object> params = new Map<String, Object>();
       List<Order> oList = new List<Order>();
       List<Order> ordersToBeUpdated = new List<Order>();
       List<Id> ordersToBeUpdatedfromBtn = new List<Id>();
  
       try{
         //Update orders

         oList=[Select Id, Send_Order_Certificate_Email__c,Account_Theater_Region__c from Order where Opportunity.Business_Group__c='Core' AND Id =:orderIdList];

         if(oList!=null && !oList.isEmpty() && !isFromTrigger){
  
          for(Order o: oList){  
          
          ordersToBeUpdated.add(o);          
          }
  
          params.put('OrderList', ordersToBeUpdated);
          params.put('isFromTrigger', isFromTrigger);

          if((ordersToBeUpdated!=null && !ordersToBeUpdated.isEmpty()) ){            
            Flow.Interview.Send_Sub_Cert_Update Send_Sub_Cert_Update = new Flow.Interview.Send_Sub_Cert_Update(params);
            Send_Sub_Cert_Update.start();  
           }
  
         }
         else if(oList!=null && !oList.isEmpty() && isFromTrigger){
         
            for(Order o: oList){

              ordersToBeUpdated.add(new Order(Id = o.Id, Send_Order_Certificate_Email__c = true));
           }

           //If orders are present for updates then update
        if(ordersToBeUpdated!=null && !ordersToBeUpdated.isEmpty()){
            //Update this list of Orders. Partial update is allowed
            Database.SaveResult[] srList = Database.update(ordersToBeUpdated, false);
  
            //Loop through the result to check if there were any failures and log these failures
            for(Database.SaveResult sr: srList){
              if(!sr.isSuccess()){
                String errorMessage =  'Error updating order ' + sr.getId() + ' : ';
                for(Database.Error error: sr.getErrors()){
                  errorMessage += error.getMessage();
                }              
              }
              else{
               // log.addLog('Order updated: ' + sr.getId());
              }
            }
          }
        }       
       } 
       catch(Exception ex){
        // log.addExceptionLog(ex);
        System.debug('Exception'+ ex.getMessage()+'occurred at:' +ex.getStackTraceString());
       }                                    
    }

    public static void sendPlatformEventPAM(List<Id> OrderIds,Boolean isFromTrigger){

      List<Order> orderforPENotify=new List<Order>();

      try{

      if(OrderIds!=null && !OrderIds.isEmpty() && isFromTrigger) { 
      
        for(Order o: [Select Id,OrderNumber from Order where Id =:OrderIds]){
         
             orderforPENotify.add(o);
        }

        if(orderforPENotify!=null && !orderforPENotify.isEmpty()  && LegacySerialDataFixBatch.BypassQuable==FALSE) {

          new PlatformEventHelper().publishObject('FULFILLED',orderforPENotify);
          updatePAMTriggerFieldFuture(OrderIds);
        }
      }
    } 
      catch(Exception ex){
        System.Debug('Exception Generated::'+ex);
      }  
    }

    @future
    public static void updatePAMTriggerFieldFuture(List<Id> orderIdList){

      List<Order> ordersToBeUpdated = new List<Order>();

      try{

        for(Id oId : orderIdList){

          ordersToBeUpdated.add(new Order(Id = oId, PAM_Trigger__c = true));
        }

        if(ordersToBeUpdated!=null && !ordersToBeUpdated.isEmpty()){
       
          Database.SaveResult[] srList = Database.update(ordersToBeUpdated, false);

          for(Database.SaveResult sr: srList){
            if(!sr.isSuccess()){
              String errorMessage =  'Error updating order ' + sr.getId() + ' : ';
              for(Database.Error error: sr.getErrors()){
                errorMessage += error.getMessage();
              }              
            }
            else{
             // log.addLog('Order updated: ' + sr.getId());
            }
          }
        }

      }
      catch(Exception ex){
        System.Debug('Exception Generated::'+ex);
      }  
    }
  
    public class sendSubCertResult {
  
      @AuraEnabled
      public String message;
    
      @AuraEnabled
      public Boolean result;    
    }     
  }