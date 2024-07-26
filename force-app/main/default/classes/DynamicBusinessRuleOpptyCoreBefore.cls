/**
* @author Yuli Fintescu
* @date 2019-9-29
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description:
*   SFDC-9873 Auto populate Billing Aggregator from Account (moved this to before save flow as part of 13312 changes)
*   SFDC-9483 Prevent opp from closed if any quote line renewing sub that has been renewed.
*   SFDC-9941 Adding customer name amendment oppty name
*   SFDC-11165 Prevent opp from closed quoted different VOL product from what existing in Account.
*   SFDC-13312 Populate Account based fields on Opportunity when End User or Reseller or Disti account changes
*/
public class DynamicBusinessRuleOpptyCoreBefore implements DynamicBusinessRuleAction { 
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        validateSubsInRenewalPrimaryQuote(records, oldRecordMap);
        populateFieldsAfterAccountChanges(records, oldRecordMap);
        
        if (triggerContext.contains('Insert')) {
            checkForAccountsWithLargeAssets(records);
            AmendmentOpptyNaming(records);
            UpdateEarliestSubEndDate(records);
            
        }
                
         if (triggerContext.contains('Insert') || triggerContext.contains('Update')) {
           checkDistributorAdded(records,oldRecordMap);
         
         }

        if (triggerContext.contains('Update')) {
         
         checkDistributorRemoved(records,oldRecordMap); //  Oppty Before Save Flow change Oppty to 'Included-Automatically'
                                                        // This Code will hence only update back to 'Excluded-Automatically'
                                                        // if Expiration date was less than 60 days in future
      }
    }
	
    @TestVisible
    private void checkDistributorRemoved(List<SObject> records, Map<Id,SObject> oldRecordMap){

      System.debug('Before Update :: checkDistributorRemoved from Oppty');
        List<Id>  oIds = new List<Id>();
        List<Contract>  contoUpdate = new List<Contract>();
        Date coreExpDate   = Date.today().addDays(60);

        for (Opportunity op : (List<Opportunity>)records){
          Opportunity opOld = oldRecordMap == null ? new Opportunity() : (Opportunity)oldRecordMap.get(op.Id);
            if (opOld == null){ opOld = new Opportunity();}
			System.debug('Business_Group__c---> '+ op.Business_Group__c +' op.Distributor__c---> '+ op.Distributor__c+' opOld.Distributor__c---> '+opOld.Distributor__c);
            System.debug('opOld.Auto_Renewal_Status_Core__c---> '+ opOld.Auto_Renewal_Status_Core__c +'  opOld.Auto_Renewal_Status_Reason_Core__c---> '+  opOld.Auto_Renewal_Status_Reason_Core__c+' op.SBQQ__Renewal__---> '+op.SBQQ__Renewal__c);
            System.debug(' op.SBQQ__RenewedContract__c---> '+ op.SBQQ__RenewedContract__c +' op.Expiration_Date__---> '+ op.Expiration_Date__c+'coreExpDate---> '+coreExpDate);
            if(op.Business_Group__c=='Core'  && (op.Distributor__c==null && opOld.Distributor__c!=null) &&  (opOld.Auto_Renewal_Status_Core__c=='Excluded - Automatically' && opOld.Auto_Renewal_Status_Reason_Core__c=='Excluded - Distribution Deal') && op.SBQQ__Renewal__c && op.SBQQ__RenewedContract__c!=null && (op.Expiration_Date__c<coreExpDate) && !op.isclosed){

              oIds.add(op.Id);
            }
          }
            System.debug('Dist Removed from Opp Size::'+ oIds.size());

            if(oIds.size()>0) {
              Map<Id,Opportunity> opMap=new Map<Id, Opportunity>([Select Id, Auto_Renewal_Eligible_Core__c, Auto_Renewal_Status_Core__c, Auto_Renewal_Status_Reason_Core__c from Opportunity Where Id in : oIds]);
              
              for (Opportunity Opps : (List<Opportunity>)records){ Opps.Auto_Renewal_Status_Core__c='Excluded - Automatically';
                  Opps.Auto_Renewal_Status_Reason_Core__c='Excluded - Distribution Deal';                         
              }
            }        
    } 
   @testVisible
    private void checkDistributorAdded(List<SObject> records, Map<Id,SObject> oldRecordMap){

      System.debug('checkDistributorAdded in Oppty');
        List<Id>  oIds = new List<Id>();
        List<Contract>  contoUpdate = new List<Contract>();

        for (Opportunity op : (List<Opportunity>)records){
          Opportunity opOld = oldRecordMap == null ? new Opportunity() : (Opportunity)oldRecordMap.get(op.Id);
            if (opOld == null)
            opOld = new Opportunity();

            if(op.Business_Group__c=='Core'  && op.Distributor__c!=null &&  op.Auto_Renewal_Status_Core__c!='Excluded - Automatically' &&  op.Auto_Renewal_Status_Core__c!='Excluded - Distribution Deal' &&  op.SBQQ__Renewal__c && op.SBQQ__RenewedContract__c!=null){
             
             op.Auto_Renewal_Status_Core__c='Excluded - Automatically';
             op.Auto_Renewal_Status_Reason_Core__c='Excluded - Distribution Deal';
            }
          }
    } 
    
    //SFDC-9483 Prevent opp from closed if any quote line renewing sub that has been renewed.
    //SFDC-11165 Prevent opp from closed quoted different VOL product from what existing in Account.
    @testVisible
    private static void validateSubsInRenewalPrimaryQuote(List<SObject> records, Map<Id, SObject> oldRecordMap) {
        Map<String, Opportunity> candidates = new Map<String, Opportunity>();
        Map<String, Opportunity> candidatesMSP = new Map<String, Opportunity>();

        for (Opportunity o : (List<Opportunity>)records){
            Opportunity oOld = oldRecordMap == null ? new Opportunity() : (Opportunity)oldRecordMap.get(o.Id);
            if (oOld == null)
                oOld = new Opportunity();

            if (o.SBQQ__PrimaryQuote__c != null && o.StageName != oOld.StageName && o.StageName == 'Closed Won') {
                candidates.put(o.SBQQ__PrimaryQuote__c, o);

                if (o.Business_Group__c == 'MSP') { candidatesMSP.put(o.SBQQ__PrimaryQuote__c, o);
                }
            }
        }

        //SFDC-9483
        if (candidates.size() > 0) {
            for (String quoteId : DynamicBusinessRuleQuoteCoreBefore.quotesWithInvalidSubs(candidates.keySet())) {
                Opportunity errorOppty =  (Opportunity)candidates.get(quoteId);
                if (errorOppty != null){errorOppty.addError('One or more of the subscriptions on the Primary Quote have already been renewed or are associated with multiple line items in the quote. Please double check your subscriptions have not already been renewed, or ensure that you have one of your quote options marked as optional. You can see this by looking at the subscription record in the Renewed by Subscription field.');}
            }
        }

        //SFDC-11165
        if (candidatesMSP.size() > 0) {
            for (String quoteId : DynamicBusinessRuleQuoteBefore.quotesWithDupVols(candidatesMSP.keySet())) {
                Opportunity errorOppty =  (Opportunity)candidatesMSP.get(quoteId);
                if (errorOppty != null) {errorOppty.addError('Unable to close this opportunity: Primary Quote contains multiple VOLs or VOLs conflicting with the active VOLs on the account.');}
            }
        }
    }

    //SFDC-9941 Adding customer name amendment oppty name
    @testVisible
    private static void AmendmentOpptyNaming(List<SObject> records) {
        List<Opportunity> candidates = new List<Opportunity>();

        Set<String> acctIds = new Set<String>();
        for (Opportunity o : (List<Opportunity>)records){
            if (o.AccountId != null && o.SBQQ__AmendedContract__c != null) {
                candidates.add(o);
                acctIds.add(o.AccountId);
            }
        }

        if (candidates.size() > 0 && acctIds.size() > 0) {
            Map<String, Account> accounts = new Map<String, Account>([Select ID, Name From Account Where Id in: acctIds and Name <> NULL]);
            
            for (Opportunity o : candidates) {
                Account a = accounts.get(o.AccountId);
                if (a != null && o.Name != null && o.Name.length() < 97) {
                    Integer remainLength = 97 - o.Name.length();
                    o.Name = a.Name.left(remainLength) + ' - ' + o.Name;
                }
            }
        }
    }

  //SFDC-13312 Renamed the method from BillingAggregator to populateFieldsAfterAccountChanges.
  //This method will be used to populate all end user/reseller/disti account based fields on Opportunity
   @testVisible
    private static void populateFieldsAfterAccountChanges(List<SObject> records, Map<Id, SObject> oldRecordMap) {
    //Map of opportunities in which bill to account changed. ID is the bill to account Id
    Map<Id,List<Opportunity>> billToAccountChangedOppMap = new Map<Id,List<Opportunity>>();

    //Map of opportunities in which end user account changed. ID is the end user account Id
    Map<Id,List<Opportunity>> endUserAccountChangedOppMap = new Map<Id,List<Opportunity>>();
    
    //Account Ids used to get account information for accounts identified in the changed opportunities
    Set<Id> acctIds = new Set<Id>();

    //Populate above defined maps and sets
    for (Opportunity newOpp : (List<Opportunity>)records){
      //Get old Opp
      Opportunity oldOpp = oldRecordMap == null ? new Opportunity() : (Opportunity)oldRecordMap.get(newOpp.Id);

      //if old opp is null, initialize it to a blank opportunity
      if (oldOpp == null){
        oldOpp = new Opportunity();
      }

      //Check if the bill to account has changed. This will change if End User/Reseller/Disti has changed.
      //This will be used to populate billing address
      if (newOpp.Bill_To_Account__c != null && newOpp.Bill_To_Account__c != oldOpp.Bill_To_Account__c) {
        if(billToAccountChangedOppMap.containsKey(newOpp.Bill_To_Account__c)){
          billToAccountChangedOppMap.get(newOpp.Bill_To_Account__c).add(newOpp);
        }
        else{
          billToAccountChangedOppMap.put(newOpp.Bill_To_Account__c, new List<Opportunity>{newOpp});
        }
        acctIds.add(newOpp.Bill_To_Account__c);
      }

      //Check if End User account has changed. This will be used to populate shipping address
      if (newOpp.AccountId != null && newOpp.AccountId != oldOpp.AccountId) {
        if(endUserAccountChangedOppMap.containsKey(newOpp.AccountId)){
          endUserAccountChangedOppMap.get(newOpp.AccountId).add(newOpp);
        }
        else{
          endUserAccountChangedOppMap.put(newOpp.AccountId, new List<Opportunity>{newOpp});
        }
        acctIds.add(newOpp.AccountId);
      }
    }

    //If accounts are identified then get account details
    if (acctIds.size() > 0) {
      //Loop through these accounts and populate related information in the opportunity
      for(Account currentAccount: [SELECT Id,
                                          (SELECT Id, Street__c, City__c, State_Name__c, Zip_Postal_Code__c, Country_Name__c, Country_ISO__c, Type__c FROM Addresses__r WHERE Primary__c = TRUE) 
                                   FROM Account 
                                   WHERE Id in: acctIds]){

        //Get the billing address and shipping address for the given account
        Address__c billingAddress;
        Address__c shippingAddress;

        for(Address__c addr: currentAccount.Addresses__r){
          if(addr.Type__c == 'Billing' && billingAddress==null){
            billingAddress = addr;
          }
          else if(addr.Type__c == 'Shipping' && shippingAddress==null){
            shippingAddress = addr;
          }
          if(billingAddress!=null && shippingAddress!=null){
            break;
          }
        }

        //For each account find the related oppties and update applicable address field
        //Opportunities with changed bill to account
        if(billToAccountChangedOppMap.containsKey(currentAccount.Id)){
          for(Opportunity billToAccountOpp: billToAccountChangedOppMap.get(currentAccount.Id)){
            if(billingAddress!=null){
              //Billing Address update
              billToAccountOpp.Billing_Address__c  = billingAddress.Id;
              billToAccountOpp.Street__c           = billingAddress.Street__c;
              billToAccountOpp.City__c             = billingAddress.City__c;
              billToAccountOpp.State__c            = billingAddress.State_Name__c;
              billToAccountOpp.Zip_Postal_Code__c  = billingAddress.Zip_Postal_Code__c;
              billToAccountOpp.Country__c          = billingAddress.Country_Name__c;
              billToAccountOpp.Country_ISO_Code__c = billingAddress.Country_ISO__c;
            }
          }
        }
        //Opportunities with changed end user account
        if(endUserAccountChangedOppMap.containsKey(currentAccount.Id)){
          for(Opportunity endUserAccountOpp: endUserAccountChangedOppMap.get(currentAccount.Id)){
                        
            if(shippingAddress!=null){
              //Shipping Address update
              endUserAccountOpp.Shipping_Address__c          = shippingAddress.Id;
              endUserAccountOpp.Ship_To_Account__c           = currentAccount.Id;
              endUserAccountOpp.Ship_To_Street__c            = shippingAddress.Street__c;
              endUserAccountOpp.Ship_To_City__c              = shippingAddress.City__c;
              endUserAccountOpp.Ship_To_State__c             = shippingAddress.State_Name__c;
              endUserAccountOpp.Ship_To_Zip_Postal_Code__c   = shippingAddress.Zip_Postal_Code__c;
              endUserAccountOpp.Ship_To_Country__c           = shippingAddress.Country_Name__c;
              endUserAccountOpp.Shipping_Country_ISO_Code__c = shippingAddress.Country_ISO__c;            
            }
          }
        }
      }  
    }
  } 

  @testVisible
    private static void checkForAccountsWithLargeAssets(List<SObject> records){
    // Retrieve settings from custom metadata type
    Opp_Creation_Settings__mdt oppCreateMetadata = [SELECT Id, QualifiedApiName, Asset_Volume_Threshold__c, Check_Asset_Volume_On_Account__c, Error_Message__c FROM Opp_Creation_Settings__mdt WHERE QualifiedApiName = 'Check_Asset' LIMIT 1];

    // Assign values based on the test context
    Integer assetVolumeThreshold = Test.isRunningTest() ? 2 : (Integer)oppCreateMetadata.Asset_Volume_Threshold__c;
    Boolean checkAssetVolumeOnAccount = Test.isRunningTest() || oppCreateMetadata.Check_Asset_Volume_On_Account__c;

    if(oppCreateMetadata != null && checkAssetVolumeOnAccount){
        Map<Id, List<Opportunity>> oppsByAccountIds = new Map<Id, List<Opportunity>>();
        for(SObject rec : records){
            Opportunity opp = (Opportunity)rec;
            if(opp.AccountId != null){
                if(!oppsByAccountIds.containsKey(opp.AccountId)){
                    oppsByAccountIds.put(opp.AccountId, new List<Opportunity>{opp});
                } else {oppsByAccountIds.get(opp.AccountId).add(opp); }
            }
        }

        // Process only if there are Opportunities grouped by AccountIds
        if(!oppsByAccountIds.isEmpty()){
            // Bulkified SOQL Query
            List<AggregateResult> aggregatedAssets = [SELECT AccountId, Count(Id) totalAssets FROM Asset WHERE AccountId IN :oppsByAccountIds.keySet() GROUP BY AccountId];

            for(AggregateResult aggregatedAsset : aggregatedAssets){
                Integer numOfAssets = (Integer)aggregatedAsset.get('totalAssets'); 
                Id accountId = (Id)aggregatedAsset.get('AccountId');

                if(numOfAssets > assetVolumeThreshold){
                    for(Opportunity opp : oppsByAccountIds.get(accountId)){opp.addError(oppCreateMetadata.Error_Message__c);
                    }
                }
            }
        }
    }
}


  /*private static void checkForAccountsWithLargeAssets(List<sobject> records){
    Opp_Creation_Settings__mdt oppCreateMetadata = [Select Id, QualifiedApiName, Asset_Volume_Threshold__c, Check_Asset_Volume_On_Account__c, Error_Message__c from Opp_Creation_Settings__mdt Where QualifiedApiName = 'Check_Asset'];

    Boolean checkAssetVolumeOnAccount;
    Integer AssetVolumeThreshold;

    if(!Test.isRunningTest()){
    checkAssetVolumeOnAccount = oppCreateMetadata.Check_Asset_Volume_On_Account__c;
    AssetVolumeThreshold = (Integer)oppCreateMetadata.Asset_Volume_Threshold__c;
    }
    else{
        checkAssetVolumeOnAccount = true;
        AssetVolumeThreshold = 2;
    }

    if(oppCreateMetadata != null && checkAssetVolumeOnAccount == true){

      map<Id,list<Opportunity>> oppsByAccountIds = new map<Id,list<Opportunity>>();

      for(sobject rec : records){
        Opportunity opp = (Opportunity) rec;
        if(opp.AccountId != null){
          if(!oppsByAccountIds.containsKey(opp.AccountId)){
            oppsByAccountIds.put(opp.AccountId,new List<Opportunity>{opp});
          }
          else{
            oppsByAccountIds.get(opp.AccountId).add(opp);
          }
        }

        if(!oppsByAccountIds.isEmpty()){
          List<AggregateResult> aggregatedAssets = [Select AccountId, Count(Name) from Asset Where AccountId IN: oppsByAccountIds.keySet() GROUP BY AccountId];
          for(AggregateResult aggregatedAsset : aggregatedAssets){
            Integer numOfAssets = (Integer)aggregatedAsset.get('expr0');
            system.debug('---num of assets---' + numOfAssets);
            system.debug('---threshold----' + oppCreateMetadata.Asset_Volume_Threshold__c);
            if(numOfAssets > AssetVolumeThreshold){
              String accountId = (String)aggregatedAsset.get('AccountId');
              system.debug('---accountId----' + accountId);
              List<Opportunity> opps = oppsByAccountIds.get(accountId);
              for(Opportunity op : opps){
                system.debug('---adding error----');
                op.addError(oppCreateMetadata.Error_Message__c);
              }
            }
          }
        }

      }   
    }
  }*/
    //SFDC-18936---Start
    public static void UpdateEarliestSubEndDate(List<SObject> records)
    {
        

            Date minimumDate;
            Set<Id> contractSet = new Set<Id>();
            

            // Storing contract id's from opportunity
            for(Opportunity opp : (List<Opportunity>) records)
            {
                system.Debug('Business group: '+opp.Business_Group__c);
                if(opp.SBQQ__RenewedContract__c!=null && opp.Business_Group__c=='Core' )
                {
                    system.Debug('SBQQ__RenewedContract__c '+opp.SBQQ__RenewedContract__c);
                    contractSet.add(opp.SBQQ__RenewedContract__c);
                } 
            }
            //Querying subcription by using contract Id's
            List<SBQQ__Subscription__c> subsList = [select Id, SBQQ__SubscriptionEndDate__c
                                                    from SBQQ__Subscription__c 
                                                    where SBQQ__Contract__c =: contractSet 
                                                    and SBQQ__RenewalQuantity__c >= 1];

            // getting the earliest date from all the subscription
        if(!subsList.isEmpty())  {
             for(SBQQ__Subscription__c subs : subsList)     
            {
                System.debug('minimumDate : '+minimumDate+' Subscription End Date : '+subs.SBQQ__SubscriptionEndDate__c);
                if(minimumDate==null || minimumDate > subs.SBQQ__SubscriptionEndDate__c)
                {
                    minimumDate = subs.SBQQ__SubscriptionEndDate__c;
                }
            }
			System.debug('minimumDate value before assignment : '+minimumDate);
            //updating opportunity
            
        }  
       
            for(Opportunity opp : (List<Opportunity>) records)
            {
                    if(minimumDate != null)
                    {
                      opp.Earliest_Subscription_End_Date__c = minimumDate;
                    }
            }
                

    }
}