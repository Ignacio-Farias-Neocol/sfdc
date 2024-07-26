global with sharing class UpdateCSMName_Batch implements Database.Batchable<SObject>, Database.Stateful {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String SOQL = 'SELECT Id,CSM__c,CSM_Name__c FROM Account WHERE CSM__c!=NULL AND CSM_Name__c !=NULL';
        System.debug('SOQL...'+SOQL);
        return Database.getQueryLocator(SOQL);
    }
    public void execute(Database.BatchableContext BC, List<Account> accounts){
        LogModel log = LogModel.startLog('UpdateCSMName_Batch', 'executeupdateAccountWithAccTeamMembers');
		try{
            List<Account> accList = new List<Account>();
            Map<Id,User> userMap = new Map<ID, User>([SELECT Id, Name, Manager.Name FROM User]);
            List<String> lstOfCSMNames;
            List<String> lstOfCSMManagerNames;
            for(Account acc : accounts){
                Account accToUpdate = new Account();
                accToUpdate.Id = acc.Id;
                List<String> userIds = acc.CSM__C.split(',');
                System.debug('userIds..'+userIds);
                lstOfCSMNames = new List<String>();
                lstOfCSMManagerNames = new List<String>();
                for(Id userId : userIds){
                    System.debug('userMap.get(userId)...'+userMap.get(userId).Name);
                    //lstOfCSMNames.add(userMap.get(userId).Name);
                    lstOfCSMManagerNames.add(userMap.get(userId).Manager.Name);
                }
                //accToUpdate.CSM_Name__c = String.join(lstOfCSMNames, ',');
                accToUpdate.CSM_Manager__c = String.join(lstOfCSMManagerNames, ',');
                accList.add(accToUpdate);
            }
            Update accList;
        }catch(Exception ex){
            log.addExceptionLog(ex);
        }
    }
    public void finish(Database.BatchableContext BC){
    }
}