/**
* @author Aditya
* @date 13 July 2022
* @description Test class for UpdateCommunityUserCurrency
*/
@isTest
public with sharing class UpdateCommunityUserCurrencyTest {
    
    @testSetup static void setup() {
        List<Account> listOfAcc = new List<Account>();
        Account testAccountC = new Account();
        testAccountC.Name='Customer Test';
        testAccountC.Type='Customer';
        testAccountC.Type = 'Partner - Reseller';
        testAccountC.recordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        listOfAcc.add(testAccountC);
        Account testAccountC2 = new Account();
        testAccountC2.Name='Customer Test2';
        testAccountC2.Type='Customer';
        testAccountC2.Type = 'Partner - Reseller';
        testAccountC2.recordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        listOfAcc.add(testAccountC2);
        insert listOfAcc;
        
        Contract testContractC=new Contract();
        testContractC.StartDate=Date.today();
        testContractC.ContractTerm=12;
        testContractC.AccountId=testAccountC.Id;
        testContractC.Status='Draft';
        insert testContractC;
        
        Contact commCont=new Contact();
        commCont.Contact_Status__c='Active';
        commCont.AccountId=testAccountC.Id;
        commCont.firstName ='Test Contact FName';
        commCont.LastName='Test Contact LName';
        commCont.Email='testcontact@gmail.com.invalid';
        insert commCont;
    }
    
        @isTest static void updateCurrencyTest1() {
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            contact c=[select Id,email from Contact];
            Profile pr = [SELECT Id,Name FROM Profile WHERE Name = 'Barracuda Partner Core Admin' LIMIT 1];
            
            List<User> usrList = new List<User>();
            User u = new User();
            u.Alias = 'commUser';
            u.Email = 'communityusertest@test.com';
            u.EmailEncodingKey = 'UTF-8';
            u.LastName = 'CommunityUserContact';
            u.LanguageLocaleKey = 'en_US';
            u.LocaleSidKey = 'en_US';
            u.ProfileId = pr.Id;
            u.TimeZoneSidKey = 'America/Los_Angeles';
            u.UserName = 'communityusertest@barracudatest.com';
            u.contactId = c.Id;
            usrList.add(u);
            insert usrList;
            
            List<Id> usrIds = new List<Id>();
            for(User usr : usrList){
                usrIds.add(usr.Id);            
            }
            List<User> listOfUser = [SELECT Id,Contact.LastName,Contact.Account.CurrencyIsoCode,CurrencyIsoCode,DefaultCurrencyIsoCode FROM USER WHERE Id IN :usrIds];
            for(User usr : listOfUser){
                System.assertEquals(usr.Contact.Account.CurrencyIsoCode,usr.CurrencyIsoCode);
                System.assertEquals(usr.Contact.Account.CurrencyIsoCode,usr.DefaultCurrencyIsoCode);
            }
        }
    }
    
    @isTest static void updateCurrencyTest() {
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            contact c=[select Id,email from Contact];
            Profile pr = [SELECT Id,Name FROM Profile WHERE Name = 'Barracuda Partner Core Admin' LIMIT 1];
            account a = [select id,CurrencyIsoCode from account limit 1];
            
            List<User> usrList = new List<User>();
            User u = new User();
            u.Alias = 'commUser';
            u.Email = 'communityusertest@test.com';
            u.EmailEncodingKey = 'UTF-8';
            u.LastName = 'CommunityUserContact';
            u.LanguageLocaleKey = 'en_US';
            u.LocaleSidKey = 'en_US';
            u.ProfileId = pr.Id;
            u.TimeZoneSidKey = 'America/Los_Angeles';
            u.UserName = 'communityusertest@barracudatest.com';
            u.contactId = c.Id;
            usrList.add(u);
            insert usrList;
            a.CurrencyIsoCode = 'EUR';
            update a;
            
            List<Id> usrIds = new List<Id>();
            for(User usr : usrList){
                usrIds.add(usr.Id);            
            }
            List<User> listOfUser = [SELECT Id,Contact.LastName,Contact.Account.CurrencyIsoCode,CurrencyIsoCode,DefaultCurrencyIsoCode FROM USER WHERE Id IN :usrIds];
            for(User usr : listOfUser){
                System.assertEquals(usr.Contact.Account.CurrencyIsoCode,usr.CurrencyIsoCode);
                System.assertEquals(usr.Contact.Account.CurrencyIsoCode,usr.DefaultCurrencyIsoCode);
            }
        }
    }
    
    @isTest static void updateCurrencyTest3() {
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            contact c=[select Id,email,accountId from Contact];
            Profile pr = [SELECT Id,Name FROM Profile WHERE Name = 'Barracuda Partner Core Admin' LIMIT 1];
            account acc = [select id,CurrencyIsoCode from account where id!= :c.accountId LIMIT 1];
            acc.IsPartner = true;
            update acc;
            List<User> usrList = new List<User>();
            User u = new User();
            u.Alias = 'commUser';
            u.Email = 'communityusertest@test.com';
            u.EmailEncodingKey = 'UTF-8';
            u.LastName = 'CommunityUserContact';
            u.LanguageLocaleKey = 'en_US';
            u.LocaleSidKey = 'en_US';
            u.ProfileId = pr.Id;
            u.TimeZoneSidKey = 'America/Los_Angeles';
            u.UserName = 'communityusertest@barracudatest.com';
            u.contactId = c.Id;
            usrList.add(u);
            insert usrList;
            c.accountid = acc.id;
            update c;
            
            List<Id> usrIds = new List<Id>();
            for(User usr : usrList){
                usrIds.add(usr.Id);            
            }
            List<User> listOfUser = [SELECT Id,Contact.LastName,Contact.Account.CurrencyIsoCode,CurrencyIsoCode,DefaultCurrencyIsoCode FROM USER WHERE Id IN :usrIds];
            for(User usr : listOfUser){
                System.assertEquals(usr.Contact.Account.CurrencyIsoCode,usr.CurrencyIsoCode);
                System.assertEquals(usr.Contact.Account.CurrencyIsoCode,usr.DefaultCurrencyIsoCode);
            }
        }
    }

}