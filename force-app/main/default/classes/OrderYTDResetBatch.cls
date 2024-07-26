global class OrderYTDResetBatch implements Database.Batchable<sObject>{
	global Database.QueryLocator start(Database.BatchableContext bc){ 
        String query = 'Select Id,Total_Bookings_YTD__c,Total_Core_Bookings_YTD__c,Core_Renewal_Bookings_YTD__c,Core_New_Business_Bookings_YTD__c FROM Account WHERE Total_Bookings_YTD__c != null OR Total_Core_Bookings_YTD__c != null OR Core_Renewal_Bookings_YTD__c != null OR Core_New_Business_Bookings_YTD__c != null ';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc,List<Account> acctList){
        List<Account> actList = new List<Account>();
        for(Account eachAccount : acctList){
            eachAccount.Total_Bookings_YTD__c = null;
            eachAccount.Total_Core_Bookings_YTD__c = null;
            eachAccount.Core_Renewal_Bookings_YTD__c = null;
            eachAccount.Core_New_Business_Bookings_YTD__c = null;
            actList.add(eachAccount);
        }
        if(!actList.isEmpty()){
            update actList;
        }
    }
    global void finish(Database.BatchableContext bc){
        
    }
}