@isTest
public with sharing class DynBussRuleUpdAltEmailForRelatedCaseTest {
    
    @testSetup static void setup() {
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List <Contact> customerContacts = TestDataFactory.customerContacts;
        Case c = new Case();
        c.Subject = 'Test124';
        c.Origin = 'Email';
        c.Status='New';
        c.ContactId = customerContacts[0].Id;
        insert c;  

    }
    
    @isTest static void test_getAccountShare() {
        Contact con = [SELECT Id FROM Contact WHERE Id IN (SELECT ContactId FROM Case WHERE Subject = 'Test124')];
        Test.startTest();
            con.Use_Alt_Email_for_Case__c = true;
            update con;
        Test.stopTest();
    }
    
 
}