/**
* @Description Test class to cover Account, Contact and Lead trigger used 
               for Merge for Skout Data migration process.
* @Author Jade Global 
* @Date 2022/01/13
* @group Test Class
*/
@isTest
public class SkoutDMMergeTestClass {
    @testSetup static void setupData(){
      Account acc = AdminDashboardDataFactory.getAccount();
      Contact cont = AdminDashboardDataFactory.getContact();
      cont.AccountId = acc.Id;
      Insert cont;  
    }
    
    @istest static void testAccountMerge(){
        Account acc = [Select Id, SkoutRecordId__c from Account];
        acc.SkoutRecordId__c = '1234';
        test.startTest();
        update acc;
        test.stopTest();
    }
    
    @isTest static void testContactMerge(){
        Contact cont = [Select Id, SkoutRecordId__c from Contact];
        cont.SkoutRecordId__c = '12345';
        test.startTest();
        update cont;
        test.stopTest();
    }
    
    @isTest static void testLeadMerge(){
        Lead leadObj = AdminDashboardDataFactory.createLead();
        leadObj.SkoutRecordId__c = '12356';
        test.startTest();
        update leadObj;
        test.stopTest();
    }
}