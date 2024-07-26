/**
* @author        Salesforce Services       
* @date          2023-03-22
* @description   A helper class to publish Integration EVent PE for BCC Account creation by Mulesoft
*                SFDC-18625: Identify SF account as ready to have authDB/BCC account and & initial portal admin set up
* @group         Helper
*/
global with sharing class BCCAccountCreateUtil {
    
     @InvocableMethod (label='Create BCC Account' description='Created BCC Account for MSP Billing Aggregators')
     global static List<BCCAccountCreateUtil.BCCAPIResult> publicAccountdetails(List<BCCAccountCreateUtil.BCCAPIRequest> request){
        List<BCCAccountCreateUtil.BCCAPIResult> result = new List<BCCAccountCreateUtil.BCCAPIResult>();
        try{
            List<Integration_Event__e> intEvents = new List<Integration_Event__e>();
            //Boolean isSuccess = false;
        
            Account objAcc = [Select Id,Name,Initial_BCC_Admin__r.Name, Initial_BCC_Admin__r.Email from Account where Id =: request.get(0).oAccount.Id];
            
            
            if(objAcc !=null){
          
                Integration_Event__e iEvent = new Integration_Event__e();
                iEvent.UUID__c = PlatformEventHelper.GUIDGenerator();
                iEvent.Object_Name__c = 'Account';
                iEvent.Record_ID__c = (String) objAcc.Id;
                BCCAccountCreateUtil.AccountRequest oreq = new BCCAccountCreateUtil.AccountRequest();
                oreq.Id = objAcc.Id;
                oreq.AccountName = objAcc.Name;
                oreq.ContactName = objAcc.Initial_BCC_Admin__r.Name;
                oreq.ContactEmail = objAcc.Initial_BCC_Admin__r.Email;
                iEvent.Object_Payload__c = JSON.serialize(oreq);
                iEvent.Event_Type__c = 'MSP-Aggregator';
                intEvents.add(iEvent);
          }       
         
         if(!intEvents.isEmpty()){
             List<Database.SaveResult> results = EventBus.publish(intEvents);
             for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                    BCCAccountCreateUtil.BCCAPIResult oresult = new BCCAccountCreateUtil.BCCAPIResult();
                    oresult.message = 'Request has been submitted and will be processed shortly.';
                    result.add(oresult);
                    //isSuccess = true;
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' + err.getStatusCode() );
                          BCCAccountCreateUtil.BCCAPIResult oresult = new BCCAccountCreateUtil.BCCAPIResult();
                          oresult.message = 'Error' + err.getStatusCode();  
                          result.add(oresult);
                          //isSuccess = false;
                          break;
                    }
                }
          }
        }
       
       }catch(Exception Ex){
           BCCAccountCreateUtil.BCCAPIResult oresult = new BCCAccountCreateUtil.BCCAPIResult();
           oresult.message = 'Error' + Ex.getMessage();
           result.add(oresult);
            AppLog__c applO = new AppLog__c();
            applO.Is_Error__c = true;
            applO.apexClassName__c = 'BCCAccountCreateUtil ';
            applO.message__c = Ex.getMessage();
            applO.Records__c = request.get(0).oAccount.Id;
            applO.startTime__c = system.now();
            applO.LogCategory__c = 'Apex';
            insert applO;
           
       
       }  
      
       
       return result;
     }
     
    global class BCCAPIRequest {
        @InvocableVariable(required=true)
        global Account oAccount;
       
        
    }
    
    global class BCCAPIResult {
   
        @InvocableVariable
        global String message;
  }
  
    global class AccountRequest{
        global String Id;
        global String AccountName;
        global string ContactName;
        global String Contactemail;
    
    }

}