/**
* @author Salesforce Services
* @date 2020-8-25
*
* @group VF Controller
*
* @description:
*   SFDC-12959 - VF page controller for providing mass cloning functionality for amend
*/
public with sharing class MassAmendLineItemsController {
  private Id quoteId;
  
  //Map of all filtered quote lines and their id. This is presented to the user.
  private Map<Id, SBQQ__QuoteLine__c> quoteLines;

  //Map of quote line Id and it's children in the bundle
  private Map<Id, List<SBQQ__QuoteLine__c>> quoteLineBundleMap;

  //List used to capture quote line Ids selected for cloning
  public List<MassAmendLineItemsController.QuoteLineSelection> quoteLineIds{get;set;}

  //Text containing the message to be shown
  public String message {get;set;}

  //List of Fieldset Members used to draw table columns
  transient List<Schema.FieldSetMember> fsmList;

  //These are switches to cover catch blocks. The purpose of this is to elevate the test class code coverage.
  public Boolean testRunningFlag = false;

  //Returns quote lines that are eligible for cloning
  public Map<Id, SBQQ__QuoteLine__c> getMassAmendQL(){
      return quoteLines;
  }

  //Returns fieldset members for the columns to be shown
  public List<Schema.FieldSetMember> getFSMList() {
    if(fsmList == null) {
      fsmList = SObjectType.SBQQ__QuoteLine__c.FieldSets.Mass_Amend_Table_Columns.getFields();
    }
    return fsmList;
  }

  // Class constructor.
  public MassAmendLineItemsController(ApexPages.StandardController controller) {

    try{
      //Get the parameters
      quoteId = controller.getId();

      // Throw an error if the required parameters is null
      if(String.isBlank(quoteId)) {
        // ApexPages.addMessage(new ApexPages.Message( ApexPages.Severity.ERROR, 
        //                                             'No quoteId parameter found.'));
        message = System.Label.Mass_Amend_Missing_QuoteId;
        return ;
      }
      
      // Query all fields from the collected quote line ids
      if(quoteId != null) {
        quoteLines = new Map<Id, SBQQ__QuoteLine__c>();
        quoteLineBundleMap = new Map<Id, List<SBQQ__QuoteLine__c>>();

        String query = 'SELECT Id,'+
                        'SBQQ__Product__r.SBQQ__SubscriptionTerm__c,' +
                        'SBQQ__Quote__r.SBQQ__Type__c,' +
                        'SBQQ__UpgradedSubscription__r.SBQQ__NetPrice__c,' + 
                        'SBQQ__UpgradedSubscription__r.SBQQ__CustomerPrice__c,' + 
                        'SBQQ__UpgradedSubscription__r.SBQQ__RegularPrice__c,' +
                        'SBQQ__UpgradedSubscription__r.Current_Quantity__c,';

        List<String> fieldsList = new List<String>();

        //Get fields for query by accessing the Amendment_Clone_Fields fieldset
        for(Schema.FieldSetMember fsm : SObjectType.SBQQ__QuoteLine__c.FieldSets.Amendment_Clone_Fields.getFields()) {
          fieldsList.add(fsm.getFieldPath());
        }
        
        query += String.join(fieldsList, ',') + ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quoteId';

        //Query the custom metadata 'Mass Amend Quote Line Filter' to add more filter conditions
        for(Mass_Amend_Quote_Line_Filter__mdt additionalFilter : [SELECT QuoteLine_FieldName__c,
                                                                            Operator__c,
                                                                            Value__c 
                                                                    FROM Mass_Amend_Quote_Line_Filter__mdt]){
          query += ' AND ' + additionalFilter.QuoteLine_FieldName__c + ' ' + additionalFilter.Operator__c + ' ' + additionalFilter.Value__c;
        }
        
        //Order quotelines
        query+= ' ORDER BY Name';

        //Print the query in debug log
        system.debug('QUERY' +  query);

        //Initialize quotelineIds
        quoteLineIds = new List<MassAmendLineItemsController.QuoteLineSelection>();

        //Build quoteLines map, quoteLineIds list and the map of quote line and it's children in a bundle
        for(SBQQ__QuoteLine__c quoteLineRecord : Database.query(query)) {
          quoteLines.put(quoteLineRecord.Id, quoteLineRecord);
          quoteLineIds.add(new MassAmendLineItemsController.QuoteLineSelection(false, quoteLineRecord.Id));

          //Bundle map
          if(quoteLineBundleMap!=null && quoteLineRecord.SBQQ__RequiredBy__c!=null){
            if(quoteLineBundleMap.containsKey(quoteLineRecord.SBQQ__RequiredBy__c)){
              quoteLineBundleMap.get(quoteLineRecord.SBQQ__RequiredBy__c).add(quoteLineRecord);
            }
            else{
              quoteLineBundleMap.put(quoteLineRecord.SBQQ__RequiredBy__c, new List<SBQQ__QuoteLine__c>{quoteLineRecord});
            }
          }
        } //END FOR

        //Message if no quote lines are found
        if(quoteLineIds==null || quoteLineIds.isEmpty()){
          message = System.Label.Mass_Amend_No_Quote_Lines;
        }
      }     
    }
    catch(Exception e){
      message = System.Label.Mass_Amend_Fetch_Error + e.getMessage();
    }
  }

  // Method that executes the cloning action.
  public PageReference copyQuoteLineItems() {

    //Set up the savepoint before initiating the process of cloning
    Savepoint sp = Database.setSavepoint();

    try{
      // Map of the original quote line id to its clone
      Map<Id, SBQQ__QuoteLine__c> mapOrigIdToCloned_Parent = new Map<Id, SBQQ__QuoteLine__c>();
      //Non bundle quotelines clone map
      Map<Id, SBQQ__QuoteLine__c> mapOrigIdToCloned_BundleItems = new Map<Id, SBQQ__QuoteLine__c>();
      //Original quoteline to be updated
      List<SBQQ__QuoteLine__c> originalQuoteLinesToBeUpdated = new List<SBQQ__QuoteLine__c>();
      //Based on the user selection determine the quote lines to be cloned
      for(MassAmendLineItemsController.QuoteLineSelection qlSelected: quoteLineIds){
        if(qlSelected.checkBox){
          //Add the parent
          SBQQ__QuoteLine__c ql_cloned = quoteLines.get(qlSelected.id).clone(false, true, false, false);
          ql_cloned.SBQQ__Existing__c = false;
          ql_cloned.Is_Bucket_Change__c = true;
          ql_cloned.SBQQ__Source__c = qlSelected.id;
          ql_cloned.SBQQ__UpgradedSubscription__c = null;
          ql_cloned.SBQQ__DefaultSubscriptionTerm__c = quoteLines.get(qlSelected.id).SBQQ__Product__r.SBQQ__SubscriptionTerm__c; // SFDC-16543         

          mapOrigIdToCloned_Parent.put(qlSelected.id, ql_cloned);
          originalQuoteLinesToBeUpdated.add(new SBQQ__QuoteLine__c(Id = qlSelected.id,
                                                                   SBQQ__Quantity__c = 0,
                                                                   Is_Bucket_Change__c = true));

          //Get bundle items
          if(quoteLineBundleMap!=null){
            System.debug('***BundleMAp: ' + quoteLineBundleMap.size());
            for(SBQQ__QuoteLine__c itemQuoteLine: quoteLineBundleMap.get(qlSelected.id)){
              SBQQ__QuoteLine__c ql_itemcloned = itemQuoteLine.clone(false, true, false, false);
              ql_itemcloned.SBQQ__Existing__c = false;
              ql_itemcloned.Is_Bucket_Change__c = true;
              ql_itemcloned.SBQQ__Source__c = itemQuoteLine.Id;
              ql_itemcloned.SBQQ__UpgradedSubscription__c = null;
              ql_itemcloned.SBQQ__DefaultSubscriptionTerm__c = itemQuoteLine.SBQQ__Product__r.SBQQ__SubscriptionTerm__c; // SFDC-16543         

              mapOrigIdToCloned_BundleItems.put(itemQuoteLine.Id, ql_itemcloned);
              originalQuoteLinesToBeUpdated.add(new SBQQ__QuoteLine__c(Id = itemQuoteLine.id,
                                                                       SBQQ__Quantity__c = 0,
                                                                       Is_Bucket_Change__c = true));
            }
          }
        }
      } //END FOR

      // Insert this first as we will be needing the bundle id
      if(mapOrigIdToCloned_Parent!=null && !mapOrigIdToCloned_Parent.isEmpty()){
        insert mapOrigIdToCloned_Parent.values();

        //Loop through bundle items map and add replace required by id with the newly created parent quote line
        for(SBQQ__QuoteLine__c clonedItem: mapOrigIdToCloned_BundleItems.values()){
          if(clonedItem.SBQQ__RequiredBy__c != null && mapOrigIdToCloned_Parent.containsKey(clonedItem.SBQQ__RequiredBy__c)){
            clonedItem.SBQQ__RequiredBy__c = mapOrigIdToCloned_Parent.get(clonedItem.SBQQ__RequiredBy__c).Id;
          }
        }
      }
      
      //Upsert Quote lines. This will insert QL for items and update original QLs
      List<SBQQ__QuoteLine__c> mergedList = new List<SBQQ__QuoteLine__c>();
      mergedList.addAll(originalQuoteLinesToBeUpdated);
      mergedList.addAll(mapOrigIdToCloned_BundleItems.values());
      
      if(mergedList!=null && !mergedList.isEmpty()){
        upsert mergedList;
      }

      //FOR TEST COVERAGE
      if(Test.isRunningTest() && testRunningFlag){
        throw new CustomException('Error message in Test Class.');
      }

      return this.goToQLE();

    }
    catch(Exception ex) {
      // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
      //                                             'DML operation has failed. More info: ' + ex.getMessage() + '\nStack Trace:' + ex.getStackTraceString()
      //                                           )
      //                     );
      message = System.Label.Mass_Amend_DML_Error + ex.getMessage() + '\nStack Trace:' + ex.getStackTraceString();
      Database.rollback(sp);
      return null;
    }
  }

  // Method that executes the cloning action.
  public PageReference goToQLE() {
    return new PageReference('/apex/SBQQ__sb?id=' + quoteId + '#quote/le?qId=' + quoteId);
  }  

  public class CustomException extends Exception {
      
  }

  //Wrapper class for capturing selected quote lines
  public class QuoteLineSelection{

    public Boolean checkBox{get;set;}
    public Id id {get;set;}

    public QuoteLineSelection(Boolean checkBox,
                              Id id){

      this.checkBox = checkBox;
      this.id       = id;
    }

  }

  //Method to create Assigned Serials for Subscriptions created after mass amend
  @InvocableMethod (label='Create Assigned Serial' description='Creates Assigned Serial for Subscriptions created via Bucket Change')
  public static void createAssignedSerial(List<Id> orderIdList){

    LogModel log = LogModel.startLog('BucketChangeAssignedSerial',
                                     'Adding assigned serial for bucket change');
                            
    try{
      
      //Get the list of Order Products for the orders
      List<OrderItem> orderItemList =  [Select Id, SBCF_Serial_Number__c 
                                        From OrderItem 
                                        Where OrderId in :orderIdList 
                                        And Is_Bucket_Change__c = true];

      //Set of Serial numbers to be used to get Serial Id
      Set<String> serialNumberSet = new Set<String>();
      
      if(orderItemList!=null && !orderItemList.isEmpty()){
        //Loop through the list to get the list of serial numbers
        for(OrderItem currentItem: orderItemList){
          //Check if the orderitem has a serial number
          if(String.isNotBlank(currentItem.SBCF_Serial_Number__c)){
            //If serial number is present then split it using comma as delimiter
            for(String serialNumber: currentItem.SBCF_Serial_Number__c.split(',')){
              //Add serial number to set if the set does not contain it already
              if(!serialNumberSet.contains(serialNumber)){
                serialNumberSet.add(serialNumber);
              }
            } // Split string for loop end
          }               
        } //Order item for loop end

        /*Get all Subscriptions for the given order where
          Subscription is Active
          Susbcription does not have assigned serial*/
        List<SBQQ__Subscription__c> bucketSubscriptions =  [SELECT Id, 
                                                                    SBCF_Serial_Number__c, 
                                                                    SBQQ__Product__r.Family, 
                                                                    SBQQ__Product__r.ProductCode,
                                                                    SBQQ__RootId__c,
                                                                    SBQQ__RequiredById__c,
                                                                    Current_Quantity__c
                                                              FROM SBQQ__Subscription__c
                                                              WHERE Id not in (Select Subscription__c 
                                                                              From Assigned_Serial__c 
                                                                              Where Serial_Number__c in :serialNumberSet 
                                                                              And Subscription__c!=null) 
                                                              AND Business_Group__c = 'MSP'
                                                              AND SBQQ__RevisedSubscription__c=null 
                                                              AND Active__c = true
                                                              AND Renewed_By_Subscription__c = null
                                                              AND SBQQ__Product__r.MSP_Product__c = TRUE 
                                                              AND Related_Order__c in :orderIdList 
                                                              AND SBQQ__OrderProduct__c in :orderItemList];
        //List of Assigned Serials to be inserted
        List<Assigned_Serial__c> asInsertList = new List<Assigned_Serial__c>();

        //Map of Sub Id and Assigned Serials to be inserted
        Map<String, Map<Id,Assigned_Serial__c>> asInsertMap = new Map<String,Map<Id,Assigned_Serial__c>>();

        //Map of Serial Id and asset's assigned serial
        Map<Id, Assigned_Serial__c> serialAssetAssignedSerialMap = new Map<Id, Assigned_Serial__c>();

        //Loop through subscription and get the list of serials listed in the Subscription field
        for(SBQQ__Subscription__c sub: bucketSubscriptions){
          //Check if the subscription has a serial number
          if(String.isNotBlank(sub.SBCF_Serial_Number__c)){
            //If serial number is present then split it using comma as delimiter
            for(String serialNumber: sub.SBCF_Serial_Number__c.split(',')){
              //Create Assigned serial for each Subscription ID and Serial Number Combination
              if(!asInsertMap.containsKey(serialNumber)){
              Map<Id, Assigned_Serial__c> subAssignedSerialMap = new Map<Id, Assigned_Serial__c>();
              subAssignedSerialMap.put(sub.id, new Assigned_Serial__c(Parent_Subscription__c = sub.SBQQ__RequiredById__c,
                                  Subscription__c = sub.Id,
                                  Capacity__c = sub.Current_Quantity__c,
                                  External_ID__c = sub.SBQQ__RootId__c + sub.Id));
              asInsertMap.put(serialNumber, subAssignedSerialMap);
              }
              else if(asInsertMap.containsKey(serialNumber)){
              Map<Id, Assigned_Serial__c> subAssignedSerialMap = asInsertMap.get(serialNumber);
              subAssignedSerialMap.put(sub.id, new Assigned_Serial__c(Parent_Subscription__c = sub.SBQQ__RequiredById__c,
                                  Subscription__c = sub.Id,
                                  Capacity__c = sub.Current_Quantity__c,
                                  External_ID__c = sub.SBQQ__RootId__c + sub.Id));
              }
            } //End of split string loop
          }
        } //End of subscription loop

        //Prepare a map of Serial Number and the Asset Assigned Serial
        for(Assigned_Serial__c currentAS: [SELECT Id,
                                                  Serial__c,
                                                  Asset__c
                                                  FROM Assigned_Serial__c 
                                                  WHERE Serial_Number__c in :serialNumberSet 
                                                  AND Subscription__c = null 
                                                  AND Parent_Subscription__c = null 
                                                  AND Asset__c!=null]){
          if(!serialAssetAssignedSerialMap.containsKey(currentAs.Serial__c)){
          serialAssetAssignedSerialMap.put(currentAS.Serial__c, currentAS);
          }
        } //End of Asset assigned serial loop            

        //Loop through the Serials obtained using serial numbers and prepare the list of Assigned Serials to be created
        for(Serial__c currentSerial: [SELECT Id, 
                                            Serial_Number__c,
                                            Expire_Date__c,
                                            Status__c 
                                      FROM Serial__c 
                                      WHERE Serial_Number__c in :serialNumberSet]){
          if(asInsertMap!=null && !asInsertMap.isEmpty()){
            for(Assigned_Serial__c currentAS: asInsertMap.get(currentSerial.Serial_Number__c).values()){
              currentAS.Serial__c      = currentSerial.Id;
              currentAs.Expire_Date__c = currentSerial.Expire_Date__c;
              currentAS.External_ID__c = currentSerial.Id + currentAS.External_ID__c;
              currentAS.Asset__c       = serialAssetAssignedSerialMap.containsKey(currentSerial.Id)? serialAssetAssignedSerialMap.get(currentSerial.Id).Asset__c: null;
              currentAs.Status__c      = (currentSerial.Status__c == 'Active')? 'Active': 'Inactive';
  
              //Add this assigned serial to the final insert list
              asInsertList.add(currentAS);
            } //End of Assigned serial loop
          }

        }//END of serial loop

        //Insert this list of Assigned Serial
        Database.SaveResult[] srList = Database.insert(asInsertList, false);

        //Loop through the result to check if there were any failures and log these failures
        if(srList!=null && !srList.isEmpty()){
          for(Integer i=0; i<srList.size(); i++){
            if(!srList[i].isSuccess()){
            log.addLog('Error creating Assigned Serial for ' + asInsertList[i].Subscription__c);
              for(Database.Error error: srList[i].getErrors()){
              log.addLog(error.message);
              }//End of save result error loop
            }
            else{
            log.addLog('Assigned Serial Created: ' + srList[i].getId());
            }
          } //End of saveresult loop
        }        
      }
      else{
        log.addLog('Order items not found for bucket change');
      }

      //End log
      log.endLog('End of Bucket Change Assigned Serial log');
    }
    catch(System.DmlException de){
      System.debug('Exception creating Assigned Serials for bucket change' +  de.getMessage());
      log.addExceptionLog(de);
    }
    catch(Exception e){
      log.addExceptionLog(e);
    }
  }
}