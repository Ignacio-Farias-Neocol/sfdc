@isTest
public with sharing class AccountShareHelperTest {
    
    @testSetup static void setup() {
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        Account acc = new Account();
        acc.Name = 'testAccount';
        insert acc;
    }
    
    @isTest static void test_getAccountShare() {
        List<Account> accList = [SELECT Id, Name FROM Account WHERE Name='testAccount' LIMIT 1];
        
        Profile pr = [SELECT Id,Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Test.startTest();
        User u = new User();
        u.Alias = 'usertest';
        u.Email = 'UserTest@test.com';
        u.EmailEncodingKey = 'UTF-8';
        u.LastName = 'UserTest';
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.ProfileId = pr.Id;
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.UserName = 'TestUser@barracudatest.com';
        insert u;
              
        AccountShare newAcctShare = new AccountShare();
        newAcctShare.AccountId = accList[0].Id;
        newAcctShare.UserOrGroupId = u.id;
        newAcctShare.AccountAccessLevel = 'Edit';
        newAcctShare.ContactAccessLevel = 'Edit';
        newAcctShare.OpportunityAccessLevel = 'Edit';
        insert newAcctShare;        
        
        Boolean accShareAvail = AccountShareHelper.getAccountShare(accList[0].Id, u.id);
        
        Test.stopTest();
        
        System.assert(accShareAvail);
    }
    
    @isTest static void test_addAccountShare() {
        List<Account> accList = [SELECT Id, Name FROM Account WHERE Name='testAccount' LIMIT 1];
        
        Profile pr = [SELECT Id,Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Test.startTest();
        User u = new User();
        u.Alias = 'usertest';
        u.Email = 'UserTest@test.com';
        u.EmailEncodingKey = 'UTF-8';
        u.LastName = 'UserTest';
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.ProfileId = pr.Id;
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.UserName = 'TestUser@barracudatest.com';
        insert u;
              
        AccountShareHelper.addAccountShare(accList[0].Id, u.id);
        
        Test.stopTest();
        
        List<AccountShare> acctShare = [SELECT Id FROM AccountShare WHERE AccountId = :accList[0].Id AND UserOrGroupId = :u.id AND RowCause = 'manual' LIMIT 1];
        System.assert(acctShare!=null && acctShare.size()>0);
    }
    
    @isTest static void test_deleteAccountShare() {
        List<Account> accList = [SELECT Id, Name FROM Account WHERE Name='testAccount' LIMIT 1];
        
        Profile pr = [SELECT Id,Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Test.startTest();
        User u = new User();
        u.Alias = 'usertest';
        u.Email = 'UserTest@test.com';
        u.EmailEncodingKey = 'UTF-8';
        u.LastName = 'UserTest';
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.ProfileId = pr.Id;
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.UserName = 'TestUser@barracudatest.com';
        insert u;
              
        AccountShare newAcctShare = new AccountShare();
        newAcctShare.AccountId = accList[0].Id;
        newAcctShare.UserOrGroupId = u.id;
        newAcctShare.AccountAccessLevel = 'Edit';
        newAcctShare.ContactAccessLevel = 'Edit';
        newAcctShare.OpportunityAccessLevel = 'Edit';
        insert newAcctShare;        
        
        AccountShareHelper.deleteAccountShare(accList[0].Id, u.id);
        
        Test.stopTest();
        List<AccountShare> acctShare = [SELECT Id FROM AccountShare WHERE AccountId = :accList[0].Id AND UserOrGroupId = :u.id AND RowCause = 'manual' LIMIT 1];
        System.assert(acctShare.size()==0);
    }
    
}