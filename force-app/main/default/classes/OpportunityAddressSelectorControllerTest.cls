/**
* @author        Ivan Yeung/salesforce services
* @date          2018-11-10
* @description   Unit Test class for OpportunityAddressSelectorController
* @group         Test
*
*/
@isTest
public with sharing class OpportunityAddressSelectorControllerTest {

    @isTest static void unitTest() {

        // prepare test data
        // by pass business action ,
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        List <Contact> contacts = TestDataFactory.customerContacts;
        List <Account> customers = TestDataFactory.customers;
        List <Account> partners = TestDataFactory.partners;
        List <Product2> products = TestDataFactory.products;
        List <Opportunity> opportunities = TestDataFactory.opportunities;
        TriggerHandler.clearAllBypasses();


        Opportunity o = opportunities[0];

        
        Map<String, Map<String, State__c>> states = TestDataFactory.states;
        Map<String, Country__c> countries = TestDataFactory.countries;


        Test.startTest();
        OpportunityAddressSelectorController  controller = OpportunityAddressSelectorController.getClass(o.Id);

        // operation: "update", "createUpdate"
        // accountType: "account", "distributor", "distributor"
        // addressType: billTo, "shipTo"
        Address__c addr = new Address__c();
        addr.Country__c = countries.get('US').Id;
        addr.State__c = states.get('US').get('CA').Id;
        addr.Street__c = '415 Mission Street';
        addr.City__c = 'San Francisco';
        addr.Zip_Postal_Code__c = '94105';
        String addressString = JSON.serialize(addr);

        OpportunityAddressSelectorController.createUpdateAddress(o.Id, 'createUpdate', 'distributor',  'billTo',addressString );
        OpportunityAddressSelectorController.createUpdateAddress(o.Id, 'createUpdate', 'reseller',  'shipTo',addressString );
        OpportunityAddressSelectorController.createUpdateAddress(o.Id, 'createUpdate', 'account',  'shipTo',addressString );

        // OpportunityAddressSelectorController.createUpdateAddress(o.Id, 'update', 'distributor',  'billTo',addressString );
        // OpportunityAddressSelectorController.createUpdateAddress(o.Id, 'update', 'reseller',  'shipTo',addressString );
        // OpportunityAddressSelectorController.createUpdateAddress(o.Id, 'update', 'account',  'shipTo',addressString );


        Test.stopTest();

    }


}