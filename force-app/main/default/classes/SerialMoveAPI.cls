/**
* @author        Salesforce Services       
* @date          2020-05-10
* @description   A helper class for making an API call to MuleSoft to move serials
*
* @group         Helper
*/
global with sharing class SerialMoveAPI {
  
  private static final String MIGRATION = 'Migration';
  private static final String UPLEVEL = 'Uplevel';
  private static final String MOVE_SERIALS = 'Move_Serials';
  private static final String UPGRADE_SERIALS = 'Upgrade_Serials';
  private static final String PENDING_STATUS = 'Pending Move';

  private static LogModel log;

  /** This method calls the MS API to move serials. The method is invoked from Serial Move flow
   * Since it is invocable method we have to use list parameters, however the API runs for one request at a time.
   * We first try to update Salesforce. If all updates to Salesforce are successful, then call the API to move serials in ECHO
  */
  @InvocableMethod (label='Move Serials' description='Moves serials')
  public static List<SerialMoveAPI.MoveAPIResult> moveSerials(List<SerialMoveAPI.FlowMoveAPIRequest> moveRequestList){
    //HTTP object
    Http http = new Http();

    //HTTP Request
    HttpRequest request = new HttpRequest();

    //API Endpoint setting developer name
    String settingName = moveRequestList[0].moveType == MIGRATION? MOVE_SERIALS : UPGRADE_SERIALS;

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
                                                        WHERE DeveloperName = :settingName];

    //Instantiate the log class to capture logs for error conditions
    log = LogModel.startLog('SerialMoveAPI', 'moveSerials');  
    log.addLog('moveRequestList: ' + moveRequestList);

    //Create a result object
    SerialMoveAPI.MoveAPIResult apiResult = new SerialMoveAPI.MoveAPIResult(); 

    try
    {
      String userName = moveRequestList[0].moveType == MIGRATION? moveRequestList[0].smbUsername : moveRequestList[0].targetPartnerUsername;
      //Set Request parameters
      String endPoint = String.format(integrationDetails[0].Base_URL__c, new List<String>{userName}) + 
                        '?countryCode=' + SerialMoveHelper.getMaestroInstance(moveRequestList[0].countryCode);
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

      //Set Request Body
      SerialMoveAPI.MoveAPIRequestBody requestBody = new SerialMoveAPI.MoveAPIRequestBody();
      requestBody.partner    = moveRequestList[0].moveType == MIGRATION ? moveRequestList[0].sourceAccountUsername : null;
      requestBody.newPartner = moveRequestList[0].moveType == MIGRATION ? moveRequestList[0].targetPartnerUsername : null;
      requestBody.serials    = new List<SerialMoveAPI.SerialPayload>();

      //parse the JSON string provided by the flow
      List<Object> subscriptions = (List<Object>)JSON.deserializeUntyped(moveRequestList[0].serialSubMap);

      //If there are subscription loop through each of them to get serial information for the payload
      if(subscriptions!=null && !subscriptions.isEmpty()){
        for(Object obj: subscriptions){
          //Convert each Subscription entry in JSON to a map. This is done to get attribute values.
          Map<String, Object> subObjMap = (Map<String, Object>)obj;

          //If the Subscription does have a mapped Serial then prepare the payload
          if(subObjMap.get('serials')!=null){
            //Get serials as a list
            List<Object> serialsObjList = (List<Object>)subObjMap.get('serials');

            //Loop through each serial to get serial info
            for(Object serialObj: serialsObjList){
              //Convert each serial into a map to get attributes
              Map<String, Object> serialObjMap = (Map<String, Object>)serialObj;

              Map<String, Object> serialInfo = (Map<String, Object>)serialObjMap.get('serial');

              //Prepare the payload using information from Serial and Subscription
              requestBody.serials.add(new SerialMoveAPI.SerialPayload((String)serialInfo.get('serialNumber'),
                                                                      (String)subObjMap.get('subscriptionOrderId'),
                                                                      (String)subObjMap.get('subscriptionOrderLineId')));

            }
          }
        }
      }

      // log.addLog('Request Payload: ' + JSON.serialize(requestBody));
      System.debug('***Request***:' + JSON.serialize(requestBody));
      log.addLog('Request Body: ' + JSON.serialize(requestBody));
      //Set request body
      //The boolean value 'true' suppresses null values during serialization
      //https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_System_Json.htm
      request.setBody(JSON.serialize(requestBody, true));
      log.addLog('Request: ' + request);

      //Set the timeout value. Default is 10 seconds. Setting it to 100 sec. Max limit is 120 seconds.
      //Check this link for more information https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_callouts_timeouts.htm
      request.setTimeout(100000);

      //Callout
      HttpResponse response = http.send(request);
      // HttpResponse response;
          
      //Understanding the response
      /* 1. If the response is as follows it means all serials moved and SMB moved
         {
          "success": true
         }

        2. If the response is as follows it means all serials moved but SMB move failed
         {
          "success": false,
          "errors": [
            {
              "newPartner": "krupp",
              "message": "Unabled to move SMB to new partner"
            }
          ]
         }         

        3. If the response is as follows it means some serials moved and SMB move failed
         {
          "success": false,
          "errors": [
            {
              "serial": "12999934",
              "message": "Move failed",
              "statusCode": 500
            },
            {
              "newPartner": "krupp",
              "message": "Unabled to move SMB to new partner"
            }
          ]
         } 
      */
      log.addLog('Response for Serial Move: ' + response!=null ? response.getBody(): null);
      // Parse JSON response
      if (response!=null && response.getStatusCode() == 200) {
        //Deserialze JSON
        Map<String,Object> serialMoveResponseMap = (Map<String,Object>)JSON.deserializeUntyped(response.getBody());

        //Get the Serial Move status
        if(serialMoveResponseMap.get('success')!=null){
          //Serial Move Succeeded
          if((Boolean)serialMoveResponseMap.get('success')){
            apiResult.result = true;
            apiResult.message = 'Serials and SMB were moved successfully';
          }
          //Serial Move failed
          else{
            apiResult.result = false;
            //Get errors
            List<Object> errorList = ((List<Object>) serialMoveResponseMap.get('errors'));

            //If there is only one item in errorlist it means that SMB move failed. 
            //If there are more than one then it means that some serials failed as well
            if(errorList!=null && !errorList.isEmpty()){
              if(errorList.size() == 1){
                //Create a map for error object and get the message
                Map<String, Object> errorMap = (Map<String, Object>)errorList[0];
                apiResult.message = (String)errorMap.get('message');
              }
              else{
                apiResult.message = 'Serials failed to move to target subscriptions';
                List<SerialMoveAPI.FailedSerials> failedSerials = new List<SerialMoveAPI.FailedSerials>();
                
                //Failed Serials Serial Number. Used to query serials for update
                Set<String> serialNumberSet = new Set<String>();

                //Loop through errors and get failed serials
                for(Object errorObj: errorList){
                  //Create a map of errorObj
                  Map<String, Object> errorMap = (Map<String, Object>)errorObj;
                  if(errorMap.get('serial')!=null){

                    //Populate set for query
                    if(!serialNumberSet.contains((String)errorMap.get('serial'))){
                      serialNumberSet.add((String)errorMap.get('serial'));
                    }
                    
                    //Create object for return
                    SerialMoveAPI.FailedSerials failedSerialEntry = new SerialMoveAPI.FailedSerials((String)errorMap.get('serial'),
                                                                                                     (String)errorMap.get('message'));
                    failedSerials.add(failedSerialEntry);
                  }
                }

                //Serialize for return parameter
                apiResult.failedSerials = JSON.serialize(failedSerials);

                //Make Serial Updates
                apiResult.message += updateFailedSerials(serialNumberSet);
              }
            }
            else{
              apiResult.message = 'Serial and SMB move failed. MS/ECHO did not provide specific error message';
            }
          }
        }
        else{
          apiResult.result = false;
          apiResult.message = 'Did not get any response from MS/Echo';
        }
      }  
      else if(response!=null && response.getStatusCode() != 200) {

        apiResult.result = false;

        //Prepare error message for display and log
        //Create a JSON parser to access the message
        JSONParser parser = JSON.createParser(response.getBody());
        apiResult.message = '';
        while (parser.nextToken() != null) {
          if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
              (parser.getText() == 'message' || parser.getText() == 'description')) {
              // Get the value.
              parser.nextToken();
              // Compile error messages
              apiResult.message += parser.getText() + '.';
              log.addErrorLog(apiResult.message);
          }
        }  

      }      

      log.endLog('End: SerialMoveAPI Log');
        
    }
    catch(DMLException de){
      //Set result attributes
      apiResult.result  = false;
      apiResult.message += ' Salesforce DML Exception: ' + de.getMessage();
    }    
    catch(Exception ex){
      //Set result attributes
      apiResult.result  = false;
      apiResult.message = 'Callout Exception: ' + ex.getMessage();
      log.addExceptionLog(ex);
    }

    return new List<SerialMoveAPI.MoveAPIResult>{apiResult};
  }

  private static String updateFailedSerials(Set<String> serialNumberSet){
    //Update Serial Status
    //Get Serials using Serial number
    List<Serial__c> serialUpdateList = new List<Serial__c>();
    for(Serial__c failedSerialRec :[SELECT Id,
                                                Status__c 
                                        FROM Serial__c 
                                        WHERE Serial_Number__c in :serialNumberSet])
    {
      failedSerialRec.Status__C = PENDING_STATUS;
      serialUpdateList.add(failedSerialRec);
    }

    //Update serials
    List<Database.SaveResult> srList = withoutSharingDML.save(serialUpdateList, false, 'SerialMoveAPI');

    //Error message
    String errorMessage = '';

    //Iterate through each returned result
    for (Database.SaveResult sr : srList) {
      if (!sr.isSuccess()) 
      {
        // Operation failed, so get all errors                
        for(Database.Error err : sr.getErrors()) {                 
            errorMessage += err.getStatusCode() + ': ' + err.getMessage();
            log.addLog(errorMessage);
        }
      }
    }

    return errorMessage;
  }

  global class FlowMoveAPIRequest {

    @InvocableVariable(required=true)
    global String smbUsername;

    @InvocableVariable(required=true)
    global String sourceAccountUsername;

    @InvocableVariable(required=true)
    global String targetPartnerUsername;

    @InvocableVariable(required=true)
    global String serialSubMap; 
    
    @InvocableVariable(required=true)
    global String moveType;  

    @InvocableVariable(required=true)
    global String countryCode;
  } 

  public class MoveAPIRequestBody {

    public String partner;

    public String newPartner;

    public List<SerialPayload> serials;    
  }

  public class SerialPayload {
    private String serial;
    private String orderId;
    private String orderLineId; 
    public SerialPayload(String serial,
                      String orderId,
                      String orderLineId)
    {
      this.serial      = serial;
      this.orderId     = orderId;
      this.orderLineId = orderLineId;
    }
  } 

  global class MoveAPIResult {

    @InvocableVariable
    global String failedSerials;

    @InvocableVariable
    global String message;

    @InvocableVariable
    global Boolean result;    
  } 

  public class FailedSerials {
    private String serialNumber;
    private String message;
    public FailedSerials(String serialNumber,
                      String message)
    {
      this.serialNumber = serialNumber;
      this.message      = message;
    }
  }
}