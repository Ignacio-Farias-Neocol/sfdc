/**
* @author        Ivan Yeung/salesforce services
* @date          2019-07-02
* @description   Unit Test class for DynamicBusinessRuleSerialTerminated
* @group         Test
*
*/
@isTest
public with sharing class DynamicBusinessRuleSerialTerminatedTest {


    @isTest static void unitTest() {

        // by pass business action
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List<Contact> contacts = TestDataFactory.customerContacts;
        List<Account> customers = TestDataFactory.customers;
        List<Account> partners = TestDataFactory.partners;
        List<Product2> products = TestDataFactory.products;
        List<Opportunity> opportunities = TestDataFactory.opportunities;

        Contract contract = new Contract();
        contract.AccountId = opportunities[0].accountId;
        contract.SBQQ__Opportunity__c = opportunities[0].Id;
        insert contract;

        Serial__c serial = new Serial__c();
        serial.Serial_Number__c = '9999';
        serial.Status__c = 'Inactive';
        serial.Contract__c = contract.Id;
        serial.Is_Terminated__c = true; // terminated serial for this test
        insert serial;

        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c  = opportunities[0].accountId;
        subscription.SBQQ__Contract__c = contract.Id;
        subscription.SBCF_Serial_Number__c = null;
        subscription.SBQQ__Quantity__c = 1;
        insert subscription;

        Assigned_Serial__c assignedSerial = new Assigned_Serial__c();
        assignedSerial.Serial__c = serial.Id;
        assignedSerial.Subscription__c = subscription.Id;
        assignedSerial.Status__c = 'Active';
        insert assignedSerial;

        TriggerHandler.clearAllBypasses();

        List <Serial__c> serials = new List <Serial__c>();
        serials.add(serial);


        Test.startTest();

        DynamicBusinessRuleSerialTerminated d = new DynamicBusinessRuleSerialTerminated();
        d.processRecords(null, null, serials, '', '', '');

        Test.stopTest();

    }


}