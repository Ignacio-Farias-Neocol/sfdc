/**
* @author Nandita
* @date 2023-02-16
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description:
*   
*/

public without sharing class DynamicBusinessRuleOpptyMSPAfter implements DynamicBusinessRuleAction {

  //Prevents queueable job from being queued twice
  public static Boolean isAlreadyQueued = false;

  //Map of quote id and it's corresponding object. This will be used to update quotes after fetching all quotes that need to be updated
  Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>();

  public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {

    //When Opportunity is updated
    if(triggerContext.contains('Update') && !isAlreadyQueued){
      identifyQuotesForUpdate(newRecordMap, oldRecordMap);

    }
  }

  //Identify quotes to be updated
  private void identifyQuotesForUpdate(Map<Id,SObject> newRecordMap, Map<Id, SObject> oldRecordMap){

    //Set of Opportunity Ids for which quotes need to be pulled
    Set<Id> oppSet = new Set<Id>();
    try{
        //Loop through all opportunities to get the eligible quote to be updated
        for(Opportunity currentOpp: (List<Opportunity>) newRecordMap.values()){
          //get the old oppty values for comparison
          Opportunity oldOpp = (Opportunity)oldRecordMap.get(currentOpp.Id);
          //Modify: Sonal Agrawal
          //SFDC-19246: Update for Billing Address also
          if(currentOpp.Business_group__c == 'MSP' && (currentOpp.Shipping_Address__c != oldOpp.Shipping_Address__c || currentOpp.Billing_Address__c != oldOpp.Billing_Address__c)) {
             oppSet.add(currentOpp.Id);
          }
    
          
        }
    
        //Get quotes that need to be updated
        for(SBQQ__Quote__c currentQuote : [SELECT Id,
                                                  SBQQ__Primary__c,
                                                  SBQQ__Opportunity2__c,
                                                  Shipping_Address__c,
                                                  Billing_Address__c,
                                                  SBQQ__Opportunity2__r.Billing_Address__c,
                                                  SBQQ__Opportunity2__r.Shipping_Address__c                                              
                                            FROM SBQQ__Quote__c 
                                            WHERE SBQQ__Opportunity2__c in :oppSet and SBQQ__Primary__c = true
                                            ORDER BY SBQQ__Opportunity2__c]){
          
          //Get/put quote record to be updated
          SBQQ__Quote__c quote;
          //Modify: Sonal Agrawal
          //SFDC-19246: Update for Billing Address also
          //Update Shipping Address and Shipping Contact for quotes
          if((currentQuote.Shipping_Address__c!=currentQuote.SBQQ__Opportunity2__r.Shipping_Address__c && currentQuote.SBQQ__Opportunity2__r.Shipping_Address__c!=null) || (currentQuote.Billing_Address__c!=currentQuote.SBQQ__Opportunity2__r.Billing_Address__c && currentQuote.SBQQ__Opportunity2__r.Billing_Address__c!=null)){
               if(quoteMap.containsKey(currentQuote.Id)){
                    quote = quoteMap.get(currentQuote.Id);
                  }
                  else{
                    quote = new SBQQ__Quote__c(Id = currentQuote.Id);
                    quoteMap.put(currentQuote.Id, quote);
                  }
              quote.Shipping_Address__c = currentQuote.SBQQ__Opportunity2__r.Shipping_Address__c;
              quote.Billing_Address__c = currentQuote.SBQQ__Opportunity2__r.Billing_Address__c;
            }
         }
         
         if(quoteMap!=null && !quoteMap.isEmpty()){
          Database.update(quoteMap.values(),false);
         }
      
      }catch(Exception Ex){
		System.debug('Exception**'+Ex);
      }
      
  }


}