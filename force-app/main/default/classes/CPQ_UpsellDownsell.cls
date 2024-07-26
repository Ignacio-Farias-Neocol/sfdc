/**
* @author Salesforce Services
* @date 02/18/2021
*
* @description Class containing logic related to upsell downsell process. 
*              This is a utility class used by other classes called by Quote_After_Save_Operations
* Modification: SFDC-14595 added the logic to copy Group Id from the Account product
8               SFDC-14654 added the logic to ensure that Group Id is carried over to -ve lines
                when Group creation and reconfiguratio happens in the same transaction
*/
public with sharing class CPQ_UpsellDownsell {
  //Set of product codes for the Account Level products
  private static Set<String> accountProductCodeReferenceSet = new Set<String>();

  //Set of product codes for Level 1
  private static Set<String> level1ProductCodeSet = new Set<String>(); 

  static{
    for(Upsell_Downsell_Settings__mdt setting: [SELECT DeveloperName, 
                                                       Settings_Value__c 
                                                FROM Upsell_Downsell_Settings__mdt 
                                                WHERE DeveloperName in ('Account_Products','Level1_Bundle')]){
      
      //Populate accountProductCodeReferenceSet
      if(String.isNotBlank(setting.Settings_Value__c)){
        switch on setting.DeveloperName {
          when 'Account_Products' {
            accountProductCodeReferenceSet.addAll(setting.Settings_Value__c.split(','));
          }	
          when 'Level1_Bundle' {
            level1ProductCodeSet.addAll(setting.Settings_Value__c.split(',')); 
          }
          when else {
            //Do Nothing
          }
        }
      }
    } //END OF CUSTOM METADATA LOOP
  }

  /** Logic summary
   * 1.Loop through all quote lines and get subscription from the quote lines from Renewed Subscription field
   * 2. Get contract Id from the given quote Id
   * 3. Using the contract get the list of Subscription
   * 4. Check if all subs under the contract have a corresponding QL with renewed subscription. 
   *    Create a negative line if any subs don't have a match. Make sure that group id (if it exists) from the account prouct is copied. 
   * 5. For new lines that do not have Renewed Subscription field populated, identify the matching sub and populate 'Upsell/Downsell Subscription' field.
   */
  public static void updateRenewalQuoteUpsellDownsell(List<Id> quoteIdList){

    //Map containing Quote Id - Quote record relationship to fetch quote info
    Map<Id, SBQQ__Quote__c> quoteRecordMap = new Map<Id,SBQQ__Quote__c>();

    //Map containing information about the Quote-Contract relationship
    Map<Id,List<Id>> contractQuoteMap = new Map<Id,List<Id>>();

    //Map containing Quote-Sub Id record relationship
    Map<Id,Set<Id>> quoteSubMap = new Map<Id,Set<Id>>();

    //Map of Quote ID and map of product code and QL. For each quote, this map keeps a map of product code of each quoteline. 
    //Used to populate upsell/downsell sub on new lines
    Map<Id, Map<String,Id>> quoteProductQLMap = new Map<Id, Map<String,Id>>();

    //Map containing Quote Id and record of missing sub for Level 1. this will be used to create missing quote line
    Map<Id, List<SBQQ__Subscription__c>> quoteLevelOneMissingSubMap = new Map<Id, List<SBQQ__Subscription__c>>();

    //Once quote lines for the level 1 one missing subs are inserted, following map will be used to create dependent quote lines for missing subs
    Map<Id, List<SBQQ__Subscription__c>> quoteDependentMissingSubMap = new Map<Id, List<SBQQ__Subscription__c>>();

    //Map of quote and quote line for the account products
    Map<Id,SBQQ__QuoteLine__c> quoteAccountQLMap = new Map<Id,SBQQ__QuoteLine__c>(); 

    //List of level 1 quote lines to be added if they are missing
    // This list also contains new quote lines that need to be updated with upsell/downsell sub
    List<SBQQ__QuoteLine__c> qlUpsertList = new List<SBQQ__QuoteLine__c>();

    //Map of bundle product code and bundle quote lines to be updated
    Map<String,SBQQ__QuoteLine__c> qlUpsertMap = new Map<String,SBQQ__QuoteLine__c>();

    //List of bundle items quote lines to be added
    List<SBQQ__QuoteLine__c> newDependentQuoteLines = new List<SBQQ__QuoteLine__c>();

    //SBQQ__Number__c starter. This can be any number but need to make sure that they are unique for each QL.
    Integer nextNum = 9000;

    //Set of Product Ids related to missing subscription in upsell quote
    Set<Id> missingSubProductSet = new Set<Id>();

    //Set of PricebookIds in the quote
    Set<Id> quotePricebookId = new Set<Id>();

    //Map of ProductCode + PricebookId to PriceBookEntry
    Map<String,Id> productPriceBookPBEMap = new Map<String,Id>();

    //Map of quoteId + subscriptionId to quoteLineId
    Map<String,Id> quoteSubQLMap = new Map<String,Id>();

    //SFDC-14654: Map of Quote > Quotelines that need only group id update
    Map<Id,List<Id>> quotelineGroupUpdateMap = new Map<Id,List<Id>>();    

    //Instantiate the log class to capture logs
    LogModel log = LogModel.startLog('CPQ_UpsellDownsell', 
                                      'updateRenewalQuoteUpsellDownsell',
                                      LogModel.LOG_CATEGORY_APEX);

    try {
      //LOG
      log.addLog('Quote Ids: ' + quoteIdList);

      //Loop through the quotes and prepare a map of Contract Id and Quote Id
      for(SBQQ__Quote__c quoteRecord: [SELECT Id,
                                              SBQQ__StartDate__c,
                                              SBQQ__PricebookId__c,
                                              SBQQ__Opportunity2__r.SBQQ__RenewedContract__c ,
                                              (SELECT Id,
                                                      SBQQ__Quote__c,
                                                      SBQQ__ProductCode__c,
                                                      SBQQ__RenewedAsset__c,
                                                      SBQQ__RenewedSubscription__c,
                                                      Upsell_Downsell_Subscription__c,
                                                      SBQQ__OptionLevel__c,
                                                      SBQQ__Group__c 
                                              FROM SBQQ__LineItems__r)
                                          FROM SBQQ__Quote__c 
                                          WHERE Id in :quoteIdList]){

        //Add quote to quote record map to fetch quote information later
        quoteRecordMap.put(quoteRecord.Id, quoteRecord);

        //Prepare the quote pricebook Id set
        quotePricebookId.add(quoteRecord.SBQQ__PricebookId__c);

        //Check if the contract map contains this contract
        if(contractQuoteMap.containsKey(quoteRecord.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c)){
          contractQuoteMap.get(quoteRecord.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c).add(quoteRecord.Id);
        }
        else{
          contractQuoteMap.put(quoteRecord.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c, new List<Id>{quoteRecord.Id});
        }

        //prepare map of quote Id and the set of subscriptions defined in this quote line of this quote
        if(quoteRecord.SBQQ__LineItems__r!=null && !quoteRecord.SBQQ__LineItems__r.isEmpty()){

          //Create an entry for this quote by instantiating an empty set
          quoteSubMap.put(quoteRecord.id, new Set<Id>());
          //Loop through quote lines of each quote and populate the map with sub Ids
          for(SBQQ__QuoteLine__c ql: quoteRecord.SBQQ__LineItems__r){
            
            //Check if the Quote line product code is one of the product codes corresponding to Account
            //Currently checking for BEOi001a and BEO001a. Get this from custom metadata so that this can be added later
            if(ql.SBQQ__RenewedAsset__c!=null && accountProductCodeReferenceSet.contains(ql.SBQQ__ProductCode__c)){
              quoteAccountQLMap.put(quoteRecord.Id, ql);
            }
            else if(ql.SBQQ__RenewedSubscription__c!=null){
              //Add the subscription Id to the quote-sub map
              quoteSubMap.get(quoteRecord.Id).add(ql.SBQQ__RenewedSubscription__c);

              //SFDC-14654 Check that the quote line with renewed subscription has a group as well
              //If the quoteline does not have group then add it.
              if(String.isBlank(ql.SBQQ__Group__c)){
                if(quotelineGroupUpdateMap!=null){
                  if(quotelineGroupUpdateMap.containsKey(quoteRecord.Id)){
                    quotelineGroupUpdateMap.get(quoteRecord.Id).add(ql.Id);
                  }
                  else{
                    quotelineGroupUpdateMap.put(quoteRecord.Id, new List<Id>{ql.Id});
                  }
                }
              }
              // END OF SFDC-14654
            }
            else if(ql.SBQQ__RenewedSubscription__c==null && 
                    ql.Upsell_Downsell_Subscription__c ==null){
              //Add an entry into product and QL map
              if(ql.SBQQ__OptionLevel__c == 1 && level1ProductCodeSet.contains(ql.SBQQ__ProductCode__c)){
                if(quoteProductQLMap.containsKey(quoteRecord.Id)){
                  quoteProductQLMap.get(quoteRecord.Id).put('BUNDLE_PARENT',ql.Id);
                }
                else{
                  quoteProductQLMap.put(quoteRecord.Id, new Map<String,Id>{'BUNDLE_PARENT'=>ql.Id});
                }
              }
              else{
                if(quoteProductQLMap.containsKey(quoteRecord.Id)){
                  quoteProductQLMap.get(quoteRecord.Id).put(ql.SBQQ__ProductCode__c,ql.Id);
                }
                else{
                  quoteProductQLMap.put(quoteRecord.Id, new Map<String,Id>{ql.SBQQ__ProductCode__c=>ql.Id});
                }
              }
            }        
          } //END OF QUOTE LINE LOOP
        }
      } //END OF QUOTE LOOP

      //LOG
      log.addLog('quotePricebookId: ' + quotePricebookId);
      log.addLog('contractQuoteMap: ' + contractQuoteMap);
      system.debug('contracquotemap: ' + contractQuoteMap);
      log.addLog('quoteSubMap: ' + quoteSubMap);
      log.addLog('quoteAccountQLMap: ' + quoteAccountQLMap);
      log.addLog('quoteProductQLMap: ' + quoteProductQLMap);
      log.addLog('quotelineGroupUpdateMap: ' + quotelineGroupUpdateMap);

      //SFDC-14654 Check if Account product is in a group. 
      if(quoteAccountQLMap!=null && 
        !quoteAccountQLMap.isEmpty() && 
        quotelineGroupUpdateMap!=null && 
        !quotelineGroupUpdateMap.isEmpty()){
        for(SBQQ__QuoteLine__c accountQL: quoteAccountQLMap.values()){
          if(String.isNotBlank(accountQL.SBQQ__Group__c)){
            for(Id qlId: quotelineGroupUpdateMap.get(accountQL.SBQQ__Quote__c)){
              qlUpsertList.add(new SBQQ__QuoteLine__c(Id = qlId,
                                                      SBQQ__Group__c = accountQL.SBQQ__Group__c));
            }
          }
        }
      }
      //END OF SFDC-14654      

      //Get contract and sub details if contractQuoteMap is not empty
      //Match subs from contract with those fetched from QL
      if(contractQuoteMap!=null && !contractQuoteMap.isEmpty()){
        for(Contract contractRecord: [SELECT Id,
                                            (SELECT Id,
                                                    Product_Code__c,
                                                    SBQQ__RequiredById__c,
                                                    SBQQ__OptionLevel__c,
                                                    SBQQ__RequiredByProduct__r.ProductCode,
                                                    SBCF_Serial_Number__c,
                                                    SBQQ__ProductOption__c,
                                                    Current_Quantity__c,
                                                    OriginalSalePrice__c,
                                                    RevRecStartDate__c,
                                                    RevRecAdjustedDate__c,
                                                    SBQQ__Product__c,
                                                    SBQQ__SubscriptionStartDate__c,
                                                    Original_Order_Id__c,
                                                    Original_OrderItem_Id__c,
                                                    Original_Order_Number__c,
                                                    Active__c
                                            FROM SBQQ__Subscriptions__r 
                                            WHERE SBQQ__RevisedSubscription__c = null)
                                      FROM Contract 
                                      WHERE Id in :contractQuoteMap.keySet()]){

          //Loop through Subscription and identify missing subs in each of the quotes tied to this contract
          for(SBQQ__Subscription__c subRecord: contractRecord.SBQQ__Subscriptions__r){
            log.addLog('Contract Sub: ' + subRecord.Id);

            //Loop through each of the quotes. Get these quotes using the contractQuoteMap which contains List of Quote IDs for each of the contracts
            for(Id currentQuoteId: contractQuoteMap.get(contractRecord.Id)){

              //prepare quote lines for updating upsell downsell sub field
              if(quoteProductQLMap!=null){
                if(quoteProductQLMap.containsKey(currentQuoteId) && 
                    quoteProductQLMap.get(currentQuoteId).containskey(subRecord.Product_Code__c) && 
                    !qlUpsertMap.containsKey(subRecord.Product_Code__c)){
                  qlUpsertMap.put(subRecord.Product_Code__c,new SBQQ__QuoteLine__c(Id = quoteProductQLMap.get(currentQuoteId).get(subRecord.Product_Code__c),
                                                                                    Upsell_Downsell_Subscription__c = subRecord.Id));
                }
                else if(quoteProductQLMap.containsKey(currentQuoteId) && 
                        subRecord.SBQQ__OptionLevel__c == 1 && 
                        quoteProductQLMap.get(currentQuoteId).containsKey('BUNDLE_PARENT') &&
                        !qlUpsertMap.containsKey('BUNDLE_PARENT')){
                  qlUpsertMap.put('BUNDLE_PARENT',new SBQQ__QuoteLine__c(Id = quoteProductQLMap.get(currentQuoteId).get('BUNDLE_PARENT'),
                                                                          Upsell_Downsell_Subscription__c = subRecord.Id));
                }
              } 

              //Use quote sub map to get subs tied to the quote. 
              if(quoteSubMap !=null && !quoteSubMap.isEmpty() && subRecord.Active__c){
                //For each of the quote, get the set of subscriptions that we obtained from related quote lines
                //Check whether the current subscription in the loop is present in the map
                //If it is not present then add this subscription to the map containing quote and related subs that don't have corresponding quote lines
                if(quoteSubMap.containsKey(currentQuoteId) && //Quote present in the map
                (quoteSubMap.get(currentQuoteId) == null || //Quote does not have set of sub Ids
                quoteSubMap.get(currentQuoteId).isEmpty() || // Quote has a set of subs but the set is empty 
                !quoteSubMap.get(currentQuoteId).contains(subRecord.Id))){ //Set of Subs for this quote does not have this Sub

                  //Add the missing product code
                  missingSubProductSet.add(subRecord.SBQQ__Product__c);

                  //Separate out these subs based on the option level and required by fields
                  //Check for Level 1 missing Subs
                  if(subRecord.SBQQ__OptionLevel__c == 1){
                    //Subscription is missing. Add it. 
                    if(quoteLevelOneMissingSubMap.containsKey(currentQuoteId)){
                      quoteLevelOneMissingSubMap.get(currentQuoteId).add(subRecord);
                    }
                    else{
                      quoteLevelOneMissingSubMap.put(currentQuoteId,new List<SBQQ__Subscription__c>{subRecord});
                    }
                  }
                  //Check for bundle items missing subs
                  else if(level1ProductCodeSet.contains(subRecord.SBQQ__RequiredByProduct__r.ProductCode)){
                    //Subscription is missing. Add it. 
                    if(quoteDependentMissingSubMap.containsKey(currentQuoteId)){
                      quoteDependentMissingSubMap.get(currentQuoteId).add(subRecord);
                    }
                    else{
                      quoteDependentMissingSubMap.put(currentQuoteId,new List<SBQQ__Subscription__c>{subRecord});
                    }
                  }
                }
              }
            } // END OF QUOTE ID LOOP FOR EACH CONTRACT
          } //END OF SUBSCRIPTION LOOP FOR EACH CONTRACT
        } //END OF CONTRACT LOOP
      }
      log.addLog('qlUpsertMap: ' + qlUpsertMap );
      //If qlUpsertMap is not empty then add values to the upsert list
      if(qlUpsertMap!=null && !qlUpsertMap.isEmpty()){
        qlUpsertList.addAll(qlUpsertMap.values());
      }

      //LOG
      log.addLog('Level 1 missing sub: ' + quoteLevelOneMissingSubMap.size());
      log.addLog('Bundle item missing sub: ' + quoteDependentMissingSubMap.size());

      //If quoteLevelOneMissingSubMap is not empty then prepare quote lines and add them to quote
      if(quoteLevelOneMissingSubMap!=null && !quoteLevelOneMissingSubMap.isEmpty()){

        //Get Pricebookentries using the missingSubProductSet and quotePricebookId
        for(PricebookEntry pbe: [SELECT Id,
                                        Product2Id,
                                        Pricebook2Id
                                FROM PricebookEntry 
                                WHERE Product2Id in :missingSubProductSet 
                                AND Pricebook2Id in :quotePricebookId]){
          productPriceBookPBEMap.put(String.valueOf(pbe.Product2Id )+ String.valueOf(pbe.Pricebook2Id), pbe.Id);
        }

        //LOG
        log.addLog('Product PBE Map: ' + productPriceBookPBEMap); 

        //Add quote lines for missing level 1 subs
        for(Id currentQuoteId: quoteLevelOneMissingSubMap.keySet()){
          //Get the subscription record
          for(SBQQ__Subscription__c sub: quoteLevelOneMissingSubMap.get(currentQuoteId)){
            nextNum += 1; //Increment nextNum
            SBQQ__QuoteLine__c newBundleQL = setQLFields(sub, quoteRecordMap.get(currentQuoteId), nextNum);
            newBundleQL.SBQQ__PricebookEntryId__c    = productPriceBookPBEMap.get(sub.SBQQ__Product__c+ quoteRecordMap.get(currentQuoteId).SBQQ__PricebookId__c);
            newBundleQL.SBQQ__RequiredBy__c          = quoteAccountQLMap.get(currentQuoteId)?.Id;
            newBundleQL.SBQQ__OptionLevel__c         = 1;
            newBundleQL.SBQQ__Group__c               = quoteAccountQLMap.get(currentQuoteId)?.SBQQ__Group__c;
            //Add it to the insert list
            qlUpsertList.add(newBundleQL);

          } //END OF LEVEL1 MISSING SUB LOOP FOR EACH QUOTE
        } //END OF LEVEL1 MISSING SUB MAP LOOP

      }
      
      //Upsert quote lines. This list may contain new QL for -ve lines and existing QL for updating Upsell_Downsell_Subscription__c.
      if(qlUpsertList!=null && !qlUpsertList.isEmpty()){
        //LOG
        log.addLog('UpsertList: ' + qlUpsertList.size()); 
        for(SBQQ__QuoteLine__c ql: qlUpsertList){
          if(ql.Id!=null){
            log.addLog('QuoteLineId: ' + ql.id);
          }
        } 

        //Disable CPQ triggers within the current transaction
        SBQQ.TriggerControl.disable();

        //Insert level 1 QL
        saveQL(qlUpsertList, log);

        //Enable trigger
        SBQQ.TriggerControl.enable();

        //We need to do the following only if there are missing -ve lines.
        if(quoteLevelOneMissingSubMap!=null && 
            !quoteLevelOneMissingSubMap.isEmpty() && 
            quoteDependentMissingSubMap!=null && 
            !quoteDependentMissingSubMap.isEmpty()){

          //prepare a map of quote_subscriptionID as the key and level1 quote line id as the value
          for(SBQQ__QuoteLine__c newQL: qlUpsertList){
            if(newQl.SBQQ__Quote__c!=null && newQL.SBQQ__RenewedSubscription__c!=null){
              quoteSubQLMap.put(String.valueOf(newQl.SBQQ__Quote__c)+String.valueOf(newQl.SBQQ__RenewedSubscription__c), newQL.Id);
            }
            
          }

          //LOG
          log.addLog('Quote Sub QL Map: ' + quoteSubQLMap); 

          ////Loop through quoteDependentMissingSubMap to add dependent quote lines  
          for(Id currentQuoteId: quoteDependentMissingSubMap.keySet()){
            //Get the subscription record
            for(SBQQ__Subscription__c sub: quoteDependentMissingSubMap.get(currentQuoteId)){
              nextNum += 1; //Increment nextNum
              SBQQ__QuoteLine__c newsubQl = setQLFields(sub, quoteRecordMap.get(currentQuoteId), nextNum);
              newsubQL.SBQQ__PricebookEntryId__c    = productPriceBookPBEMap.get(sub.SBQQ__Product__c+ quoteRecordMap.get(currentQuoteId).SBQQ__PricebookId__c);
              newsubQL.SBQQ__RequiredBy__c          = quoteSubQLMap.get(currentQuoteId+sub.SBQQ__RequiredById__c);
              newsubQL.SBQQ__Hidden__c              = true;
              newsubQL.SBQQ__OptionLevel__c         = 2;
              newsubQL.SBQQ__Group__c               = quoteAccountQLMap.get(currentQuoteId)?.SBQQ__Group__c;

              //Add it to the insert list
              newDependentQuoteLines.add(newSubQL); 
            } //END OF DEPENDENT MISSING SUB LOOP FOR EACH QUOTE
          } //END OF DEPENDENT MISSING SUB MAP LOOP

          if(newDependentQuoteLines!=null && !newDependentQuoteLines.isEmpty()){
            //LOG 
            log.addLog('New bundle items QL: ' + newDependentQuoteLines.size());  
            //Insert dependent QL
            saveQL(newDependentQuoteLines, log);
          }
        } 
      }   

      //End Log
      log.endLog('End of Log');
    }
    catch (Exception ex) {
      log.addExceptionLog(ex);
    }      
  }  

    /** Logic summary
   * 1.Loop through all quote lines and get subscription from the quote lines that do not have SBQQ__UpgradedSubscription__c and upsell downsell subscription
   * 2. Get contract Id from the given quote Id
   * 3. Using the contract get the list of Subscription
   * 4. For new lines that do not have SBQQ__UpgradedSubscription__c field populated, identify the matching sub and populate 'Upsell/Downsell Subscription' field.
   */
  public static void updateAmendmentQuoteUpsellDownsell(List<Id> quoteIdList){
    
    //Map containing information about the Quote-Contract relationship
    Map<Id,List<Id>> contractQuoteMap = new Map<Id,List<Id>>();

    //Map of product code and QL. To be used to populate upsell/downsell sub
    Map<Id, Map<String,Id>> quoteProductQLMap = new Map<Id, Map<String,Id>>();

    //List of level 1 quote lines to be added and bundle and bundle quote lines to be updated
    Map<String,SBQQ__QuoteLine__c> qlUpsertMap = new Map<String,SBQQ__QuoteLine__c>();

    //Instantiate the log class to capture logs
    LogModel log = LogModel.startLog('CPQ_UpsellDownsell', 
                                     'updateAmendmentQuoteUpsellDownsell',
                                     LogModel.LOG_CATEGORY_APEX);

    try {
      //LOG
      log.addLog('Quote Ids: ' + quoteIdList);

      //Loop through the list and prepare a map of Contract Id and Quote Id
      for(SBQQ__Quote__c quoteRecord: [SELECT Id,
                                              SBQQ__StartDate__c,
                                              SBQQ__PricebookId__c,
                                              SBQQ__Opportunity2__r.SBQQ__AmendedContract__c ,
                                              (SELECT Id,
                                                      SBQQ__ProductCode__c,
                                                      SBQQ__UpgradedAsset__c,
                                                      SBQQ__UpgradedSubscription__c,
                                                      Upsell_Downsell_Subscription__c,
                                                      SBQQ__OptionLevel__c 
                                              FROM SBQQ__LineItems__r)
                                          FROM SBQQ__Quote__c 
                                          WHERE Id in :quoteIdList]){

        //Check if the contract map contains this contract
        if(contractQuoteMap.containsKey(quoteRecord.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c)){
          contractQuoteMap.get(quoteRecord.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c).add(quoteRecord.Id);
        }
        else{
          contractQuoteMap.put(quoteRecord.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c, new List<Id>{quoteRecord.Id});
        }

        //prepare map of quote Id and a map of product code to ql id without upgraded subscription
        if(quoteRecord.SBQQ__LineItems__r!=null && !quoteRecord.SBQQ__LineItems__r.isEmpty()){

          //Loop through quote lines of each quote and populate the map with sub Ids
          for(SBQQ__QuoteLine__c ql: quoteRecord.SBQQ__LineItems__r){

            if(ql.SBQQ__UpgradedAsset__c==null &&
               ql.SBQQ__UpgradedSubscription__c==null && 
               ql.Upsell_Downsell_Subscription__c ==null){
              //Add an entry into product and QL map
              if(ql.SBQQ__OptionLevel__c == 1 && level1ProductCodeSet.contains(ql.SBQQ__ProductCode__c)){
                if(quoteProductQLMap.containsKey(quoteRecord.Id)){
                  quoteProductQLMap.get(quoteRecord.Id).put('BUNDLE_PARENT',ql.Id);
                }
                else{
                  quoteProductQLMap.put(quoteRecord.Id, new Map<String,Id>{'BUNDLE_PARENT'=>ql.Id});
                }
              }
              else{
                if(quoteProductQLMap.containsKey(quoteRecord.Id)){
                  quoteProductQLMap.get(quoteRecord.Id).put(ql.SBQQ__ProductCode__c,ql.Id);
                }
                else{
                  quoteProductQLMap.put(quoteRecord.Id, new Map<String,Id>{ql.SBQQ__ProductCode__c=>ql.Id});
                }
              }
            }        
          } //END OF QUOTE LINE LOOP
        }
      } //END OF QUOTE LOOP

      //LOG
      log.addLog('Contract Quote Map: ' + contractQuoteMap);
      log.addLog('Product Map: ' + quoteProductQLMap);

      //Get contract and sub details if contractQuoteMap is not empty
      //Match subs from contract with those fetched from QL
      if(contractQuoteMap!=null && !contractQuoteMap.isEmpty()){
        for(Contract contractRecord: [SELECT Id,
                                            (SELECT Id,
                                                    Product_Code__c,
                                                    SBQQ__OptionLevel__c
                                            FROM SBQQ__Subscriptions__r 
                                            WHERE Active__c = TRUE 
                                            AND SBQQ__RevisedSubscription__c = null)
                                      FROM Contract 
                                      WHERE Id in :contractQuoteMap.keySet()]){

          //Loop through Subscription and identify missing subs in each of the quotes tied to this contract
          for(SBQQ__Subscription__c subRecord: contractRecord.SBQQ__Subscriptions__r){
            log.addLog('Contract Sub: ' + subRecord.Id);

            //Loop through each of the quotes. Get these quotes using the contractQuoteMap which contains List of Quote IDs for each of the contracts
            for(Id currentQuoteId: contractQuoteMap.get(contractRecord.Id)){
              //prepare quote lines for updating upsell downsell sub field
              if(quoteProductQLMap!=null){
                if(quoteProductQLMap.containsKey(currentQuoteId) && 
                   quoteProductQLMap.get(currentQuoteId).containskey(subRecord.Product_Code__c) && 
                   !qlUpsertMap.containsKey(subRecord.Product_Code__c)){
                  qlUpsertMap.put(subRecord.Product_Code__c,new SBQQ__QuoteLine__c(Id = quoteProductQLMap.get(currentQuoteId).get(subRecord.Product_Code__c),
                                                                                   Upsell_Downsell_Subscription__c = subRecord.Id));
                }
                else if(quoteProductQLMap.containsKey(currentQuoteId) && 
                        subRecord.SBQQ__OptionLevel__c == 1 && 
                        quoteProductQLMap.get(currentQuoteId).containsKey('BUNDLE_PARENT') &&
                        !qlUpsertMap.containsKey('BUNDLE_PARENT')){
                  qlUpsertMap.put('BUNDLE_PARENT',new SBQQ__QuoteLine__c(Id = quoteProductQLMap.get(currentQuoteId).get('BUNDLE_PARENT'),
                                                                          Upsell_Downsell_Subscription__c = subRecord.Id));
                }
              } 
            } // END OF QUOTE ID LOOP FOR EACH CONTRACT
          } //END OF SUBSCRIPTION LOOP FOR EACH CONTRACT
        } //END OF CONTRACT LOOP
      }

      //Upsert quote lines.
      if(qlUpsertMap!=null && !qlUpsertMap.isEmpty()){
        //LOG
        log.addLog('Upsert List ' + qlUpsertMap.size()); 

        //Disable CPQ triggers within the current transaction
        SBQQ.TriggerControl.disable();

        //Insert level 1 QL
        saveQL(qlUpsertMap.values(), log);

        //Enable trigger
        SBQQ.TriggerControl.enable();       
      }   

      //End Log
      log.endLog('End of Log');
    }
    catch (Exception ex) {
      log.addExceptionLog(ex);
    }
  } 

  //Method to set Quoteline fields
  private static SBQQ__QuoteLine__c setQLFields(SBQQ__Subscription__c sub,
                                                SBQQ__Quote__c quote, 
                                                Integer nextNum){
    SBQQ__QuoteLine__c newQL = new SBQQ__QuoteLine__c();
    newQL.SBQQ__Quantity__c            = 0;
    newQL.SBCF_Serial_Number__c        = sub.SBCF_Serial_Number__c;
    newQL.RevRecStartDate__c           = sub.RevRecStartDate__c;
    newQL.RevRecAdjustedDate__c        = sub.RevRecAdjustedDate__c;
    newQL.SBQQ__ProductOption__c       = sub.SBQQ__ProductOption__c;
    newQL.SBQQ__PriorQuantity__c       = sub.Current_Quantity__c;
    newQL.OriginalSalePrice__c         = sub.OriginalSalePrice__c;
    newQL.SBQQ__RenewedSubscription__c = sub.id;    
    newQL.SBQQ__Quote__c               = quote.Id;
    newQL.SBQQ__StartDate__c           = sub.SBQQ__SubscriptionStartDate__c;
    newQL.SBQQ__EndDate__c             = quote?.SBQQ__StartDate__c;
    newQL.SBQQ__Existing__c            = true;
    newQL.SBQQ__SubscriptionPricing__c = 'Fixed Price';
    newQL.SBQQ__Number__c              = nextNum;
    newQL.SBQQ__Product__c             = sub.SBQQ__Product__c;
    newQL.Original_Order_Id__c         = sub.Original_Order_Id__c;
    newQL.Original_OrderItem_Id__c     = sub.Original_OrderItem_Id__c;
    newQL.Original_Order_Number__c     = sub.Original_Order_Number__c;
    newQL.isRenewalCrossGrade__c       = true;

    return newQL;
  }

  //Method to save quotelines and log errors if any
  private static void saveQL(List<SBQQ__QuoteLine__c> qlList, LogModel log){
    Database.UpsertResult[] srList = Database.upsert(qlList, SBQQ__QuoteLine__c.Fields.Id,false); //Partial insert allowed
    for(Database.UpsertResult sr: srList){
      if(!sr.isSuccess()){
        String errorMessage = 'Error: ';
        for(Database.Error error: sr.getErrors()){
          errorMessage += error;
        }
        //LOG
        //log.addLog(errorMessage); 
        System.debug('QL Error Message: ' + errorMessage);
      }
    } //END OF SR LOOP
  }  
}