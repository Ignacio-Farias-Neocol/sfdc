/**
* @author        Salesforce Services       
* @date          2021-21-01
* @description   A helper class for making an API call to MuleSoft to submit request to sync information to ZAB
*
* @group         Helper
*/
public with sharing class ZABSyncRequest {

  //Name of the custom metadata containing integration details
  private static final String WI_CMTD_NAME = 'Sync_To_ZAB_Request'; 

  /** This method calls the MS API to request syncing of information from Salesforce to ZAB.
   *  The method is invoked from Sync To ZAB Request flow.
  */
  @InvocableMethod (label='Sync To ZAB' description='Submits request for ZAB sync')
  public static List<ZABSyncRequest.SyncResponse> submitSyncRequest(List<Id> accountIdList){
      //HTTP object
      Http http = new Http();

      //HTTP Request
      HttpRequest request = new HttpRequest();

      //Get the EndPoint URL and Client ID/ Secret to build the Request object
      Web_Integration_Setting__mdt[] integrationDetails = [SELECT Base_URL__c, 
                                                                  DeveloperName,
                                                                  MasterLabel,
                                                                  Parameter1_Label__c, 
                                                                  Parameter1_Value__c, 
                                                                  Parameter2_Label__c, 
                                                                  Parameter2_Value__c,
                                                                  Parameter3_Label__c, 
                                                                  Parameter3_Value__c
                                                          FROM Web_Integration_Setting__mdt
                                                          WHERE DeveloperName = :WI_CMTD_NAME];

      //Instantiate the log class to capture logs for error conditions
      LogModel log = LogModel.startLog('ZABSyncRequest', 'submitSyncRequest');

      //Create a result object
      ZABSyncRequest.SyncResponse apiResult = new ZABSyncRequest.SyncResponse();         

      try
      {
        //Set Request parameters
        String endPoint = integrationDetails[0].Base_URL__c;

        //Endpoint
        request.setEndpoint(endPoint);

        //Method - POST
        request.setMethod('POST');

        //Header Parameters
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        if(String.isNotBlank(integrationDetails[0].Parameter1_Label__c) && String.isNotBlank(integrationDetails[0].Parameter1_Value__c)){
            request.setHeader(integrationDetails[0].Parameter1_Label__c, integrationDetails[0].Parameter1_Value__c);
        }
        if(String.isNotBlank(integrationDetails[0].Parameter2_Label__c) && String.isNotBlank(integrationDetails[0].Parameter2_Value__c)){
            request.setHeader(integrationDetails[0].Parameter2_Label__c, integrationDetails[0].Parameter2_Value__c);
        }        
        if(String.isNotBlank(integrationDetails[0].Parameter3_Label__c) && String.isNotBlank(integrationDetails[0].Parameter3_Value__c)){
            request.setHeader(integrationDetails[0].Parameter3_Label__c, integrationDetails[0].Parameter3_Value__c);
        }

        //Prepare Request Body
        List<ZABSyncRequest.SyncRequestBody> requestBodyList = new List<ZABSyncRequest.SyncRequestBody>();
        for(Id accId: accountIdList){
          requestBodyList.add(new ZABSyncRequest.SyncRequestBody(accId));
        }

        //Set Request Body
        request.setBody(JSON.serialize(requestBodyList, true));
        log.addLog(request.getBody());
        log.addLog('Request: ' + request);
        
        //Callout
        HttpResponse response = http.send(request);
        log.addLog('Response: ' + response.getBody());
        // Parse the JSON response
        if (response.getStatusCode() == 200) {
          //Deserialze JSON
          // Map<String,Object> results = (Map<String,Object>)JSON.deserializeUntyped(response.getBody());
          apiResult.message = 'Request submitted successfully.';
          apiResult.result = true;
        }
        else{
          apiResult.message = 'Error submitting the request';
          apiResult.result = false;
        }
        log.addLog('Result: ' + apiResult);
        log.endLog('End: ZABSyncRequest');
          
      }
      catch(Exception ex){
        //Set result attributes
        apiResult.result  = false;
        apiResult.message = 'Exception: ' + ex.getTypeName() + ' ' + ex.getMessage();
        log.addLog('Result: ' + apiResult);
        log.addExceptionLog(ex);
      }

      return new List<ZABSyncRequest.SyncResponse>{apiResult};
  }  

  public class SyncRequestBody {
    private Id accountId;
    public SyncRequestBody(Id accId){
      accountId = accId;
    }
  }

  public class SyncResponse {

    @InvocableVariable
    public String message;

    @InvocableVariable
    public Boolean result;    
  } 
}