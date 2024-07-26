/**
* Test class for SFDC-18768 - CaseTechnicalAlertUpdateBatchTest
*/
public class CaseTechnicalAlertUpdateBatch implements Database.Batchable <SObject> {
    
    public Set<Id> accountIdSet;
    
    // START METHOD
    public Database.QueryLocator start(Database.BatchableContext bc){        
        String queryString = 'Select Id, Technical_Alert__c, Contact_Center_Alert__c, Account.Contact_Center_Alert__c, Account.Technical_Alert__c from Case where Status != \'Closed\' and AccountId =: accountIdSet';
        return Database.getQueryLocator(queryString);
    }
    
    //EXECUTE METHOD
    public void execute(Database.BatchableContext bc, List<Case> scope){
        LogModel log = LogModel.startLog('CaseTechnicalAlertUpdateBatch', 'execute');
        try{
            log.addLog('scope: ' + JSON.serialize(scope));
            for(Case c: scope){ 
                c.Technical_Alert__c = c.Account.Technical_Alert__c;
                c.Contact_Center_Alert__c = c.Account.Contact_Center_Alert__c;
                If(c.Account.Technical_Alert__c != null || c.Account.Contact_Center_Alert__c != null){
                    c.Alert_Exists__c = true;
                } else {
                    c.Alert_Exists__c = false;
                }
            }
            update scope;
        } Catch(Exception e){
            System.debug('**Error Message: ' + e.getMessage() + '\n LineNumber: ' + e.getLineNumber() + '\n Exception Type: ' + e.getTypeName() + '\n Cause: ' + e.getCause() + '\nStack Trace ' + e.getStackTraceString());
            log.addExceptionLog(e);
        }        
    }
    
    //FINISH METHOD
    public void finish(Database.BatchableContext bc){

    }
    
}