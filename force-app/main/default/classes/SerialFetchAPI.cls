/**
* @author        Salesforce Services       
* @date          2020-05-10
* @description   A helper class for making an API call to MuleSoft to fetch serials for a given SMB username
*
* @group         Helper

* SFDC-16055 : Added SNT and FIR to Product Sales Group in the code
*/
global with sharing class SerialFetchAPI {

  private static final String FETCH_SMB_SERIALS    = 'Fetch_SMB_Serials';
  private static final String MIGRATION = 'Migration';
  private static final String UPLEVEL = 'Uplevel';
  private static final String STATUS_ACTIVE = 'Active';

  /** This method calls the MS API to get serials for a given SMB Username. The method in invoked from Serial Move flow
   * Since it is invocable method we have to use list parameters, however the API runs for one username at a time.
  */
  @InvocableMethod (label='SMB username serials' description='Fetches serials for an SMB Username')
  public static List<SerialFetchAPI.SMBAPIResult> fetchSerials(List<SerialFetchRequest> requestList){
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
                                                          WHERE DeveloperName = :FETCH_SMB_SERIALS];

      //Instantiate the log class to capture logs for error conditions
      LogModel log = LogModel.startLog('SerialFetchAPI', 'fetchSerials');

      //Create a result object
      SerialFetchAPI.SMBAPIResult apiResult = new SerialFetchAPI.SMBAPIResult();        

      try
      {
        //Set Request parameters
        String endPoint = String.format(integrationDetails[0].Base_URL__c, new List<String>{requestList[0].smbusername}) + 
                          '?countryCode=' + SerialMoveHelper.getMaestroInstance(requestList[0].countryCode);
        //Endpoint
        request.setEndpoint(endPoint);

        //Method - GET
        request.setMethod('GET');

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

        log.addLog('Request: ' + request);
        
        //This request does not need any body. Hence not setting request body attribute.
        //Callout
        HttpResponse response = http.send(request);
        
        // Parse the JSON response
        if (response.getStatusCode() == 200) {
          log.addLog('Serials for ' + requestList[0].smbusername + ' were fetched. Response: ' + response.getBody());

          //Deserialze JSON
          List<Object> serials = (List<Object>)JSON.deserializeUntyped(response.getBody());

          /*If the serials list is not empty then get all serial numbers. 
            This list of serial numbers will be used to fetch assigned serials.*/
          if(serials != null && !serials.isEmpty()){
            
            //Set containing serial numbers
            Set<String> serialNumberSet = new Set<String>();
            //Populate the set
            for(Object obj: serials){
              Map<String, Object> serialObjMap = (Map<String, Object>)obj;
              serialNumberSet.add((String)serialObjMap.get('serial'));
            }

            /*Get Assigned Serials for the set of serials obtained above. 
              Assumption: One Assigned Serial for One Serial*/
            // List<Assigned_Serial__c> smbSerials = [SELECT Serial_Number__c,
            //                                               Serial__r.Base_Product_SKU__c,
            //                                               Serial__r.Status__c,
            //                                               Serial__r.Capacity__c,
            //                                               Id,
            //                                               SMB_Name__c,
            //                                               Subscription__r.Name ,
            //                                               Subscription__r.Product_Code__c,
            //                                               Subscription__r.SBQQ__ProductName__c
            //                                        FROM Assigned_Serial__c 
            //                                        WHERE Serial_Number__c in :serialNumberSet 
            //                                        AND Serial__r.Status__c = 'Active'
            //                                        AND Subscription__r.SBQQ__Product__r.SBQQ__Component__c = false 
            //                                       //  AND Subscription__r.SBQQ__Product__r.Product_Sales_Grouping__c	= 'Cloud Email Services' 
            //                                        AND Subscription__c !=null
            //                                        AND Subscription__r.SBQQ__RevisedSubscription__c = null 
            //                                        AND Subscription__r.Renewed_By_Subscription__c = null];

            List<Assigned_Serial__c> smbSerials = SerialFetchAPI.getAssignedSerial(serialNumberSet, requestList[0].moveType);

            if(smbSerials!=null && smbSerials.size()>0){
              apiResult.smbSerials = smbSerials;
              apiResult.message = 'Serial Numbers fetched Successfully';
              apiResult.result = true;
            }
            else
            {
              //Set result to false
              apiResult.result = false;

              //Set Message
              apiResult.message = 'Serials not available for the SMB username provided.';
            }

            system.debug('Serials: ' + apiResult.smbSerials);            
          }
          //No serials available for the given SMB Username
          else
          {
            //Set result to false
            apiResult.result = false;

            //Set Message
            apiResult.message = 'Serials not available for the SMB username provided.';
          }
            
        } 
        else if(response.getStatusCode() != 200) {

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

        System.debug('Error Message: ' + apiResult.message);
        log.endLog('End: EchoPartnerHelperLog');
          
      }
      catch(Exception ex){
        //Set result attributes
        apiResult.result  = false;
        apiResult.message = 'Callout Exception: ' + ex.getTypeName() + ' ' + ex.getMessage();
        log.addExceptionLog(ex);
      }

      return new List<SerialFetchAPI.SMBAPIResult>{apiResult};
  }

  //method to get Assigned Serials
  private static List<Assigned_Serial__c> getAssignedSerial(Set<String> serialNumberSet, String moveType){
    //Prepare the query 
    String query = 'SELECT Serial_Number__c,' + 
                   'Serial__r.Base_Product_SKU__c,' +
                   'Serial__r.Status__c,' +
                   'Serial__r.Capacity__c,' +
                   'Id,' +
                   'SMB_Name__c,'+
                   'Subscription__r.Name ,' +
                   'Subscription__r.Product_Code__c,'+
                   'Subscription__r.SBQQ__ProductName__c,'+
                   'Subscription__r.ECHO_Unique_Identifier_Value__c' +
                   ' FROM Assigned_Serial__c ' +
                   ' WHERE Serial_Number__c in :serialNumberSet'+
                   ' AND Status__c = :STATUS_ACTIVE' +
                   ' AND Serial__r.Status__c = :STATUS_ACTIVE'+
                   ' AND Subscription__r.SBQQ__Product__r.SBQQ__Component__c = false' + 
                   ' AND Subscription__c !=null' +
                   ' AND Subscription__r.SBQQ__RevisedSubscription__c = null' +
                   ' AND Subscription__r.Renewed_By_Subscription__c = null';

    //List of Product Sales Groupings
    //List<String> productSalesGroupings = new List<String>{'Cloud Email Services'};   
    List<String> productSalesGroupings = new List<String>{'ESS','SNT','FIR'};       // SFDC-16055                

    if(moveType == UPLEVEL){
      query += ' AND Subscription__r.SBQQ__Product__r.Product_Sales_Grouping__c	in :productSalesGroupings';
    }

    System.debug('Query: ' + query);

    return Database.query(query);
//   
  }

  global class SerialFetchRequest {

    @InvocableVariable(required=true)
    global String smbusername;

    @InvocableVariable(required=true)
    global String moveType;  
    
    @InvocableVariable(required=true)
    global String countryCode;        
  } 

  global class SMBAPIResult {

    @InvocableVariable
    global List<Assigned_Serial__c> smbSerials;

    @InvocableVariable
    global String message;

    @InvocableVariable
    global Boolean result;    
  } 
}