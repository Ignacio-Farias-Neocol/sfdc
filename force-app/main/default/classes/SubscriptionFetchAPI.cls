/**
* @author        Salesforce Services       
* @date          2020-05-10
* @description   A helper class for fetching subscriptions for a given Account Id
*
* @group         Helper
*/
global with sharing class SubscriptionFetchAPI {
  /** This method runs a query on SBQQ__Subscription__c object and fetches Subs for a given account
  */
  @InvocableMethod (label='Get Subscriptions for Account' description='Fetches subscriptions for an account')
  public static List<SubscriptionFetchAPI.SubFetchResult> fetchSubscriptions(List<SubFetchRequest> requestList){

    //Instantiate the log class to capture logs for error conditions
    LogModel log = LogModel.startLog('SubscriptionFetchAPI', 'fetchSubscriptions');

    //Create a result object
    SubscriptionFetchAPI.SubFetchResult fetchResult = new SubscriptionFetchAPI.SubFetchResult();        
    try
    {
      //get assigned serial and account from the request
      List<String> productCodeList = requestList[0].productCodeList;
      Id accountId                 = requestList[0].accountId;
      String moveType              = requestList[0].moveType;

      //List of Product Sales Groupings
      //List<String> productSalesGroupings = new List<String>{'Cloud Email Services'};
      List<String> productSalesGroupings = new List<String>{'ESS','SNT','FIR'};       // SFDC-16854     

         String subscriptionQuery = 'SELECT Id, Name, SBQQ__ProductName__c, Product_Code__c, Universal_OrderItem_Id__c, Universal_Order_Id__c,SBQQ__RootId__c,SBQQ__Contract__c,ECHO_Unique_Identifier_Value__c' + 
       ' FROM SBQQ__Subscription__c' + 
       ' WHERE SBQQ__Account__c = :accountId' +
       ' AND SBQQ__Product__r.SBQQ__Component__c = false' + 
       ' AND SBQQ__RevisedSubscription__c = null' + 
       ' AND Renewed_By_Subscription__c = null' +
       ' AND SBQQ__TerminatedDate__c = null' ; 

      
      if(String.isNotBlank(moveType)){
        if(moveType.equals('Migration')){
          //This is needed for migration to ensure product codes match
          subscriptionQuery += ' AND Product_Code__c in :productCodeList';
        }
        else if(moveType.equals('Uplevel')){
          //This is needed for migration to ensure product codes match
          subscriptionQuery += ' AND SBQQ__Product__r.Product_Sales_Grouping__c in :productSalesGroupings';
        }
      }

      //Get Subscriptions
      List<SBQQ__Subscription__c> subs = Database.query(subscriptionQuery);     

      if(subs!=null && subs.size()>0){
        fetchResult.subscriptionList = subs;       
        fetchResult.message = 'Subscriptions fetched Successfully';
        fetchResult.result = true;
        log.addLog('Subscriptions fetched successfully');
      }
      else
      {
        //Set result to false
        fetchResult.result = false;

        //Set Message
        fetchResult.message = 'Subscriptions not available for the Account provided.';
        log.addLog('Subscriptions not available for the account');
      }

      log.endLog('End: SubscriptionFetchAPI');
        
    }
    catch(Exception ex){
      //Set result attributes
      fetchResult.subscriptionList = null;
      fetchResult.result  = false;
      fetchResult.message = 'Exception: ' + ex.getMessage();
      log.addExceptionLog(ex);
    }

    return new List<SubscriptionFetchAPI.SubFetchResult>{fetchResult};
  }
  
  global class SubFetchResult {

    @InvocableVariable
    global List<SBQQ__Subscription__c> subscriptionList;

    @InvocableVariable
    global String message;

    @InvocableVariable
    global Boolean result;    
  } 

  global class SubFetchRequest {

    @InvocableVariable(required=true)
    global Id accountId;

    @InvocableVariable(required=true)
    global List<String> productCodeList;  

    @InvocableVariable(required=true)
    global String moveType;     
  } 
}