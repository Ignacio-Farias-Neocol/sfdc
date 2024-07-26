/**
* Test class for SFDC-18768 - CaseTechnicalAlertUpdateBatchTest
*/
public class AccountTriggerHelper {
    
    public static Boolean isHelperExecuted = false;
	
    public static void afterUpdate(){
        if(!isHelperExecuted){
            isHelperExecuted = true;
        } else {
            return;
        }
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, Account> oldMap = (Map<Id, Account>) Trigger.oldMap;
        for(Account acc: (List<Account>) Trigger.new){
            Account oldRecord = oldMap.get(acc.Id);
            if(acc.Technical_Alert__c != oldRecord.Technical_Alert__c || acc.Contact_Center_Alert__c != oldRecord.Contact_Center_Alert__c){
                accountIdSet.add(acc.Id);
            }
        }
        
        if(!accountIdSet.isEmpty()){
            CaseTechnicalAlertUpdateBatch caseBatch = new CaseTechnicalAlertUpdateBatch();
            caseBatch.accountIdSet = accountIdSet;
            Database.executeBatch(caseBatch, 10);
            
            ContactAlertUpdateBatch contactBatch = new ContactAlertUpdateBatch();
            contactBatch.accountIdSet = accountIdSet;
            Database.executeBatch(contactBatch, 10);
        }        
    }
}