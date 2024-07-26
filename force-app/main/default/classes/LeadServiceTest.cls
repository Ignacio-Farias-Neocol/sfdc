@isTest
public class LeadServiceTest {

    private final static String LEAD_FIRST_NAME = 'John';
    private final static String LEAD_LAST_NAME = 'Doe';
    private final static String LEAD_COMPANY = 'Test Inc';
    private final static String LEAD_EMAIL = 'jdoe@test.com';
    private final static String LEAD_PHONE = '555-555-55555';
    private final static String CREATION_SOURCE_AUDIT = 'Manual';

    @testSetup
    private static void testSetup() {
        insert new Lead(FirstName = LEAD_FIRST_NAME, LastName = LEAD_LAST_NAME, Company = LEAD_COMPANY, Email = LEAD_EMAIL, Phone = LEAD_PHONE);
    }

    private static Lead getTestLead() {
        Lead leadRecord = [SELECT Id, LastName, Company, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId FROM Lead WHERE LastName = :LEAD_LAST_NAME LIMIT 1];
        return leadRecord;
    }

    private static Account buildAccount() {
        return new Account(Name = LEAD_COMPANY, Creation_Source_Audit__c = CREATION_SOURCE_AUDIT);
    }

    private static Contact buildContact() {
        return new Contact(FirstName = LEAD_FIRST_NAME, LastName = LEAD_LAST_NAME, Email= LEAD_EMAIL, Phone = LEAD_PHONE);
    }

    private static Opportunity buildOpportunity() {
        return new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today(), OwnerId = UserInfo.getUserId());
    }

    @isTest
    static void testConvertLead() {
        // Create a Lead
        Lead testLead = getTestLead();

        // Create Account, Contact, and Opportunity for the conversion
        Account acc = buildAccount();
        Contact con = buildContact();
        Opportunity opp = buildOpportunity();

        // Test lead conversion method
        Test.startTest();
        LeadService.ConversionResult result = LeadService.convertLead(testLead.Id, acc,acc, con, opp, 'false');
        Test.stopTest();

        // Asserts to verify the conversion
        Assert.isNotNull(result, 'ConversionResult is null');
        Assert.isNotNull(result.accountId, 'Conversion Result Account Id is null');
        Assert.isNotNull(result.contactId, 'Conversion Result Contact Id is null');
        Assert.isNotNull(result.opportunityId, 'Conversion Result Opportunity Id is null');

        testLead = getTestLead();
        Assert.areEqual(result.accountId, testLead.ConvertedAccountId, 'Converted Account Id is incorrect');
        Assert.areEqual(result.contactId, testLead.ConvertedContactId, 'Converted Contact Id is incorrect');
        Assert.areEqual(result.opportunityId, testLead.ConvertedOpportunityId, 'Converted Opportunity Id is incorrect');
    }

    @isTest
    private static void testConvertLead_ExistingRecords() {
        // Test data setup
        Lead testLead = getTestLead();

        // Create Account, Contact, and Opportunity for the conversion
        Account acc = buildAccount();
        insert acc;

        Contact con = buildContact();
        con.email += '.test';
        con.AccountId = acc.Id;
        insert con;

        Opportunity opp = TestDataFactory.createEmptyOpportunity(acc);
        insert opp;

        Assert.isNotNull(acc.Id, 'Account Id is null');
        Assert.isNotNull(con.Id, 'Contact Id is null');
        Assert.isNotNull(opp.Id, 'Opportunity Id is null');

        // Actual test
        Test.startTest();
        LeadService.ConversionResult result = LeadService.convertLead(testLead.Id, acc,acc, con, opp, 'false');
        Test.stopTest();

        // Asserts
        //Assert.areEqual(acc.Id, result.accountId, 'Account Ids do not match');
        Assert.areEqual(con.Id, result.contactId, 'Contact Ids do not match');
        Assert.areEqual(opp.Id, result.opportunityId, 'Opportunity Ids do not match');
        Assert.areEqual(opp.Name, result.opportunityName, 'Opportunity Names do not match');
    }

    @isTest
    private static void testConvertLead_ExistingAccount() {
        // Test data setup
        Lead testLead = getTestLead();

        // Create Account, Contact, and Opportunity for the conversion
        Account acc = buildAccount();
        insert acc;

        Contact con = buildContact();
        Opportunity opp = buildOpportunity();

        // Actual test
        Test.startTest();
        LeadService.ConversionResult result = LeadService.convertLead(testLead.Id, acc,acc, con, opp, 'false');
        Test.stopTest();

        // Asserts
        //Assert.areEqual(acc.Id, result.accountId, 'Account Ids do not match');
        Assert.isNotNull(result.contactId, 'Contact Ids do not match');
        Assert.isNotNull(result.opportunityId, 'Opportunity Ids do not match');
        Assert.areEqual(opp.Name, result.opportunityName, 'Opportunity Names do not match');
    }

    @isTest
    private static void testConvertLead_ExistingContactRelationship() {
        // Test data setup
        Lead testLead = getTestLead();

        // Create Account, Contact, and Opportunity for the conversion
        Account acc = buildAccount();
        Account accountForContact = new Account(Name = 'Contact Account');
        insert new List<Account>{ acc, accountForContact };

        Contact con = buildContact();
        con.email += '.test';
        con.AccountId = accountForContact.Id;
        insert con;

        Opportunity opp = buildOpportunity();

        // Actual test
        Test.startTest();
        LeadService.ConversionResult result = LeadService.convertLead(testLead.Id, acc,acc, con, opp, 'false');
        Test.stopTest();

        // Asserts
        con = [SELECT Id, AccountId FROM Contact WHERE Id = :con.Id LIMIT 1];
        Assert.areEqual(accountForContact.Id, con.AccountId, 'Contact Account Id is changed incorrectly');

        Map<Id, AccountContactRelation> acrMapByAccountId = new Map<Id, AccountContactRelation>();
        for(AccountContactRelation acr : [SELECT AccountId FROM AccountContactRelation WHERE ContactId = :con.Id]) {
            acrMapByAccountId.put(acr.AccountId, acr);
        }
        Assert.areEqual(2, acrMapByAccountId.keySet().size(), 'Account Contact Relation number mismatch');
        //Assert.isNotNull(acrMapByAccountId.get(acc.Id), 'Converted Account relationship not created');
    }

    @isTest
    static void testConvertLead_DoNotCreateOpportunity() {
        // Create a Lead
        Lead testLead = getTestLead();

        // Create Account, Contact, and Opportunity for the conversion
        Account acc = buildAccount();
        Contact con = buildContact();

        // Test lead conversion method
        Test.startTest();
        LeadService.ConversionResult result = LeadService.convertLead(testLead.Id, acc, acc, con, NULL, 'true' /*donotCreateOpp*/);
        Test.stopTest();

        // Asserts to verify the conversion
        Assert.isNull(result.opportunityId, 'Conversion Result Opportunity Id is not null');
        Assert.isNull(result.opportunityName, 'Conversion Result Opportunity Name is not null');

        testLead = getTestLead();
        Assert.isNull(testLead.ConvertedOpportunityId, 'Converted Opportunity Id is not null');
    }
}