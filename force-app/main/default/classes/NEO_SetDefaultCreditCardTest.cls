/**
 * @description       : Test Class for Set Default Opportunity. Rework from PB added to Opportunity Record Trigger Before Save Flow.
 * @author            : Ignacio F.
 * @group             : 
 * @last modified on  : 07-17-2024
 * @last modified by  : Ignacio F.
**/
@isTest
public with sharing class NEO_SetDefaultCreditCardTest {
    @TestSetup
    static void makeData(){
        Account testaccount = NEO_TestDataFactory.getPartnerAccounts(1)[0];
        testaccount.Payment_Terms__c = 'Credit Card';
        insert testAccount;

        Contact contact = NEO_TestDataFactory.getRelatedContacts(1, testAccount.Id)[0];
        insert contact;

        List<Opportunity> opps = NEO_TestDataFactory.getOpportunities(5, testAccount.Id, contact.Id);
        insert opps;    

        Credit_Card__c cc = new Credit_Card__c(
            Account__c = testAccount.Id,
            Card_Type__c = 'Visa',
            Expiration__c = '05/25',
            Last_4_of_CC__c = '1234',
            CurrencyIsoCode = 'USD',
            Is_Default__c = true
        );
        insert cc;
    }

    /**
    * @description Positive scenario, default CC should be set on the Opportunity.
    * @author Ignacio F. | 07-12-2024 
    **/
    @isTest
    public static void test_SetDefaultCCPositive(){
        Account testAccount = [SELECT Id From Account LIMIT 1];

        Contact contact = [SELECT Id From Contact LIMIT 1];

        List<Opportunity> opps = NEO_TestDataFactory.getOpportunities(5, testAccount.Id, contact.Id);

        Test.startTest();
            insert opps;
        Test.stopTest();

        Credit_Card__c cc = [Select Id FROM Credit_Card__c WHERE Is_Default__c = true LIMIT 1];

        opps = [SELECT Id, Bill_To_Credit_Card__c From Opportunity where Bill_To_Credit_Card__c =: cc.Id];

        System.assertEquals(5, opps.size(), 'There should be 5 opportunities with a default credit card');
    }

    /**
    * @description Payment Method on account is not set so Default CC should not be present in Oppty.
    * @author Ignacio F. | 07-12-2024 
    **/
    @isTest
    public static void test_Negative(){
        Account testaccount = NEO_TestDataFactory.createAccounts(1, true)[0];
        
        Contact contact = NEO_TestDataFactory.getRelatedContacts(1, testAccount.Id)[0];
        contact.LastName = 'Negative';
        contact.Phone = '+59888888888';
        contact.Email = 'negative@example.com';
        insert contact;

        List<Opportunity> opps = NEO_TestDataFactory.getOpportunities(5, testAccount.Id, contact.Id);

        Test.startTest();
            insert opps;
        Test.stopTest();

        Credit_Card__c cc = [Select Id FROM Credit_Card__c WHERE Is_Default__c = true LIMIT 1];

        opps = [SELECT Id, Bill_To_Credit_Card__c From Opportunity where Bill_To_Credit_Card__c =: cc.Id];

        System.assertEquals(0, opps.size(), 'opps list should not have opportunities with a default credit card');
    }

    /**
    * @description Payment Method on account is not set so Default CC should not be present in Oppty.
    * @author Ignacio F. | 07-12-2024 
    **/
    @isTest
    public static void test_UpdatePositive(){
        Account testaccount = NEO_TestDataFactory.createAccounts(1, true)[0];
        
        Contact contact = NEO_TestDataFactory.getRelatedContacts(1, testaccount.Id)[0];
        contact.LastName = 'Negative';
        contact.Phone = '+59888888888';
        contact.Email = 'negative@example.com';
        insert contact;

        List<Opportunity> opps = NEO_TestDataFactory.getOpportunities(5, testaccount.Id, contact.Id);
        insert opps;

        Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp : opps){
            oppIds.add(opp.Id);
        }


        Credit_Card__c cc = new Credit_Card__c(
            Account__c = testaccount.Id,
            Card_Type__c = 'Visa',
            Expiration__c = '05/25',
            Last_4_of_CC__c = '1234',
            CurrencyIsoCode = 'USD',
            Is_Default__c = true
        );
        insert cc;

        testaccount.Payment_Terms__c = 'Credit Card';
        update testaccount;
        
        opps = [SELECT Id, Bill_To_Credit_Card__c, Bill_To_Account__c From Opportunity where Id IN: oppIds];
        
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for(Opportunity opp : opps){
            System.AssertEquals(testaccount.Id, opp.Bill_To_Account__c);
            //opp.Bill_To_Account__c = testaccount.Id;
            opp.Distributor__c = testaccount.Id;
            oppsToUpdate.add(opp);
        }

        update oppsToUpdate;

        opps = [SELECT Id, Bill_To_Credit_Card__c From Opportunity where Bill_To_Credit_Card__c != null];

        System.assertEquals(5, opps.size(), 'There should be 5 opportunities with a default credit card');
    }
}