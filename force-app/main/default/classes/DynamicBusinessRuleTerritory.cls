public with sharing class DynamicBusinessRuleTerritory implements DynamicBusinessRuleAction  { 
   
    public static final string SFDC_API_ENDPOINT = '/services/data/v56.0/composite/sobjects/';
    public static final string ACCOUNT_TERR_RUN_FIELD_API = 'Terr_Alignment_Run__c';

    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {

        System.debug('~~~~#~~~~: starting: ' +  'DynamicBusinessRuleTerritory');
      
        if (triggerOrder == 'POST') {

            Set<Id> accIdsForTerrRun = new Set<Id>();

            if (triggerContext.contains('Update') ){

                for(SObject newAccRecord: records){
                    SObject oldAccRecord = oldRecordMap.get((Id)newAccRecord.get('Id'));

                    if((newAccRecord.get('BillingPostalCode') != oldAccRecord.get('BillingPostalCode')) || 
               
                    (newAccRecord.get('BillingState') != oldAccRecord.get('BillingState')) || 
                    (newAccRecord.get('BillingStateCode') != oldAccRecord.get('BillingStateCode')) || 
                 
                    (newAccRecord.get('BillingCountry') != oldAccRecord.get('BillingCountry')) || 
                    (newAccRecord.get('BillingCountryCode') != oldAccRecord.get('BillingCountryCode')) || 
                  
                    (newAccRecord.get('BillingCity') != oldAccRecord.get('BillingCity'))) {

                        accIdsForTerrRun.add((Id)newAccRecord.get('Id'));
                        continue;
                    }
                }

                System.debug(':::: AccountIds for Terr Run: ' +  accIdsForTerrRun);
            }

            if(accIdsForTerrRun!=null && !accIdsForTerrRun.isEmpty() && accIdsForTerrRun.size()>200) {

                System.debug('Cannot Process more that 200 Account records for Territory Assignment Rules at a Time. Please Use a Batch size of 200.');
            }
            else if(accIdsForTerrRun!=null && !accIdsForTerrRun.isEmpty() && !System.isBatch()){

                runTerrAssignmentRules(accIdsForTerrRun);
            }            
        }
    }
   
     @future (callout=true)
      public static void runTerrAssignmentRules(Set<Id> accIds){

        System.debug(':: runTerrAssignmentRules ::');
        
        String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm(); 
        String accApi = sfdcURL + SFDC_API_ENDPOINT;
        String response = '';

        AccountTerrRunRequest.accFields reqBody;    

        for(Account acc : [Select Id, Terr_Alignment_Run__c from Account where Id in :accIds ]){
        
            AccountTerrRunRequest.fieldValues reqVal;
            AccountTerrRunRequest.arrtributeValues attr;
            reqBody=new AccountTerrRunRequest.accFields();  
            reqBody.records=new List<AccountTerrRunRequest.fieldValues>(); 
            reqBody.allOrNone=false; 
                   
            reqVal=new AccountTerrRunRequest.fieldValues();
    
            attr =new  AccountTerrRunRequest.arrtributeValues();
            attr.type='Account';
            reqVal.zattributes=attr;                     

            reqVal.Id=acc.Id;
            reqVal.TerrRun=acc.Terr_Alignment_Run__c+1;    
           
            reqBody.records.add(reqVal); 
        }             
       
        LogModel log = LogModel.startLog('DynamicBusinessRuleTerritory','runTerrAssignmentRules');           


        Http http = new Http();
        HttpRequest httpReq = new HttpRequest();  
        HTTPResponse res;
        String body='';
       
        try {  

        httpReq.setEndpoint(accApi); 
        httpReq.setMethod('PATCH');   
        httpReq.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());        
        httpReq.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        httpReq.setHeader('Content-Type','application/json');
        httpReq.setHeader('Sforce-Auto-Assign', 'TRUE');       
      
        body=JSON.serialize(reqBody,true).replace('zattributes', 'attributes').replace('TerrRun', ACCOUNT_TERR_RUN_FIELD_API);

        httpReq.setBody(body);
        res = http.send(httpReq);

        if (res.getStatusCode() == 200 ) {                   
            log.addLog('Success: Terr Assgn Rules Ran with request payload : ' + body + ' and response payload :'+res.getBody());     
      } else {  
           
            throw new CalloutException( res.getBody() );  
      }   

        } catch( System.Exception ex) {  
            log.addLog('Error: Terr Assgn Rules failed with payload : ' + body + ' and response payload :'+res.getBody() + ':: Error Message : '+ ex);  
            log.addExceptionLog(ex);   
            System.debug('ERROR: '+ ex);           
        }     
        log.endLog();
    }
}