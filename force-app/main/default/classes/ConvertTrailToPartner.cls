/**
* @author        Keethi Atluri    
* @date          2020-05-15
* @description   A helper class for making an API call to MuleSoft to convert the trail partner account to full partner account
*
* @group         Helper
*/
global with sharing class ConvertTrailToPartner {	
    @InvocableMethod (label='Convert Trial To Full Partner')
    public static void callAPIToConvert(List<String> AccId) {
        if(System.IsBatch() == false && System.isFuture() == false){
            callout(AccId[0]);
        }
    }
    
    @future(callout=true)
    public static void callout(String AccId){
        
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('Convert_Trial_To_Partner', 'converting trial to full partner account');
        
        try {
            Account acc = [SELECT Id,User_na__c,BillingCountryCode FROM Account WHERE Id =:AccId LIMIT 1];
            List<String> params = new List<String>{acc.User_na__c};
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
                                                                 WHERE DeveloperName = 'Convert_Trial_To_Partner'];
            
            
            //Set Request parameters
            String endPoint = String.format(integrationDetails[0].Base_URL__c,params) + '?countryCode='+ acc.BillingCountryCode;
            //Endpoint
            request.setEndpoint(endPoint);
            
            //Method - PUT
            request.setMethod('PUT');
            
            //Header Parameters
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', 'application/json');
            if(String.isNotBlank(integrationDetails[0].Parameter1_Label__c) && String.isNotBlank(integrationDetails[0].Parameter1_Value__c)) {
                request.setHeader(integrationDetails[0].Parameter1_Label__c, integrationDetails[0].Parameter1_Value__c);
            }
            if(String.isNotBlank(integrationDetails[0].Parameter2_Label__c) && String.isNotBlank(integrationDetails[0].Parameter2_Value__c)) {
                request.setHeader(integrationDetails[0].Parameter2_Label__c, integrationDetails[0].Parameter2_Value__c);
            }
            
            //Generating json body
            JSONGenerator gen = JSON.createGenerator(false);
            gen.writeStartObject();
            gen.writeStringField('sfAccountId', acc.Id);
            gen.writeEndObject();
            String jsonBody = gen.getAsString();
			request.setBody(jsonBody);
            
            HttpResponse response = http.send(request);
            //system.debug('@@ resp: '+ jSON.serialize(response));
            if (response.getStatusCode() >= 200 && response.getStatusCode() <=210) {
                log.addLog('Update successful'+ AccId);
                system.debug('Update successful'+ AccId + 'StatusCode: ' + response.getStatusCode());
                acc.Is_Converted_to_Full_Partner__c=True;
                Update acc;
            } 
            else {
                log.addLog('Update failed: '+ acc.User_na__c+ ':' +response.getBody());
                system.debug('Update failed: '+ acc.User_na__c+ ':' +response.getBody());
            }
            
            log.endLog('End: ConvertTrailToPartner');
            
        }catch(Exception ex) {
            log.addExceptionLog(ex);
            System.debug('@@error:'+ex.getMessage());
        }
    }
}