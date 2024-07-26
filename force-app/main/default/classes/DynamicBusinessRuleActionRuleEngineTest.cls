@isTest
public with sharing class DynamicBusinessRuleActionRuleEngineTest {
	
    @isTest static void test_CaseContactVerificationCondition() {
        TriggerHandler.bypass('RollUpSummaryUtilityTriggerHandler');
        // TriggerHandler.bypass('AccountTriggerHandler');
        // TriggerHandler.bypass('ContactTriggerHandler');


        System.debug('~~ Test: Case creation starts ~~');
        Id recordId = TestDataFactory.supportCases[0].Id;
        System.debug('~~ Test: Case creation ends ~~');


        System.debug('~~ Test: Case ~~' + TestDataFactory.supportCases[0]);
        System.debug('~~ Test: Contact ~~' + TestDataFactory.customerContacts[0]);
        System.debug('~~ Test: Contact_Verified_Condition__c ~~' + TestDataFactory.supportCases[0].Contact_Verified_Condition__c);

        List <Case> l = [select CaseNumber, id, Contact.Name, Contact.Contact_Status__c, Account.Id , Contact.AccountId from Case where id = : TestDataFactory.supportCases[0].Id];
        system.debug('~~ Test: case list: ' + l);
        system.debug('~~ Test: case list contact.Id: ' + l[0].contact.Id);
        system.debug('~~ Test: case list contact.Name: ' + l[0].contact.Name);
        system.debug('~~ Test: case list Contact_Status__c: ' + l[0].contact.Contact_Status__c);
        system.debug('~~ Test: case list AccountId: ' + l[0].contact.AccountId);


        test.startTest();


        System.assertEquals(true, TestDataFactory.supportCases[0].Contact_Verified_Condition__c);
        System.assertEquals(true, TestDataFactory.supportCases[0].Is_Contact_Verified__c);
        
        test.stopTest();

        TriggerHandler.clearBypass('AccountTriggerHandler');
        TriggerHandler.clearBypass('ContactTriggerHandler');

    }
    
    @isTest static void test_CaseHasEnterpriseAssetCondition() {
        TriggerHandler.bypass('RollUpSummaryUtilityTriggerHandler');
        
        Id recordId = TestDataFactory.supportCases[0].Id;
        
        test.startTest();
        
        //Case supportCase = [SELECT Is_Enterprise_Account__c FROM Case WHERE Id = :recordId];
        
        System.debug('~~ Test: Case ~~' + TestDataFactory.supportCases[0]);
        System.debug('~~ Test: Contact ~~' + TestDataFactory.customerContacts[0]);
        System.debug('~~ Test: Has_Enterprise_Asset_c ~~' + TestDataFactory.supportCases[0].Has_Enterprise_Asset__c);


        System.assertEquals(true, TestDataFactory.supportCases[0].Has_Enterprise_Asset__c);
        // System.assertEquals(true, TestDataFactory.supportCases[0].Is_Enterprise_Account__c); // 2019-06-12. this rule is no longer set by busienss rule by via trigger
        
        test.stopTest();
    }
    
    
    /*    
    @isTest static void testAccountTriggersOneRule() {
        Account a = new Account(Name='Jose Account',Partner_Birthdate__c=Date.newInstance(1988,5,20));
        insert a;
        
        // Retrieve the new account
        a = [SELECT Description, Account_Notes__c FROM Account WHERE Id =:a.Id];
        System.debug('Description after trigger fired: ' + a.Description);
        
        // Test that the trigger correctly updated the description
        System.assertEquals('www.josecvega.com', a.Description);
        System.assertEquals('VEGA', a.Account_Notes__c);
    }
    
    @isTest static void testAccountDoNotTrigger() {
        Account a = new Account(Name='Jose Account',Partner_Birthdate__c=Date.newInstance(1988,5,21));
        insert a;
        
        // Retrieve the new account
        a = [SELECT Description, Account_Notes__c FROM Account WHERE Id =:a.Id];
        System.debug('Description after trigger fired: ' + a.Description);
        
        // Test that the trigger correctly updated the description
        System.assertEquals('', a.Description);
        System.assertEquals('a', a.Account_Notes__c);
    }
    

    @isTest static void testCaseContactVerificationCondition() {
        Case c = new Case(Status='New',Origin='Email',ContactId='0033C000007d5HPQAY');
        insert c;
        
        //Retrieve the new case
        c = [SELECT Contact_Verified_Condition__c, Is_Contact_Verified__c FROM Case WHERE Id =: c.Id];
        System.debug('Is Contact Verified after trigger fired:' + c.Is_Contact_Verified__c);
        
        System.assertEquals(true, c.Is_Contact_Verified__c);
    }
    */
}