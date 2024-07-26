public class AdminDashboardQueueable implements Queueable, Database.AllowsCallouts{
    public String jsonBody;
    public String method;
    public Id opportunityId;
    
    public AdminDashboardQueueable(String jsonBody, String method, String opportunityId){
        this.jsonBody = jsonBody;
        this.method = method;
        this.opportunityId = opportunityId;
    }
    public void execute(system.QueueableContext context){
        Http http = new Http();
        HttpResponse res = new HttpResponse();
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:AdminDashboardCredential');
            req.setMethod(method);
            req.setHeader('Content-Type', 'application/json;charset=UTF-8');
            req.setHeader('x-api-key','{!$Credential.Password}');
            //Set json request body.
            req.setBody(jsonBody);  
            system.debug('request '+req);
            // Send the request to admin dashboard, and return a response
            res =  http.send(req);
            //Capture request in integration snapshot object.
            CaptureRequest(req, OpportunityId, method);
            system.debug('response '+res.getBody());
            //Capture response in integration snapshot object.
            CaptureResponse(res, opportunityId, method);
        }
        catch(System.CalloutException e) {
            System.debug(res.toString());
        }
        catch(Exception e) {
            System.debug('Callout error: '+ e); 
            System.debug(res.toString());
        }
    }
    //Capture the response from Admin dashboard.
    public static void CaptureResponse(HttpResponse response, String opportunityId, String method){
        try{
            Integration_snapshot__c intsnp = new Integration_snapshot__c();
            intsnp.Record_ID__c = opportunityId;
            intsnp.Message_Payload__c = response.getBody();
            intsnp.System_Name__c = 'Admin Dashboard';
            intsnp.Sync_Status__c = response.getStatus();
            intsnp.External_ID__c = 'Res-'+OpportunityId+method;
            intsnp.Object_Name__c = 'Opportunity'; 
            if(!Test.isRunningTest()){
                insert intsnp;  
            }    
        }catch(DmlException dml){
            system.debug('DML Exception in capture response: '+dml);
        }catch(Exception ex){
            system.debug('Exception in capture response: '+ex);
        }
          
    }
    //Capture request body before sending request to admin dashboard.
    public static void CaptureRequest(HttpRequest req, String OpportunityId, String method){
        try{
            Integration_snapshot__c intsnp = new Integration_snapshot__c();
            intsnp.Record_ID__c = OpportunityId;
            intsnp.Message_Payload__c = req.getBody();
            intsnp.System_Name__c = 'Salesforce';
            intsnp.Sync_Status__c = 'Request Sent';
            intsnp.External_ID__c = 'Req-'+OpportunityId+method;
            intsnp.Object_Name__c = 'Opportunity'; 
            if(!Test.isRunningTest()){
                insert intsnp;
            }
        }catch(DmlException dml){
            system.debug('DML Exception in capture request: '+dml);
        }catch(Exception ex){
            system.debug('Exception in capture request: '+ex);
        }
    }
}