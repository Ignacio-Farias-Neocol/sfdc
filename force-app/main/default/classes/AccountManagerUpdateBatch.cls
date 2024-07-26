public class AccountManagerUpdateBatch implements Database.Batchable<sObject>, Database.Stateful{
    public Map<Id,String> accMap = new Map<Id,String>();
    public AccountManagerUpdateBatch(Map<Id,String> accMgrMap){
        accMap = accMgrMap;
    }
	public Database.QueryLocator start(Database.BatchableContext BC){
        Set<Id> setIds = accMap.keySet();
		String soqlQuery = 'Select id from Account where Id IN :setIds';
        return Database.getQueryLocator(soqlQuery);
    }
    public void execute(Database.BatchableContext BC, List<Account> accList){
        LogModel log = LogModel.startLog('AccountManagerUpdateBatch', 'UpdateCSMMamanger', LogModel.LOG_CATEGORY_APEX);
        List<Account> accListToUpdate = new List<Account>();
        try{
            for(Account acc: accList){
                Account a = new Account();
                a.Id=acc.Id;
                a.CSM_Manager__c = accMap.get(acc.Id);
                accListToUpdate.add(a);
            }
            if(accListToUpdate!=null && accListToUpdate.size()>0){
                UPDATE accListToUpdate;
            }
        }Catch(Exception e){
            log.addExceptionLog(e); 
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    }
    public void finish(Database.BatchableContext BC) {
    }
}