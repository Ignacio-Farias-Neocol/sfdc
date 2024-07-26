/**
* @author Aditya
* @date 2024-04-09
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description implementation of DynamicBusinessRuleAction interface & call Account changes after insert/update.

* @description SFDC-***** Update CSM Manager based on CSM User
*/

public class DynamicBusinessRuleCSMUpdate implements DynamicBusinessRuleAction{
    
    /******************************************************************************************************
* @description called CSM2__c field change after account update.
* @param trigger.new map
* @return none, the result should be set to account object.
* @example 
*******************************************************************************************************/
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        
        try{
            
            Set<Id> csmUserIds = new Set<Id>();
            
            List<Account> listAccounts = (List<Account>) newRecordMap.values();
            List<Account> listAccToUpdate = new List<Account>();
            for(Account acc:listAccounts){
                SObject oldAccRecord = oldRecordMap.get((Id)acc.get('Id'));
                //verify CSM2__c field change.
                if(acc.get('CSM2__c') != oldAccRecord.get('CSM2__c')){
                    if (acc.CSM2__c != null) {
                        csmUserIds.add(acc.CSM2__c);
                    }
                    listAccToUpdate.add(acc);
                }
            }
            
            Map<Id,User> csmUsersMap = new Map<Id,User>([Select Id,Name,Manager.name FROM User WHERE Id IN :csmUserIds]);
            
            for(Account acc:listAccToUpdate){
                if (acc.CSM2__c != null && csmUsersMap.containsKey(acc.CSM2__c)) {
                    User csmUser = csmUsersMap.get(acc.CSM2__c);
                    acc.CSM_Name__c = csmUser.Name;
                    acc.CSM_Manager__c = csmUser.Manager.Name;
                } else {
                    acc.CSM_Name__c = null;
                    acc.CSM_Manager__c = null;
                }
            }
            
        }
        catch (Exception Ex){
            AppLog__c log = new AppLog__c(Is_Error__c=true,message__c = Ex.getMessage(),apexClassName__c = 'DynamicBusinessRuleCSMUpdate');
            Insert log;
        }
    }
}