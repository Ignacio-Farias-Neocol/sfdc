/**
 * @description       : Test Class for NEO_OpportunityUpdateRelatedHotList
 * @author            : Ignacio F.
 * @group             : 
 * @last modified on  : 07-16-2024
 * @last modified by  : Ignacio F.
**/
@isTest
public with sharing class NEO_OpportunityUpdateRelatedHotListTest {

    @TestSetup
    public static void makeData(){
        Territory2 territory = [Select Id, Theater2__c from Territory2 Where Theater2__c = 'AMERICAS' Limit 1 ];     

        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = 'Teston Road',
            BillingCity = 'Vaughan',
            BillingState = 'Ontario',
            BillingCountry = 'Canada',
            BillingPostalCode = 'L4H0L7',
            Type = 'Customer',
            Terr_Theater__c = 'AMERICAS',
            Is_Unit_Test__c = true,
            Territory__c = 'ONTARIO - TERRITORY',
            Terr_Region__c = 'CANADA - REGION',
            recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId()
        );
        insert testAccount;

        ObjectTerritory2Association  objTerr = new ObjectTerritory2Association(ObjectId = testAccount.Id, Territory2Id = territory.Id, AssociationCause =' Territory2Manual');
        insert objTerr;

        testAccount.Territory_ID__c = territory.Id;
        update testAccount;

        Account insertedAccount = [SELECT Id, Name, Terr_Theater__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        System.assertEquals('AMERICAS', insertedAccount.Terr_Theater__c, 'Account Terr_Theater__c should be AMERICAS');

        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Email = 'test@example.com',
            Phone = '+59896969696',
            CurrencyIsoCode = 'USD'
        );
        insert contact;

        List<Hot_List__c> hotLists = new List<Hot_List__c>();
        for(Integer i = 0; i < 5; i++){
            Hot_List__c hotList = new Hot_List__c(Contact__c = contact.Id, Account__c = insertedAccount.Id, Disposition__c = 'Marketing Qualified Lead');
            hotLists.add(hotList);
        }
        insert hotLists;

        Country__c country = NEO_TestDataFactory.createCountries(1, true, new Map<Schema.SObjectField, Object>{ Country__c.Name => 'Canada', Country__c.Country_ISO__c => 'CA' })[0];

        State__c state = NEO_TestDataFactory.createStates(1, true, new Map<Schema.SObjectField, Object>{ State__c.Name => 'Ontario', State__c.State_ISO__c => 'ON' })[0];

        Address__c billingAddress = NEO_TestDataFactory.getBillingAddress(1, country.Id, state.Id, insertedAccount.Id)[0];
        insert billingAddress;
        
        Address__c shippingAddress = NEO_TestDataFactory.getShippingAddress(1, country.Id, state.Id, insertedAccount.Id)[0];
        insert shippingAddress;
        
        List<Contract> contracts = new List<Contract>();
        for (Integer i = 0; i < 5; i++) {
            contracts.add( new Contract(
                BillingStreet = '123 Billing St ',
                BillingCity = 'Billing City ',
                BillingCountry = 'Canada',
                BillingState = 'Ontario',
                BillingPostalCode = '12345',
                BillingCountryCode = 'CA',
                ShippingStreet = '123 Shipping St ',
                ShippingCity = 'Shipping City ',
                ShippingCountry = 'Canada',
                ShippingState = 'Ontario',
                ShippingPostalCode = '54321',
                ShippingCountryCode = 'CA',
                AccountId = insertedAccount.Id,
                Billing_Address__c = billingAddress.Id,
                Shipping_Address__c = shippingAddress.Id,
                Most_Recent_Upsell_Hot_List__c = hotLists[i].Id
            ));
        }
        insert contracts;
    }

    @isTest
    public static void test_upsellAmendmentOrRenewal(){

        Account testAccount = [SELECT Id From Account LIMIT 1];
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        List<Contract> contracts = [SELECT Id FROM Contract];
        List<Hot_List__c> hotLists = [SELECT Id, Disposition__c FROM Hot_List__c];

        
        for(Hot_List__c hotList : hotLists){
            System.assertEquals('Marketing Qualified Lead', hotlist.Disposition__c);
        }
        
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            opps.add(new Opportunity(
                Name = 'Test Opportunity ' + i,
                StageName = 'Accepted',
                CloseDate = Date.today().addDays(30),
                AccountId = testAccount.Id,
                Primary_Contact__c = contact.Id,
                Bill_To_Account__c = testAccount.Id,
                Street__c = '123 Billing St ' + i,
                City__c = 'Billing City ' + i,
                Country__c = 'United States',
                State__c = 'Missouri',
                Zip_Postal_Code__c = '12345' + i,
                Country_ISO_Code__c = 'US',
                Ship_To_Street__c = '123 Shipping St ' + i,
                Ship_To_City__c = 'Shipping City ' + i,
                Ship_To_Country__c = 'United States',
                Ship_To_State__c = 'Missouri',
                Ship_To_Zip_Postal_Code__c = '54321' + i,
                Shipping_Country_ISO_Code__c = 'US',
                SBQQ__AmendedContract__c = contracts[i].Id,
                Hot_List__c = hotLists[i].Id
            ));
        }

        Test.startTest();
            insert opps;
        Test.stopTest();

        hotLists = [SELECT Id, Disposition__c from Hot_List__c];

        for(Hot_List__c hotList : hotLists){
            System.assertEquals('Converted', hotlist.Disposition__c);
        }
    }

    @isTest
    public static void test_upsellAmendmentOrRenewalNegative(){

        Account testAccount = [SELECT Id From Account LIMIT 1];
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        List<Contract> contracts = [SELECT Id FROM Contract];
        List<Hot_List__c> hotLists = [SELECT Id, Disposition__c FROM Hot_List__c];

        
        for(Hot_List__c hotList : hotLists){
            System.assertEquals('Marketing Qualified Lead', hotlist.Disposition__c);
        }
        
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            opps.add(new Opportunity(
                Name = 'Test Opportunity ' + i,
                StageName = 'Accepted',
                CloseDate = Date.today().addDays(30),
                AccountId = testAccount.Id,
                Primary_Contact__c = contact.Id,
                Bill_To_Account__c = testAccount.Id,
                Street__c = '123 Billing St ' + i,
                City__c = 'Billing City ' + i,
                Country__c = 'United States',
                State__c = 'Missouri',
                Zip_Postal_Code__c = '12345' + i,
                Country_ISO_Code__c = 'US',
                Ship_To_Street__c = '123 Shipping St ' + i,
                Ship_To_City__c = 'Shipping City ' + i,
                Ship_To_Country__c = 'United States',
                Ship_To_State__c = 'Missouri',
                Ship_To_Zip_Postal_Code__c = '54321' + i,
                Shipping_Country_ISO_Code__c = 'US',
                Hot_List__c = hotLists[i].Id
            ));
        }

        Test.startTest();
            insert opps;
        Test.stopTest();


        hotLists = [SELECT Id, Disposition__c from Hot_List__c];
        //Criteria is not met, Disposition field should not be updated to Converted.
        for(Hot_List__c hotList : hotLists){
            System.assertNotEquals('Converted', hotlist.Disposition__c);
        }
    }
} 

