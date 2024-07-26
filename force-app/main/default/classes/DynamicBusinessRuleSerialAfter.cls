/**
* @author PS
* @date 09/24/2019
*
* @group DynamicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to pass serial activation date to contract and subscriptions
* SFDC-8275, SFDC-6528
*/
public class DynamicBusinessRuleSerialAfter implements DynamicBusinessRuleAction { 
    /*******************************************************************************************************
    * @description pass serial activation date to related assigned serial, contract and subscriptions when serial is updated
    * @param trigger.new map
    * @return none, the result should be set to subscription object
    * @example
    */
    private static List<String> quoteTypesToExclude = new List<String>{'Amendment','Renewal'};
    
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        UpdateContractSubsDates(records, oldRecordMap);       

        if (triggerOrder == 'POST') {

            if(triggerContext.contains('Update') && LegacySerialDataFixBatch.BypassQuable==FALSE){
              AsyncCheckFulfillmentDateAndSyncSubs(records, oldRecordMap);
            }

        }
    }  

    private static void UpdateContractSubsDates(List<SObject> records, Map<Id, SObject> oldRecordMap) {
        List<Serial__c> candidates = new List<Serial__c>();
        for (SObject o: records){
            Serial__c s = (Serial__c)o;
            Serial__c s2 = oldRecordMap == null ? null : (Serial__c)oldRecordMap.get(s.Id);
            if (s2 == null)
                s2 = new Serial__c();
            
            if(s.Activation_Date__c != s2.Activation_Date__c && s.Activation_Date__c != NULL){
                candidates.add(s);
            }
        }

        if (candidates.size() > 0) {
            List<Assigned_Serial__c> assignedSerirals = [Select ID, Serial__r.Activation_Date__c, /*Serial_Activation_Date__c,*/
                                                    Subscription__c, Serial__r.Serial_Number__c,
                                                    Subscription__r.SBQQ__StartDate__c, //formula field
                                                    Subscription__r.SBQQ__SubscriptionStartDate__c, 
                                                    /*Subscription__r.Serial_Activation_Date__c,*/
                                                    Subscription__r.Business_Group__c, 
                                                    Subscription__r.SBQQ__Contract__c, 
                                                    Subscription__r.SBQQ__Contract__r.StartDate,
                                                    Subscription__r.SBQQ__Contract__r.SBCF_Order_Fulfillment_Date__c,
                                                    Subscription__r.SBQQ__Contract__r.SBQQ__Quote__c,
                                                    Subscription__r.SBQQ__Contract__r.Business_Group__c,
                                                    Subscription__r.SBQQ__Contract__r.ContractTerm 
                                                From Assigned_Serial__c 
                                                where Serial__c in: candidates and Subscription__c <> NULL AND 
                                                Subscription__r.SBQQ__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c = 'Quote'
                                                AND Subscription__r.SBQQ__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBCF_Order_Type__c = 'New' ];
            
            DynamicBusinessRuleAssignedSerialAfter.UpdateContractSubsDates(assignedSerirals);
        }
    }

    private static void AsyncCheckFulfillmentDateAndSyncSubs(List<sobject> records, Map<Id, Sobject> oldRecordMap){
      LogModel log = LogModel.startLog('DynamicBusinessRuleSerialAfter', 'AsyncCheckFulfillmentDateAndSyncSubs');

      try{
        List<String> changedFulfillmentDateSerials = new List<String>(); 
        Set<String> subscriptionIds = new Set<String>();
        for(Sobject sobj : records){
          Serial__c serial = (Serial__c) sobj;
          Serial__c oldSerial = (Serial__c) oldRecordMap.get(serial.Id);
          if(serial.Fulfillment_Date__c != oldSerial.Fulfillment_Date__c || Test.isRunningTest()){
            changedFulfillmentDateSerials.add(serial.Id);
          } 
        }

        if(!changedFulfillmentDateSerials.isEmpty()){
          List<Serial__c> serials = [Select Id, 
                                      (Select Id, Subscription__c From Assigned_Serials__r)
                                      From Serial__c
                                      Where Id IN: changedFulfillmentDateSerials];
          
          for(Serial__c ser : serials){
            if(ser.Assigned_Serials__r != null && ser.Assigned_Serials__r.size() > 0){
              for(Assigned_Serial__c aSerial : ser.Assigned_Serials__r){
                subscriptionIds.add(aSerial.Subscription__c);
              }
            }
          }
        }

        if(!subscriptionIds.isEmpty() && subscriptionIds.size() > 0){
          ID jobID = System.enqueueJob(new AsyncUpdateSubDatesOnFulfillment(new List<String>(subscriptionIds)));
        }
      }
      catch(Exception e){
        log.addExceptionLog(e);
        log.endLog();
        throw e;
      }
    }
    
}