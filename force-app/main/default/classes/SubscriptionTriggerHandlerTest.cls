/**
 * Created by iyeung on 2/15/19.
 */

@IsTest global with sharing class SubscriptionTriggerHandlerTest {
    @isTest static void unitTest() {


        // by pass business action ,
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        List <Contact> contacts = TestDataFactory.customerContacts;
        List <Account> customers = TestDataFactory.customers;
        List <Account> partners = TestDataFactory.partners;
        List <Product2> products = TestDataFactory.products;
        List <Opportunity> opportunities = TestDataFactory.opportunities;
        TriggerHandler.clearAllBypasses();


        // to do : properly create a subscription, for now just need to invoke trigger


        Contract contract = new Contract();
        contract.AccountId = opportunities[0].accountId;
        contract.SBQQ__Opportunity__c = opportunities[0].Id;
        insert contract;


        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Account__c  = opportunities[0].accountId;
        sub.SBQQ__Contract__c = contract.Id;
        sub.SBQQ__Quantity__c = 1;
        // sub.SBQQ__OrderProduct__c = productss[0].Id;
        insert sub;


    }






}