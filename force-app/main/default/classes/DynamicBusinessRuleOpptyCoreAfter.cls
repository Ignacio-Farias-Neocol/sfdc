/**
* @author Yuli Fintescu
* @date 2019-9-29
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description:
*   SFDC-7642 update quote payment term when oppty payment term changed to credit card
*   SFDC-13795: Update quote when certain fields change in opportunity
*   SFDC-13312: Updated class to update quote when end user account on opportunity changes. 
*               As part of these changes other quote update logic were consolidated.  
*/

public with sharing class DynamicBusinessRuleOpptyCoreAfter implements DynamicBusinessRuleAction {

  //Prevents queueable job from being queued twice
  public static Boolean isAlreadyQueued = false;

  //Map of quote id and it's corresponding object. This will be used to update quotes after fetching all quotes that need to be updated
  Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>();

  public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {

    //When Opportunity is updated
    if(triggerContext.contains('Update') && !isAlreadyQueued){
      identifyQuotesForUpdate(newRecordMap, oldRecordMap);

      //Create new instance of the quote update queueable job
      if(quoteMap!=null && !quoteMap.isEmpty()){
        String StrListData = JSON.serialize(quotemap.values());
        OppBasedQuoteUpdates.executeLog(StrListData);
      }
    }
  }

  //Identify quotes to be updated
  private void identifyQuotesForUpdate(Map<Id,SObject> newRecordMap, Map<Id, SObject> oldRecordMap){

    //Set of Opportunity Ids in which payment terms was changed
    Set<Id> paymentTermsOppSet = new Set<Id>();

    //Set of Opportunity Ids in which end user account was changed
    Set<Id> endUserAccountOppSet = new Set<Id>();

    //Set of Opportunity Ids for which quotes need to be pulled
    Set<Id> oppSet = new Set<Id>();

    //Loop through all opportunities to get the eligible quote to be updated
    for(Opportunity currentOpp: (List<Opportunity>) newRecordMap.values()){
      //get the old oppty values for comparison
      Opportunity oldOpp = (Opportunity)oldRecordMap.get(currentOpp.Id);
      //Check if primary quote needs to be updated
      if(currentOpp.SBQQ__PrimaryQuote__c!=null){
        addPrimaryQuote(currentOpp, oldOpp);
      }

      //Opportunity payment terms change
      if(currentOpp.Business_group__c == 'Core' && currentOpp.Payment_Terms__c != oldOpp.Payment_Terms__c) {
        paymentTermsOppSet.add(currentOpp.Id);
        oppSet.add(currentOpp.Id);
      }

      //Opportunity End User Account change
      if(!currentOpp.isClosed && currentOpp.AccountId != oldOpp.AccountId) {
        endUserAccountOppSet.add(currentOpp.Id);
        oppSet.add(currentOpp.Id);
      }
    }

    //Get quotes that need to be updated
    for(SBQQ__Quote__c currentQuote : [SELECT Id,
                                              SBQQ__Primary__c,
                                              SBQQ__Opportunity2__c,
                                              SBQQ__Opportunity2__r.AccountId,
                                              SBQQ__Opportunity2__r.Billing_Address__c,
                                              SBQQ__Opportunity2__r.Shipping_Address__c,
                                              SBQQ__Opportunity2__r.Primary_Contact__c,
                                              SBQQ__Opportunity2__r.Payment_Terms__c,
                                              SBQQ__Opportunity2__r.Bill_To_Account__r.Payment_Terms__c,
                                              SBCF_Reseller__c,
                                              SBQQ__Distributor__c 
                                        FROM SBQQ__Quote__c 
                                        WHERE SBQQ__Opportunity2__c in :oppSet
                                        ORDER BY SBQQ__Opportunity2__c]){
      
      //Get/put quote record to be updated
      SBQQ__Quote__c quote;
      if(quoteMap.containsKey(currentQuote.Id)){
        quote = quoteMap.get(currentQuote.Id);
      }
      else{
        quote = new SBQQ__Quote__c(Id = currentQuote.Id);
        quoteMap.put(currentQuote.Id, quote);
      }
      //Update Payment Terms
      if(paymentTermsOppSet.contains(currentQuote.SBQQ__Opportunity2__c)){
        if (currentQuote.SBQQ__Opportunity2__r.Payment_Terms__c == 'Credit Card'){
          quote.SBQQ__PaymentTerms__c = 'Credit Card';
        }     
        else {
          quote.SBQQ__PaymentTerms__c = currentQuote.SBQQ__Opportunity2__r.Bill_To_Account__r.Payment_Terms__c;
        }
      }

      //Update End User Account, Billing / Shipping Address and Primary Contact for non primary quotes
      if(!currentQuote.SBQQ__Primary__c && endUserAccountOppSet.contains(currentQuote.SBQQ__Opportunity2__c)){
        //Update end user account on quote
        quote.SBQQ__Account__c = currentQuote.SBQQ__Opportunity2__r.AccountId;

        //Update billing address/shipping address and partner account on quote only if the quote does not have a reseller or disti
        if(String.isBlank(currentQuote.SBCF_Reseller__c) && String.isBlank(currentQuote.SBQQ__Distributor__c)){
          quote.Billing_Address__c      = currentQuote.SBQQ__Opportunity2__r.Billing_Address__c;
          quote.Shipping_Address__c     = currentQuote.SBQQ__Opportunity2__r.Shipping_Address__c;
          quote.SBQQ__PrimaryContact__c = currentQuote.SBQQ__Opportunity2__r.Primary_Contact__c;
        }
      }
    } //END of QUOTE LOOP    
  }

  //Updates primary quote when specific fields on the opportunity change
  private void addPrimaryQuote(Opportunity newOpp, Opportunity oldOpp){
    if(oldOpp!=null){
      // Compare old and new oppties
      if ((newOpp.AccountId != oldOpp.AccountId ||
          newOpp.SBCF_Billing_Aggregator__c != oldOpp.SBCF_Billing_Aggregator__c || 
          newOpp.CloseDate != oldOpp.CloseDate || 
          newOpp.Distributor__c != oldOpp.Distributor__c || 
          newOpp.Legacy_Data__c != newOpp.Legacy_Data__c || 
          newOpp.CurrencyIsoCode != oldOpp.CurrencyIsoCode || 
          newOpp.Reseller__c != oldOpp.Reseller__c || 
          newOpp.Distributor_Contact__c != oldOpp.Distributor_Contact__c || 
          newOpp.Reseller_Contact__c != oldOpp.Reseller_Contact__c || 
          newOpp.Primary_Contact__c != oldOpp.Primary_Contact__c || 
          newOpp.Billing_Address__c != oldOpp.Billing_Address__c || 
          newOpp.Shipping_Address__c != oldOpp.Shipping_Address__c ||
          //Below logic added as a part of SFDC-18066
          newOpp.Deal_Reg_Type__c != oldOpp.Deal_Reg_Type__c ||
          newOpp.Deal_Reg_Status__c != oldOpp.Deal_Reg_Status__c ||
          newOpp.Deal_Reg_Exp_Date__c != oldOpp.Deal_Reg_Exp_Date__c ||
          newOpp.Deal_Reg_Tracking_No__c != oldOpp.Deal_Reg_Tracking_No__c) &&
          newOpp.SBQQ__PrimaryQuote__c == oldOpp.SBQQ__PrimaryQuote__c){
        SBQQ__Quote__c quote;
        if(quoteMap.containsKey(newOpp.SBQQ__PrimaryQuote__c)){
          quote = quoteMap.get(newOpp.SBQQ__PrimaryQuote__c);
        }
        else{
          quote = new SBQQ__Quote__c(Id = newOpp.SBQQ__PrimaryQuote__c);
          quoteMap.put(newOpp.SBQQ__PrimaryQuote__c, quote);
        }

        //Set quote values
        quote.SBQQ__Account__c           = newOpp.AccountId;
        quote.SBCF_Billing_Aggregator__c = newOpp.SBCF_Billing_Aggregator__c;
        quote.Closed_Date__c             = newOpp.CloseDate;
        //Changes done as a part of SFDC-18066: START  
        quote.SBCF_Deal_Reg_Type2__c      = newOpp.Deal_Reg_Type__c;
        quote.SBCF_Deal_Reg_Status__c     = newOpp.Deal_Reg_Status__c;
        quote.SBCF_Deal_Reg_Expiration__c = newOpp.Deal_Reg_Exp_Date__c;
        quote.SBCF_Deal_Reg_Tracking_No__c = newOpp.Deal_Reg_Tracking_No__c;
        quote.SBCF_Reseller_Contact__c    = newOpp.Reseller_Contact__c;
        quote.SBCF_Distributor_Contact__c = newOpp.Distributor_Contact__c;       
        // Changes done as a part of SFDC-18066: END
        quote.SBQQ__Distributor__c       = newOpp.Distributor__c;
        quote.Legacy_Data__c             = newOpp.Legacy_Data__c;
        quote.CurrencyIsoCode            = newOpp.CurrencyIsoCode;
        quote.SBCF_Reseller__c           = newOpp.Reseller__c;
        quote.SBQQ__PrimaryContact__c    = newOpp.Select_Primary_Contact__c;      
        quote.Billing_Address__c         = newOpp.Billing_Address__c;
        quote.Shipping_Address__c        = newOpp.Shipping_Address__c;
      }
    }        
  }
}