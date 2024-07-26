/**
* @author        Salesforce Services       
* @date          2020-01-28
* @description   A helper class for making an API call to MuleSoft to create partner or update partner info. 
*                SFDC-12900: Increasing callout timeout and adding log to add request parameters.
* @group         Helper
*/
global with sharing class EchoPartnerHelper {

    private static final String CREATE_ECHO_USERNAME    = 'Create_ECHO_Username';
   
    @InvocableMethod (label='Upsert ECHO Partner' description='Inserts a partner or updates partner information')
    public static List<EchoPartnerHelper.EchoAPIResult> upsertEchoPartner(List<EchoPartnerHelper.EchoAPIRequest> apiRequestBodyList){
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
                                                            WHERE DeveloperName = :CREATE_ECHO_USERNAME];

        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('EchoPartnerHelper', 'upsertEchoPartner');

        //Create a result object
        EchoPartnerHelper.EchoAPIResult apiResult = new EchoPartnerHelper.EchoAPIResult();        

        try
        {
            //Set Request parameters
            //Endpoint
            request.setEndpoint(integrationDetails[0].Base_URL__c);
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

            //Get the request body from the flow
            EchoPartnerHelper.EchoAPIRequest apiRequestBody = apiRequestBodyList[0];

            //Check if any attribute is an empty string. If yes, then assign null to it.
            //We do this so that the JSON method can suppress null parameters, thereby preventing error
            //Assuming that required parameters are being checked in the entity calling this method. 
            if(String.isBlank(apiRequestBody.streetAddress2)){
                apiRequestBody.streetAddress2 = null;
            }
            if(String.isBlank(apiRequestBody.streetAddress3)){
                apiRequestBody.streetAddress3 = null;
            }
            if(String.isBlank(apiRequestBody.streetAddress4)){
                apiRequestBody.streetAddress4 = null;
            }
            if(String.isBlank(apiRequestBody.state)){
                apiRequestBody.state = null;
            }            
            if(String.isBlank(apiRequestBody.extension)){
                apiRequestBody.extension = null;
            }
            if(String.isBlank(apiRequestBody.fax)){
                apiRequestBody.fax = null;
            }
            if(String.isBlank(apiRequestBody.partnerCurrency)){
                apiRequestBody.partnerCurrency = null;
            }
            if(String.isBlank(apiRequestBody.planId)){
                apiRequestBody.planId = null;
            }
            if(String.isBlank(apiRequestBody.pricingPlanIds)){
                apiRequestBody.pricingPlanIds = null;
            }
            if(String.isBlank(apiRequestBody.partner)){
                apiRequestBody.partner = null;
            }
            //SFDC-13427: Adding billing aggregator parameter
            if(String.isBlank(apiRequestBody.billingAggregatorId)){
                apiRequestBody.billingAggregatorId = null;
            }
            
              if(String.isBlank(apiRequestBody.bccAuthDBAccountId)){
                apiRequestBody.bccAuthDBAccountId= null;
            }
            
            /**
             * Code added as a part of SFDC-18360: START
             */
                if(String.isBlank(apiRequestBody.accName)){
                    apiRequestBody.accName = null;
                }
                if(String.isBlank(apiRequestBody.conName)){
                    apiRequestBody.conName = null;
                }
                if(String.isBlank(apiRequestBody.conEmail)){
                    apiRequestBody.conEmail = null;
                }
                if(String.isBlank(apiRequestBody.bccAuthDBAdminId)){
                    apiRequestBody.bccAuthDBAdminId = null;
                }
             /**
             * Code added as a part of SFDC-18360: END
             */
            
            //Get the JSON representation of request bod and replace partnerCurrency with Currency
            String apiRequestBodyJSON = JSON.serialize(apiRequestBody,true).replace('partnerCurrency', 'currency');

            // Set the body as a JSON object
            request.setBody(apiRequestBodyJSON);

            //SFDC-12900 Log the request
            log.addLog('Request: ' + apiRequestBodyJSON);

            //SFDC-12900 Set the timeout to 100 seconds
            request.setTimeout(100000);

            System.debug('Request Body: ' + request.getBody());

            //Callout
            HttpResponse response = http.send(request);
            
            // Parse the JSON response
            if (response.getStatusCode() != 201) {
                System.debug('Error: ' +
                            response.getStatusCode() + 
                            ' ' + 
                            response.getStatus());

                apiResult.result = false;
            } else if(response.getStatusCode() == 201) {
                apiResult.result = true;
            }

            // Get the textual representation of the value.
            if(apiResult.result){
                apiResult.message = Label.ECHO_Username_Creation_Message;
                log.addLog('Success: ' +  apiRequestBody.username + ' ' + Label.ECHO_Username_Creation_Message);
            }
            else{
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
            apiResult.message = 'Callout Exception: ' + ex.getMessage();
            log.addExceptionLog(ex);
        }
        return new List<EchoPartnerHelper.EchoAPIResult>{apiResult};
   }

global class EchoAPIRequest {
    @InvocableVariable(required=true)
    global String username;

    //Commented out as per the design changes related to SFDC-18360
    /*@InvocableVariable(required=true)
    global String password;*/
    
    @InvocableVariable(required=true)
    global String name;

    @InvocableVariable(required=true)
    global String company;

    @InvocableVariable(required=true)
    global String streetAddress;

    @InvocableVariable
    global String streetAddress2;

    @InvocableVariable
    global String streetAddress3;

    @InvocableVariable
    global String streetAddress4;

    @InvocableVariable(required=true)
    global String city;

    @InvocableVariable
    global String state;

    @InvocableVariable(required=true)
    global String zip;

    @InvocableVariable(required=true)
    global String country;

    @InvocableVariable(required=true)
    global String countryCode;

    @InvocableVariable(required=true)
    global String email;

    @InvocableVariable(required=true)
    global String phone;

    @InvocableVariable(required=true)
    global String sfAccountId;
    
    @InvocableVariable
    global String extension;

    @InvocableVariable
    global String fax;

    //Naming this as partner currency as Currency is reserved
    @InvocableVariable
    global String partnerCurrency;

    @InvocableVariable
    global String planId;

    @InvocableVariable
    global String pricingPlanIds;

    @InvocableVariable
    global String partner; 

    //SFDC-13427: Adding Billing Aggregator field.
    @InvocableVariable
    global String billingAggregatorId;
    
     @InvocableVariable
    global String bccAuthDBAccountId;
    
    /***
     * Added new fields as a part of SFDC-18360: START
     */
    @InvocableVariable
    global String accName;

    @InvocableVariable
    global String conName;

    @InvocableVariable
    global String conEmail;

    @InvocableVariable
    global String bccAuthDBAdminId;
    /***
     * Added new fields as a part of SFDC-18360: END
     */
      
  }

global class EchoAPIResult {

    @InvocableVariable
    global Boolean result;

    @InvocableVariable
    global String message;
  }
}