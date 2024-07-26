/**
* @author Salesforce Services
* @date 2020-11-19
*
* @group DynamicBusinessRuleAction
*
* @description implementation of DynamicBusinessRuleAction interface to lookup an Entitlement for a given case based on the related subscription. 
* We are using this class and not DefaultLookupHelper because DefaultLookupHelper uses with sharing. There are scenarios when Resellers create cases for their customers
* and they need to access customer's entitlement. To allow for this usecase we need to use without sharing. 
*/

public without sharing class DynamicBusinessRuleCaseEntitlement implements DynamicBusinessRuleAction{

  public void processRecords(Map<Id,SObject> newRecordMap,  
                              Map<Id,SObject> oldRecordMap,  
                              List <SObject> records, 
                              String jsonParameter, 
                              String triggerOrder, 
                              String triggerContext){
                                  
     //  No longer needed as per SFDC-14299                           
                                  
 /*       
    Map <Id,List<Case>> subscriptionCases = new Map <Id,List<Case>>();

    //Loop through records and prepare a map of Subscription Id and the related cases
    for(SObject rec: records){
      //Cast the SObject into case record
      Case caseRecord = (Case)rec;
      if(String.isNotBlank(caseRecord.Subscription__c)){
        if(subscriptionCases.containsKey(caseRecord.Subscription__c)){
          subscriptionCases.get(caseRecord.Subscription__c).add(caseRecord);
        }
        else{
          subscriptionCases.put(caseRecord.Subscription__c, new List<Case>{caseRecord});
        }
      }
    }

    //if the map is not empty then get the list of entitlements for these subscriptions
    //For each of the entitlements, get the cases that are tied to related sub and update entitlements on these sub
    if(subscriptionCases!=null && !subscriptionCases.isEmpty()){
      for(Entitlement ent: [SELECT Id, 
                                    Subscription__c 
                            FROM Entitlement 
                            WHERE Subscription__c in :subscriptionCases.keySet() 
                            AND  Status='Active' 
                            AND Name Like '%Premium Support%']){
        if(subscriptionCases.containsKey(ent.Subscription__c)){
          for(Case caseRecord: subscriptionCases.get(ent.Subscription__c)){
            caseRecord.EntitlementId = ent.Id;
          }
        }
      }
    } */
                                  
  } 
}