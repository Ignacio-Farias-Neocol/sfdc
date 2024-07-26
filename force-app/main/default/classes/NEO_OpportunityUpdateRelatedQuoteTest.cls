/**
 * @description       : 
 * @author            : Ignacio F.
 * @group             : 
 * @last modified on  : 07-16-2024
 * @last modified by  : Ignacio F.
**/
@isTest
public class NEO_OpportunityUpdateRelatedQuoteTest {
    @testSetup
    static void setupTestData() {

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
                Shipping_Country_ISO_Code__c = 'US'
            ));
        }
        insert opps;

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        for (Opportunity opp : opps) {
            quotes.add(new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opp.Id,
                ApprovalStatus__c = 'Approved',
                SBQQ__Status__c = 'Draft',
                SBQQ__Type__c = 'Re-Quote'
            ));
        }
        insert quotes;
      
    }

    @isTest
    static void testProcessRecordsPositiveScenario() {
        // Query the Opportunities to pass to the handler
        List<Opportunity> oppList = [SELECT Id, Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.ApprovalStatus__c, Auto_Renewal_Eligible_Core__c FROM Opportunity];

        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c];

        List<Opportunity> oppstoUpdate = new List<Opportunity>();
        for (Integer i = 0; i < oppList.size(); i++) {
            oppList[i].Auto_Renewal_Status_Core__c = 'Included - Manually';
            oppList[i].SBQQ__PrimaryQuote__c = quotes[i].Id;
            oppList[i].Bill_To_Account__c = null;
            oppstoUpdate.add(oppList[i]);
        }
        update oppstoUpdate;

        oppList = [SELECT Id, Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.ApprovalStatus__c, Auto_Renewal_Eligible_Core__c FROM Opportunity];
        for (Opportunity opp : oppList) {
            System.assertNotEquals(null, opp.SBQQ__PrimaryQuote__c, 'Quote should not be null');
            System.assertEquals(true, opp.Auto_Renewal_Eligible_Core__c, 'Auto Renewal should be true');
            System.assertEquals('Approved', opp.SBQQ__PrimaryQuote__r.ApprovalStatus__c, 'Quote Approval Status should beApproved');
        }


        List<SBQQ__Quote__c> updatedQuotes = [SELECT Id, AR_Recalc__c, ApprovalStatus__c, SBQQ__Status__c FROM SBQQ__Quote__c WHERE AR_Recalc__c = true];
        System.assertEquals(5, updatedQuotes.size(), 'Five quotes should be updated'); 

        for (SBQQ__Quote__c quote : updatedQuotes) {
            System.assertEquals('Approved', quote.ApprovalStatus__c, 'Quote should be approved');
            System.assertEquals('Customer Accepted', quote.SBQQ__Status__c, 'Quote status should be Customer Accepted');
        }
    }

    @isTest
    static void testProcessRecordsNegativeScenario() {
        // Create Opportunities with conditions that should not trigger updates
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            opps.add(new Opportunity(
                Name = 'Negative Test Opportunity ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                SBQQ__PrimaryQuote__c = null, // No Primary Quote
                Auto_Renewal_Status_Core__c = 'Included - Manually', // Not eligible for auto-renewal
                AccountId = acc.Id,
                Primary_Contact__c = con.Id,
                LeadSource = 'Blog'
            ));
        }
        insert opps;

        // Create a new instance of the handler and call the method
        UpdateRelatedOpportunity handler = new UpdateRelatedOpportunity();
        handler.processRecords(new Map<Id, SObject>(), new Map<Id, SObject>(), opps, null, null, null);

        // Verify no Quotes were updated
        List<SBQQ__Quote__c> updatedQuotes = [SELECT Id, AR_Recalc__c, ApprovalStatus__c, SBQQ__Status__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN: opps];
        System.assertEquals(0, updatedQuotes.size(), 'No quotes should be updated');
    }

    @isTest
    public static void testMeasureExecutionTime() {
        // Query the Opportunities to pass to the handler
        List<Opportunity> oppList = [SELECT Id, Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.ApprovalStatus__c, Auto_Renewal_Eligible_Core__c FROM Opportunity];

        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c];

        List<Opportunity> oppstoUpdate = new List<Opportunity>();
        for (Integer i = 0; i < oppList.size(); i++) {
            oppList[i].Auto_Renewal_Status_Core__c = 'Included - Manually';
            oppList[i].SBQQ__PrimaryQuote__c = quotes[i].Id;
            oppList[i].Bill_To_Account__c = null;
            oppstoUpdate.add(oppList[i]);
        }
                
        // Measure execution time
        Datetime startTime = Datetime.now();
    
        Test.startTest();
        update oppstoUpdate;
        Test.stopTest();
        
        Datetime endTime = Datetime.now();
        Long executionTimeInMillis = endTime.getTime() - startTime.getTime();
    
        System.debug('Execution time: ' + executionTimeInMillis + ' ms');

        oppList = [SELECT Id, Name, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.ApprovalStatus__c, Auto_Renewal_Eligible_Core__c FROM Opportunity];
        for (Opportunity opp : oppList) {
            System.assertNotEquals(null, opp.SBQQ__PrimaryQuote__c, 'Quote should not be null');
            System.assertEquals(true, opp.Auto_Renewal_Eligible_Core__c, 'Auto Renewal should be true');
            System.assertEquals('Approved', opp.SBQQ__PrimaryQuote__r.ApprovalStatus__c, 'Quote Approval Status should beApproved');
        }

        List<SBQQ__Quote__c> updatedQuotes = [SELECT Id, AR_Recalc__c, ApprovalStatus__c, SBQQ__Status__c FROM SBQQ__Quote__c WHERE AR_Recalc__c = true];
        System.assertEquals(5, updatedQuotes.size(), 'Five quotes should be updated'); 

        for (SBQQ__Quote__c quote : updatedQuotes) {
            System.assertEquals('Approved', quote.ApprovalStatus__c, 'Quote should be approved');
            System.assertEquals('Customer Accepted', quote.SBQQ__Status__c, 'Quote status should be Customer Accepted');
        }
    }
}