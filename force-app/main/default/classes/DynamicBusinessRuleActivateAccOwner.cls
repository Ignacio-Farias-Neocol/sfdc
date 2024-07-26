/**
* @author Dilowar Hussain
* @date 2023-03-03
*
* @description 
* 
*
* 
* This has been added as a part of SFDC-17119
* Modification to this class has been done as a part of SFDC-19287.
*/
public with sharing class DynamicBusinessRuleActivateAccOwner implements DynamicBusinessRuleAction{
    /**
    * Method description: 
    * @param
    * @Return
    */
    public void processRecords(Map<Id,SObject> newRecordMap, 
                                                            Map<Id,SObject> oldRecordMap,
                                                            List <SObject> records, 
                                                            String jsonParameter, 
                                                            String triggerOrder, 
                                                            String triggerContext) {
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('DynamicBusinessRuleActivateAccOwner', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        try{
            Set<String> accountIds = new Set<String>();
            if((triggerContext.contains('Update') || triggerContext.contains('Insert'))){
                for(SObject rec: records){
                    Account acc = (Account)rec;
                    Account acc02 = oldRecordMap == null ? null : (Account)oldRecordMap.get(acc.Id);
                    if (acc02 == null){acc02 = new Account();}
                    if(acc.OwnerId != NULL && acc.Owner_IsActive__c == TRUE || (acc.OwnerId != NULL && acc.Owner_IsActive__c == TRUE && acc.OwnerId != acc02.OwnerId && acc02.Owner_IsActive__c == FALSE)){
                        accountIds.add(acc.id);
                        //mapAccount.put(acc.id, acc);
                    }
                }
                if(!accountIds.isEmpty()){
                    //System.debug('accountIds is:' +accountIds);
                    updateRelatedContacts(accountIds);
                }
                /*if(!mapAccount.isEmpty()){
                    lstCon = [select id, name, OwnerId, Owner_IsActive__c, AccountId, Account.OwnerId from Contact where Owner_IsActive__c = FALSE and accountId in :mapAccount.keySet()];
                    for(Contact con :lstCon){
                        if(mapAccount.containsKey(con.AccountId)){
                            con.OwnerId = mapAccount.get(con.AccountId).ownerId;
                             lstConUpdate.add(con);
                        }
                    }if(!lstConUpdate.isEmpty()){
                        update lstConUpdate;
                    }
                }*/
            }
        }Catch (Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
    }
    /**
    * Method description: 
    *      Added a future method to perform DML on related Contacts. 
    * @param
    * @Return
    *
    * This method has been added as a part of SFDC-19287
    */
    @future
    public static void updateRelatedContacts (Set<String> accIds){
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('DynamicBusinessRuleActivateAccOwner', 'updateRelatedContacts', LogModel.LOG_CATEGORY_APEX);
        List<Contact> lstConUpdate = new List<Contact>();
        List<Account> lstAcc = new List<Account>();
        Map<Id, Account> mapAccount = new Map<Id, Account>();
        try{
            //System.debug('accIds inside Future is:' +accIds);
            for(Account acc : [select id, name, ownerId from Account where id in :accIds]){
                mapAccount.put(acc.id, acc);
            }
            //System.debug('mapAccount inside Future is:' +mapAccount);
            for(Contact con :[select id, name, OwnerId, Owner_IsActive__c, AccountId, Account.OwnerId from Contact where Owner_IsActive__c = FALSE and accountId in :accIds FOR UPDATE]){
                if(mapAccount.containsKey(con.AccountId)){
                    //system.debug('Exists');
                    con.OwnerId = mapAccount.get(con.AccountId).ownerId;
                    lstConUpdate.add(con);
                }
            }
            //system.debug('lstConUpdate is:' +lstConUpdate);
            if(!lstConUpdate.isEmpty()){
                //update lstConUpdate;
                Database.SaveResult[] srList = Database.update(lstConUpdate, false);
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
    }
}