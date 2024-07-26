public with sharing class SubscriptionQtyInUseCorrection implements Database.Batchable<sObject> {
  public Boolean testErrorMessage = false;
  private String query;
  private String defaultQuery = 'SELECT Id, Quantity_In_Use__c,' +
                                '(SELECT Qty_In_Use__c FROM Assigned_Serials__r WHERE External_Id__c != null AND Status__c = \'Active\')' +
                                ' FROM SBQQ__Subscription__c' +
                                ' WHERE Business_Group__c = \'MSP\'';

  //Constructor with query and batchsize
  public SubscriptionQtyInUseCorrection(String queryString){
    if(String.isNotBlank(queryString)){
        query = queryString;
    }
    else{
      query = defaultQuery;
    }
  }
  //Constructor with no parameters
  public SubscriptionQtyInUseCorrection(){
      query     = defaultQuery;
  }  

  //Start method
  public Database.QueryLocator start(Database.BatchableContext BC){        
    if(String.isNotBlank(query)){
      return Database.getQueryLocator(query);
    }
    else{
      return Database.getQueryLocator(defaultQuery);
    }
  }

  //Execute
  public void execute(Database.BatchableContext BC, List<sObject> scope){
  
    LogModel log = LogModel.startLog('SubscriptionQtyInUseCorrection',
                                     'Correcting Qty in use in Subscriptions');

    try{

      //List of Subscriptions to be inserted
      List<SBQQ__Subscription__c> subUpdateList = new List<SBQQ__Subscription__c>();

      //Loop through subscription and get the list of serials listed in the Subscription field
      for(SBQQ__Subscription__c sub: (List<SBQQ__Subscription__c>)scope){
        //Initialise qty in use
        Decimal qtyInUse = 0;

        //Loop through Assigned serials and calculate qty in use
        for(Assigned_Serial__c aserial : sub.Assigned_Serials__r){
          qtyInUse += aserial.qty_in_use__c == null? 0 : aserial.qty_in_use__c;
        }

        if(sub.Quantity_In_Use__c != qtyInUse){
          subUpdateList.add(new SBQQ__Subscription__c(Id = sub.id, 
                                                      Quantity_In_Use__c = qtyInUse));
        }
      } //END FOR
      

      if(subUpdateList!=null && !subUpdateList.isEmpty()){
        //Insert this list of Assigned Serial
        Database.SaveResult[] srList = Database.update(subUpdateList, false);
        
        //Loop through the result to check if there were any failures and log these failures
        for(Database.SaveResult sr: srList){
          if(!sr.isSuccess() || testErrorMessage){
            String errorMessage = 'Error: ' + sr.getId();
              for(Database.Error error: sr.getErrors()){
                  errorMessage += error.getMessage();
              }
            log.addLog(errorMessage); 
          }
        } //END OF SR LIST
      }

      //End log
      log.endLog('End of SubscriptionQtyInUseCorrection log');

    }
    catch(System.DmlException de){
      System.debug('Exception updating Subscriptions' +  de.getMessage());
      log.addExceptionLog(de);
    }
    catch(Exception e){
      log.addExceptionLog(e);
    }
  }

  //Finish method
  public void finish(Database.BatchableContext BC){}

}