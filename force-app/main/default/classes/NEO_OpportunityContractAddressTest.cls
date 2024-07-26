/**
 * @description       : Test class for OpportunityContractAddressHandler
 * @author            : Ignacio F.
 * @group             : 
 * @last modified on  : 07-09-2024
 * @last modified by  : Ignacio F.
**/
@isTest
public class NEO_OpportunityContractAddressTest {
    @testSetup
    static void setupTestData() {


        Account account = NEO_TestDataFactory.getPartnerAccounts(1)[0];
        insert account;

        Contact contact = NEO_TestDataFactory.getRelatedContacts(1, account.Id)[0];
        insert contact;

        Country__c country = new Country__c(
            Country_ISO__c = 'US',
            Name = 'United States'
        );
        insert country;

        State__c state = new State__c(
            Country__c = country.Id,
            State_ISO__c = 'MO',
            Name = 'Missouri'
        );
        insert state;

        Address__c billingAddress = NEO_TestDataFactory.getBillingAddress(1, country.Id, state.Id, account.Id)[0];
        insert billingAddress;
        
        Address__c shippingAddress = NEO_TestDataFactory.getShippingAddress(1, country.Id, state.Id, account.Id)[0];
        insert shippingAddress;
        
        Contract contract = new Contract(
            BillingStreet = '123 Billing St ',
            BillingCity = 'Billing City ',
            BillingCountry = 'United States',
            BillingState = 'Missouri',
            BillingPostalCode = '12345',
            BillingCountryCode = 'US',
            ShippingStreet = '123 Shipping St ',
            ShippingCity = 'Shipping City ',
            ShippingCountry = 'United States',
            ShippingState = 'Missouri',
            ShippingPostalCode = '54321',
            ShippingCountryCode = 'US',
            AccountId = account.Id,
            Billing_Address__c = billingAddress.Id,
            Shipping_Address__c = shippingAddress.Id
        );
        insert contract;
    }

    @isTest
    static void testProcessRecords_Positive() {
        Account acc = [SELECT Id From Account LIMIT 1];
        Contract contract = [SELECT Id, BillingCity From Contract Where BillingCity != null LIMIT 1 ];
        System.assertNotEquals(null, contract.BillingCity);
        Contact contact = [SELECT Id From Contact LIMIT 1];

        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                AccountId = acc.Id,
                OwnerId = UserInfo.getUserId(),
                StageName = 'Accepted',
                CloseDate = Date.today().addDays(30),
                Asset_HW_Contract__c = contract.Id,
                Business_Group__c = null,
                SBQQ__AmendedContract__c = contract.Id,
                Primary_Contact__c = contact.Id
            );
            opportunities.add(opp);
        }

        NEO_OpportunityContractAddress oppContract = new NEO_OpportunityContractAddress();
        oppContract.processRecords(new Map<Id,Opportunity>() , new Map<Id,Opportunity>(), opportunities, null, null, null);

        for (Opportunity opp : opportunities) {
            System.assertNotEquals(null, opp.City__c, 'City__c should be updated');
            System.assertNotEquals(null, opp.Ship_To_City__c, 'Ship_To_City__c should be updated');
        }
    }

    @isTest
    static void testHandleOpportunities_Negative() {
        Account acc = [SELECT Id From Account LIMIT 1];
        Contract contract = [SELECT Id From Contract LIMIT 1];
        Contact contact = [SELECT Id From Contact LIMIT 1];

        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                AccountId = acc.Id,
                OwnerId = UserInfo.getUserId(),
                StageName = 'Accepted',
                CloseDate = Date.today().addDays(30),
                Asset_HW_Contract__c = null,
                Business_Group__c = null,
                SBQQ__AmendedContract__c = contract.Id,
                SBQQ__RenewedContract__c = contract.Id,
                Primary_Contact__c = contact.Id
            );
            opportunities.add(opp);
        }
        
        
        Test.startTest();
        NEO_OpportunityContractAddress oppContract = new NEO_OpportunityContractAddress();
            oppContract.processRecords(new Map<Id,Opportunity>() , new Map<Id,Opportunity>(), opportunities, null, null, null);
        Test.stopTest();

        // Verify the non-updated opportunities
        for (Opportunity opp : [SELECT Id, City__c, Ship_To_City__c FROM Opportunity WHERE Id IN :opportunities]) {
            System.assertEquals(null, opp.City__c, 'City__c should not be updated');
            System.assertEquals(null, opp.Ship_To_City__c, 'Ship_To_City__c should not be updated');
        }
    }

    
    @isTest
    static void testProcessRecordsUpdate_Positive() {
        Account acc = [SELECT Id From Account LIMIT 1];
        Contract contract = [SELECT Id, BillingCity From Contract Where BillingCity != null LIMIT 1 ];
        System.assertNotEquals(null, contract.BillingCity);
        Contact contact = [SELECT Id From Contact LIMIT 1];

        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                AccountId = acc.Id,
                OwnerId = UserInfo.getUserId(),
                StageName = 'Accepted',
                CloseDate = Date.today().addDays(30),
                Asset_HW_Contract__c = contract.Id,
                Business_Group__c = null,
                SBQQ__RenewedContract__c = contract.Id,
                Primary_Contact__c = contact.Id
            );
            opportunities.add(opp);
        }

        insert opportunities;

        OpportunityContractAddressHandler oppContract = new OpportunityContractAddressHandler();
        oppContract.processRecords(new Map<Id,Opportunity>(opportunities) , new Map<Id,Opportunity>(opportunities), new List<Opportunity>(), null, null, null);

        for (Opportunity opp : opportunities) {
            System.assertNotEquals(null, opp.City__c, 'City__c should be updated');
            System.assertNotEquals(null, opp.Ship_To_City__c, 'Ship_To_City__c should be updated');
        }
    }

}
