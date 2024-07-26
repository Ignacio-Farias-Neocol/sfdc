@istest
public with sharing class DeleteAppLogsBatchSchedTest {
    public static testMethod void testschedule() {
        List<AppLog__c> appLogList = new List<AppLog__c>();
        for(Integer i = 0; i < 5; i++) {
            appLogList.add(new AppLog__c(LogCategory__c = 'Apex',apexClassName__c = 'SubscriptionProcessBuilderClass'+i, message__c='processRecords'+i));
        }
        insert appLogList;
        List<AppLogDetail__c> appLogDetailList = new List<AppLogDetail__c>();
        for(AppLog__c appLogd : appLogList) {
            appLogDetailList.add(new AppLogDetail__c(AppLog__c = appLogd.Id));
        }
        insert appLogDetailList;
        Test.StartTest();
            DeleteAppLogsBatchSched sch = new DeleteAppLogsBatchSched();
            String sched = '0 0 12 * * ?';
            system.schedule('Test Sched', sched, sch );
        Test.stopTest();
  }
}