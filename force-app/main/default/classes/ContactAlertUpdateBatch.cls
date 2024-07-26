/**
* Test class for SFDC-18768 - CaseTechnicalAlertUpdateBatchTest
*/
public class ContactAlertUpdateBatch implements Database.Batchable <SObject> {
    
    public Set<Id> accountIdSet;
    
    // START METHOD
    public Database.QueryLocator start(Database.BatchableContext bc){        
        String queryString = 'Select Id, Contact_Center_Alert__c, Account.Contact_Center_Alert__c from Contact where AccountId =: accountIdSet';
        return Database.getQueryLocator(queryString);
    }
    
    //EXECUTE METHOD
    public void execute(Database.BatchableContext bc, List<Contact> scope){
        LogModel log = LogModel.startLog('ContactAlertUpdateBatch', 'execute');
        try{
            log.addLog('scope: ' + JSON.serialize(scope));
            for(Contact c: scope){ 
                c.Contact_Center_Alert__c = c.Account.Contact_Center_Alert__c;
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