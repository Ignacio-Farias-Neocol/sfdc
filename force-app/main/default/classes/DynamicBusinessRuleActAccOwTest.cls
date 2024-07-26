/**
* @author Dilowar Hussain
* @date 2023-03-03
*
* @description 
* 
*
* 
* This is a test class for the main class DynamicBusinessRuleActivateAccOwner
*/
@isTest
public with sharing class DynamicBusinessRuleActAccOwTest {
    public static testMethod void accountOwnerTest(){
        try{
            //InsertFutureUserForTestClass.insertUser();
            system.debug('Start of the Test Class');
            List<User> activeUserLst = [select id, name, isActive from User where isActive = true and username like '%dhussain@barracuda.com%'];
            List<User> inActiveUserLst = [select id, name, isActive from User where isActive = false limit 1];
            
            //List<Account> newAccount = TestDataFactory.customers;
            //List<Contact> cusCon = TestDataFactory.customerContacts;
            
            Account acc = new Account();
            acc.Name = 'Test Account';
            acc.OwnerId = inActiveUserLst[0].id;
            insert acc;
            Contact con = new Contact();
            con.accountId = acc.id;
            con.LastName = 'Test Contact';
            con.OwnerId = inActiveUserLst[0].id;
            insert con;
            Test.startTest();
            List<Account> lstAcc = [select id, name, ownerId from Account where id = :acc.id];
            List<Contact> lstCon = [select id, name, OwnerId, Owner_IsActive__c, AccountId, Account.OwnerId from Contact where Owner_IsActive__c = FALSE and accountId = :acc.id];
            lstAcc[0].ownerId = activeUserLst[0].id;
            update lstAcc;
            Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception occurred at' +e.getStackTraceString());
        }
    }
}