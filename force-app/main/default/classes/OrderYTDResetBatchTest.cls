@isTest
public class OrderYTDResetBatchTest {
    @isTest
    public static void testYTDResetField(){
        Account newAccount = new Account();
        newAccount.Is_Unit_Test__c = true;
        newAccount.name = 'Test';
        newAccount.Core_New_Business_Bookings_YTD__c = 100;
        newAccount.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        insert newAccount;
        
        ScheduleOrderYTDResetBatch obj = new ScheduleOrderYTDResetBatch();
        obj.execute(null); 
    }
}