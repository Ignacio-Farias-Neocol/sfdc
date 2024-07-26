@isTest
public with sharing class NEO_OpportunityUpdateRelatedAccountTest {
    
    // @testSetup
    // static void setupTestData(){

    //     Territory2 territory = [Select Id, Theater2__c from Territory2 Where Theater2__c = 'AMERICAS' Limit 1 ];     
    //     Account testAccount = NEO_TestDataFactory.getPartnerAccounts(1)[0];
    //     insert testAccount;

    //     ObjectTerritory2Association  objTerr = new ObjectTerritory2Association(ObjectId = testAccount.Id, Territory2Id = territory.Id, AssociationCause =' Territory2Manual');
    //     insert objTerr;

    //     testAccount.Territory_ID__c = territory.Id;
    //     update testAccount;

    //     // Account testAccount = NEO_TestDataFactory.createAccounts(1, true)[0];
    //     Contact testContact = NEO_TestDataFactory.createContacts(1, true, new Map<Schema.SObjectField, Object>{ Contact.AccountId => testAccount.Id })[0];
    //     Hot_List__c testHotList = NEO_TestDataFactory.createHotLists(1, true, new Map<Schema.SObjectField, Object>{ Hot_List__c.Contact__c => testContact.Id })[0];
    //     Opportunity testOpportunity = NEO_TestDataFactory.createOpportunities(1, true, new Map<Schema.SObjectField, Object>{ Opportunity.AccountId => testAccount.Id, Opportunity.Hot_List__c => testHotList.Id, Opportunity.Primary_Contact__c => testContact.Id, Opportunity.LeadSource => 'Web', Opportunity.Bill_To_Account__c => testAccount.Id, Opportunity.Street__c => '123 Billing St', Opportunity.City__c => 'Billing City', Opportunity.Country__c => 'United States', Opportunity.State__c => 'Missouri', Opportunity.Zip_Postal_Code__c => '1234', Opportunity.Country_ISO_Code__c => 'US', Opportunity.Ship_To_Street__c => '123 Shipping St', Opportunity.Ship_To_City__c => 'Shipping City', Opportunity.Ship_To_Country__c => 'United States', Opportunity.Ship_To_State__c => 'Missouri', Opportunity.Ship_To_Zip_Postal_Code__c => '5432', Opportunity.Shipping_Country_ISO_Code__c => 'US' })[0];
    //     SBQQ__Quote__c testQuote = NEO_TestDataFactory.createQuotes(1, true, new Map<Schema.SObjectField, Object>{ SBQQ__Quote__c.SBQQ__Opportunity2__c => testOpportunity.Id, SBQQ__Quote__c.ApprovalStatus__c => 'Approved', SBQQ__Quote__c.SBQQ__Status__c => 'Draft', SBQQ__Quote__c.SBQQ__Type__c => 'Re-Quote' })[0];
    // }

    @testSetup
    static void setupTestData() {

        TriggerHandler.bypass('NEO_OpportunityUpdateRelatedAccount');

        Territory2 territory = [Select Id, Theater2__c from Territory2 Where Theater2__c = 'AMERICAS' Limit 1 ];     

        NEO_TestDataFactory.createCountries(1, true, new Map<Schema.SObjectField, Object>{ Country__c.Name => 'Canada', Country__c.Country_ISO__c => 'CA' });
        NEO_TestDataFactory.createStates(1, true, new Map<Schema.SObjectField, Object>{ State__c.Name => 'Ontario', State__c.State_ISO__c => 'ON' });

        Account testAccount = new Account(
            Name = 'Test Account',
            BillingStreet = 'Teston Road',
            BillingCity = 'Vaughan',
            BillingState = 'Ontario',
            BillingStateCode = 'ON',
            BillingCountry = 'Canada',
            BillingCountryCode = 'CA',
            BillingPostalCode = 'L4H0L7',
            Type = 'Customer',
            Terr_Theater__c = 'AMERICAS',
            Is_Unit_Test__c = true,
            Territory__c = 'ONTARIO - TERRITORY',
            Terr_Region__c = 'CANADA - REGION',
            recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId(),
            Bill_To_Email__c = 'test@example.com',
            Bill_To_Contact__c = '+59896969696'
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
            CurrencyIsoCode = 'USD',
            MailingCountryCode = 'US'
        );
        insert contact;

        Hot_List__c testHotList = NEO_TestDataFactory.createHotLists(1, true, new Map<Schema.SObjectField, Object>{ Hot_List__c.Contact__c => contact.Id })[0];

        List<Opportunity> opps = new List<Opportunity>();

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Accepted',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            Primary_Contact__c = contact.Id,
            Shipping_Contact__c = contact.Id,
            // Bill_To_Account__c = testAccount.Id,
            Street__c = '123 Billing St',
            City__c = 'Billing City',
            Country__c = 'United States',
            State__c = 'Missouri',
            Zip_Postal_Code__c = '12345',
            Country_ISO_Code__c = 'US',
            Ship_To_Street__c = '123 Shipping St',
            Ship_To_City__c = 'Shipping City',
            Ship_To_Country__c = 'United States',
            Ship_To_State__c = 'Missouri',
            Ship_To_Zip_Postal_Code__c = '54321',
            Shipping_Country_ISO_Code__c = 'US',
            LeadSource = 'Web',
            Type = 'De-book Re-book',
            Hot_List__c = testHotList.Id
        );
        insert testOpportunity;


        // Create Standard Price Book
        Pricebook2 standardPricebook = NEO_TestDataFactory.createStandardPricebook();
        
        // Create Product
        Product2 usageProduct = NEO_TestDataFactory.createProducts('Test Usage Product', 1, 'Usage', 'Annual')[0];
        
        // Create Pricebook Entry for Product
        Map<Id, PricebookEntry> testPBEs = NEO_TestDataFactory.createPricebookEntries(new List<Product2>{ usageProduct }, false, 100.00, 'USD', standardPricebook);

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = testOpportunity.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Re-Quote',
            SBQQ__Primary__c = true,
            SBQQ__PriceBook__c = standardPricebook.Id
        );
        insert testQuote;

        // Create Quote Line
        List<SBQQ__QuoteLine__c> testQuoteLines = NEO_TestDataFactory.createQuoteLines(new List<SBQQ__Quote__c>{ testQuote }, new List<Product2>{ usageProduct }, testPBEs, 1);
    }

    @IsTest
    static void updateExportComplianceApprovalTest() {

        Opportunity testOpportunity = [ SELECT Id, AccountId FROM Opportunity LIMIT 1 ];
        Account testAccount = [ SELECT Id, Requires_Export_Compliance_Approval__c FROM Account WHERE Id = :testOpportunity.AccountId ];

        testOpportunity.Export_Compliance_Approved__c = 'Approved';
        update testOpportunity;

        Test.setMock(HttpCalloutMock.class, new RestMock(testAccount.Id));
        testAccount.BillingCountry = 'Andorra';
        testAccount.Industry = 'Government';
        update testAccount;

        Test.startTest();
            testOpportunity.Export_Compliance_Approved__c = null;

            NEO_OpportunityUpdateRelatedAccount.isMethodExecuted = false;
            update testOpportunity;
        Test.stopTest();

        Account updatedAccount = [ SELECT Id, Requires_Export_Compliance_Approval__c FROM Account WHERE Id = :testOpportunity.AccountId ];
        System.assertEquals(true, updatedAccount.Requires_Export_Compliance_Approval__c, 'Requires Export Compliance Approval field should be true');
        System.assertNotEquals(testAccount.Requires_Export_Compliance_Approval__c, updatedAccount.Requires_Export_Compliance_Approval__c, 'Requires Export Compliance Approval field should have changed');
    }

    @IsTest
    static void updateOppClosedNotAmendmentOrRenewal_nullValuesTest() {
        
        Opportunity testOpportunity = [ SELECT Id, AccountId, Hot_List__c, Export_Compliance_Approved__c, Export_Approval_Exempt__c, Account_Name_Check_for_Compliance__c, StageName, SBQQ__RenewedContract__c, SBQQ__AmendedContract__c FROM Opportunity LIMIT 1 ];
        Account testAccount = [ SELECT Id, Partner_Created_Date_MSP__c, User_na__c FROM Account WHERE Id = :testOpportunity.AccountId ];
        SBQQ__Quote__c testQuote = [ SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :testOpportunity.Id LIMIT 1 ];
        
        // Update Compliance_Status__c on Account
        testAccount.Compliance_Status__c = 'Active';
        update testAccount;
        
        // Approve Quote
        testQuote.ApprovalStatus__c = 'Approved';
        update testQuote;

        Test.startTest();
            Opportunity oldRecord = testOpportunity.clone();
            testOpportunity.StageName = 'Closed Won';
            testOpportunity.PurchaseOrderID__c = 'testPOId';

            // update testOpportunity; // ! Update to Closed Won does not work due to other automation
            new NEO_OpportunityUpdateRelatedAccount().processRecords(
                new Map<Id, SObject>{ testOpportunity.Id => testOpportunity },
                new Map<Id, SObject>{ testOpportunity.Id => oldRecord },
                new List<SObject>{ testOpportunity },
                '',
                'POST',
                'Bulk Save'
            );
        Test.stopTest();

        Account updatedAccount = [ SELECT Id, Partner_Created_Date_MSP__c, User_na__c FROM Account WHERE Id = :testOpportunity.AccountId ];
        System.assertEquals(null, updatedAccount.Partner_Created_Date_MSP__c, 'Partner Created Date (MSP) field should be null');
        System.assertEquals(null, updatedAccount.User_na__c, 'Username field should be null');
    }

    @IsTest
    static void updateOppClosedNotAmendmentOrRenewalTest() {
        
        Opportunity testOpportunity = [ SELECT Id, AccountId, Hot_List__c, Export_Compliance_Approved__c, Export_Approval_Exempt__c, Account_Name_Check_for_Compliance__c, StageName, SBQQ__RenewedContract__c, SBQQ__AmendedContract__c FROM Opportunity LIMIT 1 ];
        Account testAccount = [ SELECT Id, Partner_Created_Date_MSP__c, User_na__c FROM Account WHERE Id = :testOpportunity.AccountId ];
        Hot_List__c testHotList = [ SELECT Id, Trial_Create_Date__c, Trial_Username__c FROM Hot_List__c WHERE Id = :testOpportunity.Hot_List__c ];
        SBQQ__Quote__c testQuote = [ SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :testOpportunity.Id LIMIT 1 ];

        // Update Compliance_Status__c on Account
        testAccount.Compliance_Status__c = 'Active';
        update testAccount;

        // Update Hot List fields
        testHotList.Trial_Create_Date__c = Date.today();
        testHotList.Trial_Username__c = 'testUsername';
        update testHotList;

        // Approve Quote
        testQuote.ApprovalStatus__c = 'Approved';
        update testQuote;

        Test.startTest();
            Opportunity oldRecord = testOpportunity.clone();
            testOpportunity.StageName = 'Closed Won';
            testOpportunity.PurchaseOrderID__c = 'testPOId';

            // update testOpportunity; // ! Update to Closed Won does not work due to other automation
            new NEO_OpportunityUpdateRelatedAccount().processRecords(
                new Map<Id, SObject>{ testOpportunity.Id => testOpportunity },
                new Map<Id, SObject>{ testOpportunity.Id => oldRecord },
                new List<SObject>{ testOpportunity },
                '',
                'POST',
                'Bulk Save'
            );
        Test.stopTest();

        Account updatedAccount = [ SELECT Id, Partner_Created_Date_MSP__c, User_na__c FROM Account WHERE Id = :testOpportunity.AccountId ];
        System.assertEquals(testHotList.Trial_Create_Date__c, updatedAccount.Partner_Created_Date_MSP__c, 'Partner Created Date (MSP) field should be equal to Hot List Trial Create Date');
        System.assertEquals(testHotList.Trial_Username__c, updatedAccount.User_na__c, 'Username field should be equal to Hot List Trial Username');
    }

    private class RestMock implements HttpCalloutMock {

        String recordId = '';
        public RestMock(String recordId) {
            this.recordId = recordId;
        }

        public HTTPResponse respond(HTTPRequest req) {
            String responseJson = '[{"id":" ' + recordId + ' ","success":true,"errors":[]}]';
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(responseJson);
            res.setStatusCode(200);
            return res;
        }
    }
}