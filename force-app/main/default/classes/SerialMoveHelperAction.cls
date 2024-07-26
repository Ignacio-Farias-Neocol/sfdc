global with sharing class SerialMoveHelperAction {

  /** This method updates Assigned Serials in Salesforce based on the mapping
  */
@InvocableMethod (label='Update Assigned Serials' description='Update Assigned Serials') 
public static List<SerialMoveHelperAction.SerialMoveUpdateResult> updateAssignedSerialsAction(List<SerialMoveHelperAction.SerialMoveUpdateRequest> serialSubMapString){

 //Instantiate the log class to capture logs for error conditions
 LogModel log = LogModel.startLog('SerialMoveHelperAction', 'updateAssignedSerialsAction');
 log.addLog('In SerialMoveHelperAction: ');
 log.addLog('serialSubMapString: ' + serialSubMapString);
 log.addLog('Mapping String: ' + serialSubMapString[0].serialSubMap);

 //Create a result object
 SerialMoveHelperAction.SerialMoveUpdateResult updateResult = new SerialMoveHelperAction.SerialMoveUpdateResult();   
 
 //Prepare a map of Assigned Serial Id and the target Subscription ID
 Map<String, String> assignedSerialSubIdMap = new Map<String, String>();

 //Prepare a map of Assigned Serial Id and the target Subscription Root ID. 
 //This is used to determine the parent subscription for the assigned Serial
 Map<String, String> assignedSerialSubRootIdMap = new Map<String, String>();

 //Prepare a map of Assigned Serial Id and the target Subscription Contract. 
 //This is used to determine the Contract for the assigned Serial
 Map<String, String> assignedSerialContractMap = new Map<String, String>();    

 //Prepare a map of Assigned Serial Id and the Serial ID. 
 //This is used to determine the child assigned Serial for a given parent assigned serial
 Map<String, String> serialAssignedSerialIdMap = new Map<String, String>();    
 
 //List of Assigned Serials to be updated
 List<Assigned_Serial__c> assignedSerialsUpdateList = new List<Assigned_Serial__c>();  

 try
 {
   //parse the JSON string provided by the flow
   List<Object> subscriptions = (List<Object>)JSON.deserializeUntyped(serialSubMapString[0].serialSubMap);

   //If there are subscription loop through each of them to get serial information for the payload
   if(subscriptions!=null && !subscriptions.isEmpty()){
     for(Object obj: subscriptions){
       //Convert each Subscription entry in JSON to a map. This is done to get attribute values.
       Map<String, Object> subObjMap = (Map<String, Object>)obj;

       //If the Subscription does have a mapped Serial then prepare the payload
       if(subObjMap.get('serials')!=null){
         //Get serials as a list
         List<Object> serialsObjList = (List<Object>)subObjMap.get('serials');

         //Loop through each serial to get serial info
         for(Object serialObj: serialsObjList){
           //Convert each serial into a map to get attributes
           Map<String, Object> serialObjMap = (Map<String, Object>)serialObj;

           Map<String, Object> serialInfo = (Map<String, Object>)serialObjMap.get('serial');

           //get Assigned Serial ID
           String assignedSerialId = (String)serialObjMap.get('id');

           //Prepare the Map of Assigned Serial and Subscription Id
           if(assignedSerialSubIdMap!=null && !assignedSerialSubIdMap.containsKey(assignedSerialId)){
             assignedSerialSubIdMap.put(assignedSerialId, (String)subObjMap.get('subscriptionId'));
           }

           //Get root ID. If the root Id belongs to a Sub then add it to the map
           Id rootId = (Id)subObjMap.get('subscriptionRootId');

           //Populate root id map
           if(rootId!=null && rootId.getSobjectType().getDescribe().getName() == 'SBQQ__Subscription__c'){
             assignedSerialSubRootIdMap.put(assignedSerialId, (String)subObjMap.get('subscriptionRootId'));
           } 

           //Get Contract.
           String contract = (String)subObjMap.get('subscriptionContract');
           System.debug('**Contract: ' + contract);

           //Populate root id map
           if(contract!=null && !assignedSerialContractMap.containsKey(contract)){
             assignedSerialContractMap.put(assignedSerialId, contract);
           }               

           //Get Serial Id
           String serialId = (String)serialInfo.get('serialid');

           if(serialId!=null){
             serialAssignedSerialIdMap.put(serialId, assignedSerialId);
           }              
         }
       }
     }
     System.debug('AS CONTRACT MAP: ' + assignedSerialContractMap);
   }

   //Get child Subscriptions and prepare a map of Parent Subscription and its children
   Map<String, List<SBQQ__Subscription__c>> parentChildSubMap = new Map<String, List<SBQQ__Subscription__c>>();

   for(SBQQ__Subscription__c currentSub: [SELECT Product_Code__c,
                                                 SBQQ__RootId__c,
                                                 SBQQ__Contract__c,
                                                 Id
                                          FROM SBQQ__Subscription__c 
                                          WHERE SBQQ__RootId__c in :assignedSerialSubIdMap.values()]){
     if(parentChildSubMap!=null){
       if(parentChildSubMap.containsKey(currentSub.SBQQ__RootId__c)){
         parentChildSubMap.get(currentSub.SBQQ__RootId__c).add(currentSub);
       }
       else{
         parentChildSubMap.put(currentSub.SBQQ__RootId__c, new  List<SBQQ__Subscription__c>{currentSub});
       }
     }
   }

   //Prepare the list of current parent subscription for the parent assigned serial to be moved
   //this will be used to get the child assigned serials
   //Use this loop to also prepare the AssignedSerialUpdateList
   Map<String, String> currentParentASAndSubIdMap = new Map<String, String>();
   for(Assigned_Serial__c currentParentAS: [SELECT Id,
                                                   Serial__c, 
                                                   Subscription__c
                                            FROM Assigned_Serial__c 
                                            WHERE Id in :assignedSerialSubIdMap.keySet()]){
     currentParentASAndSubIdMap.put(currentParentAS.Subscription__c, currentParentAS.Id);
     assignedSerialsUpdateList.add(new Assigned_Serial__c(Id = currentParentAS.Id, 
       Subscription__c = assignedSerialSubIdMap.get(currentParentAS.Id),
       Parent_Subscription__c = assignedSerialSubRootIdMap.containsKey(currentParentAS.Id)?assignedSerialSubRootIdMap.get(currentParentAS.Id):null,
       Contract__c = assignedSerialContractMap.get(currentParentAS.Id),
       External_ID__c = currentParentAS.Serial__c + assignedSerialSubRootIdMap.get(currentParentAS.Id) + assignedSerialSubIdMap.get(currentParentAS.Id)));
   }

   system.debug('Current Parent AS and Sub Id: ' + currentParentASAndSubIdMap);
   //Get child Assigned Serial for the parent assigned serial to be moved
   for(Assigned_Serial__c currentChildAS: [SELECT Subscription__c,
                                             Parent_Subscription__c,
                                             Subscription__r.Product_Code__c,
                                             Serial__c 
                                     FROM Assigned_Serial__c 
                                     WHERE Parent_Subscription__c IN :currentParentASAndSubIdMap.keySet() 
                                     AND Serial__c IN :serialAssignedSerialIdMap.keySet() 
                                     AND Id NOT IN :assignedSerialSubIdMap.keySet()]){
     //We need to find the target parent subscription first. 
     //We will get this by determining the child AS' parent and then using it to get target parent sub
     String parentASId = serialAssignedSerialIdMap.get(currentChildAS.Serial__c);
     if(String.isNotBlank(parentASId)){
       String targetParentSubId = assignedSerialSubIdMap.get(parentASId);

       //Loop through target child subscription for the target parent sub found in the previous step.
       //If there are children, then map this child AS to the target child Sub with the same product code
       if(String.isNotBlank(targetParentSubId)){
         for(SBQQ__Subscription__c targetChildSub: parentChildSubMap.get(targetParentSubId)){
           if(currentChildAS.Subscription__r.Product_Code__c!=null && 
              currentChildAS.Subscription__r.Product_Code__c.equalsIgnoreCase(targetChildSub.Product_Code__c)){
               //Prepare the child AS for update
               assignedSerialsUpdateList.add(new Assigned_Serial__c(Id=currentChildAS.Id,
                                                                    Subscription__c = targetChildSub.Id,
                                                                    Parent_Subscription__c = targetChildSub.SBQQ__RootId__c,
                                                                    Contract__c = targetChildSub.SBQQ__Contract__c,
                                                                    External_ID__c = currentChildAS.Serial__c + targetChildSub.SBQQ__RootId__c + targetChildSub.Id));
               break;
           }
         }
       }
     }
   }

   //Update assigned serials. This is an All or none operation
   log.addLog('Assigned Serial Update List: ' + JSON.serialize(assignedSerialsUpdateList));
   // DML.save(assignedSerialsUpdateList);   
   withoutSharingDML.save(assignedSerialsUpdateList);

   updateResult.result = true;
   updateResult.message = 'Serials updated in Salesforce';
   System.debug('***Result: ' + updateResult.result + ' ' + updateResult.message);

   log.endLog('End: SerialMoveHelperAction');
     
 }
 catch(System.DmlException de) {
   //Set result attributes
   updateResult.result  = false;
   updateResult.message = 'DML Exception. API call to ECHO was not attempted: ' + de.getMessage();
   System.debug('***Result in DML: ' + updateResult.result + ' ' + updateResult.message);
 }    
 catch(Exception ex){
   //Set result attributes
   updateResult.result  = false;
   updateResult.message = 'Exception: ' + ex.getMessage();
   System.debug('***Result in EXC: ' + updateResult.result + ' ' + updateResult.message);
   log.addExceptionLog(ex);
 }

 return new List<SerialMoveHelperAction.SerialMoveUpdateResult> {updateResult};

    }

    global class SerialMoveUpdateRequest {

        @InvocableVariable(required=true)
        global String serialSubMap; 
    }

    global class SerialMoveUpdateResult {
       
        @InvocableVariable
        global Boolean result;    

        @InvocableVariable
        global String message;
      }    
}