/**
* @author Adiya
* @date 2023
* @group DynmaicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
* @description implementation of DynamicBusinessRuleAction interface to update Manager in Account once the manager get update in User
*/
public with sharing class DynamicBusineessRuleUpdateAccountManager implements DynamicBusinessRuleAction {

    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap,List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        System.debug('inside DynamicBusineessRuleUpdateAccountManager...'+records);
        if (triggerOrder == 'POST') {
            if(triggerContext.contains('Update')){
                updateAccountManager((List<User>)records, oldRecordMap, triggerContext);
            }
        }        
    }      
    
    public static void updateAccountManager(List<User> listOfUsers, Map<Id, SObject> mapOfOldUsers, String triggerContext){
        Set<Id> managerIds = new Set<Id>();
        Map<String,String> userNewMgrId = new Map<String,String>();
        
        for(Sobject usr : listOfUsers){
            SObject oldUserRecord = mapOfOldUsers.get((Id)usr.get('Id'));
            if((Id)oldUserRecord.get('ManagerId') != (Id)usr.get('ManagerId')){
                managerIds.add((Id)usr.get('ManagerId'));
                userNewMgrId.put(usr.Id,(Id)usr.get('ManagerId'));
            }
        }
        Map<Id,String> mgrIdNameMap = new Map<Id,String>();
        if(!managerIds.isEmpty()){
            for(User mgr : [SELECT Id,Name FROM User WHERE Id IN :managerIds /* OR Id IN :oldNewMgrId.keySet()*/]){
                mgrIdNameMap.put(mgr.Id,mgr.Name);
            }
        }
        System.debug('mgrIdNameMap...'+mgrIdNameMap.values());
        Map<String,String> userIdMgrNameMap = new Map<String,String>(); // User Id and new Manager Name Map
        if(!managerIds.isEmpty()){
            for(Sobject usr : listOfUsers){
                SObject oldUserRecord = mapOfOldUsers.get((Id)usr.get('Id'));
                if((Id)oldUserRecord.get('ManagerId') != (Id)usr.get('ManagerId')){
                    userIdMgrNameMap.put(usr.Id,mgrIdNameMap.get(userNewMgrId.get(usr.Id)));
                }
            }
            Map<Id,String> accMapToUpd = new Map<Id,String>();
            for(Account acc : [SELECT Id,CSM_Manager__c,CSM2__c FROM Account WHERE CSM2__c IN :userNewMgrId.keySet()]){
                accMapToUpd.put(acc.Id,userIdMgrNameMap.get(acc.CSM2__c));
            }
            if(accMapToUpd.size() > 0) {
                Database.executeBatch(new AccountManagerUpdateBatch(accMapToUpd));
            }
        }
    }
}