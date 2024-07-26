@isTest
public class LeadConvert_CPUTimeoutTest {

    private final static String LEAD_FIRST_NAME = 'John';
    private final static String LEAD_LAST_NAME = 'Test_Doe';
    private final static String LEAD_COMPANY = 'Testing Inc.';
    private final static String LEAD_EMAIL = 'jdoe@testing.com';
    private final static String LEAD_PHONE = '555-555-55555';
    private final static String LEAD_STREET = '100 Pine St.';
    private final static String LEAD_CITY = 'San Francisco';
    private final static String LEAD_STATE = 'California';
    private final static String LEAD_STATE_CODE = 'CA';
    private final static String LEAD_POSTAL_CODE = '94111';
    private final static String LEAD_COUNTRY = 'United States';
    private final static String LEAD_COUNTRY_CODE = 'US';
    private final static String LEAD_CURRENCY_CODE = 'USD';
    private final static String CREATION_SOURCE_AUDIT = 'Manual';

    @testSetup
    private static void testSetup() {
        Id rtID =
            Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Partner_Application').getRecordTypeId();

        insert new Lead(RecordTypeId = rtId,
                        Lifecycle_Status__c = 'MQL',
                        Business_Group__c = 'Core',
                        FirstName = LEAD_FIRST_NAME,
                        LastName = LEAD_LAST_NAME,
                        Company = LEAD_COMPANY,
                        Email = LEAD_EMAIL,
                        Phone = LEAD_PHONE,
                        Street = LEAD_STREET,
                        City = LEAD_CITY,
                        State = LEAD_STATE,
                        StateCode = LEAD_STATE_CODE,
                        PostalCode = LEAD_POSTAL_CODE,
                        Country = LEAD_COUNTRY,
                        CountryCode = LEAD_COUNTRY_CODE,
                        CurrencyIsoCode = LEAD_CURRENCY_CODE);
    }

    private static Lead getTestLead() {
        Lead leadRecord = [SELECT Id, LastName, Company, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId
                           FROM Lead
                           WHERE LastName = :LEAD_LAST_NAME
                           LIMIT 1];
        return leadRecord;
    }

    private static Account buildAccount() {
        Id rtID =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
        return new Account(RecordTypeId = rtId,
                           Name = LEAD_COMPANY);
    }

    private static Contact buildContact() {
        return new Contact(FirstName = LEAD_FIRST_NAME,
                           LastName = LEAD_LAST_NAME,
                           Email= LEAD_EMAIL,
                           Phone = LEAD_PHONE);
    }

    private static Opportunity buildOpportunity() {
        Id rtID =
            Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        return new Opportunity(RecordTypeId = rtId,
                               Name = 'Test Opp',
                               StageName = 'Prospecting',
                               CloseDate = Date.today(),
                               OwnerId = UserInfo.getUserId());
    }

    private static void convertLead(Id leadId, Id acctId, Id conId, Id oppId) {
        // Convert the lead
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);

        Database.LeadConvertResult lcr;
        try {
           lcr = Database.convertLead(lc);
        } catch (Exception e) {
            System.debug('Failed to convert lead. ' + e.getMessage());
        }

        if (!lcr.isSuccess()) {
            System.debug('Lead conversion failed. ' + lcr.getErrors()[0].getMessage());
        }
    }

    @isTest
    static void testConvertLead() {
        // Create a Lead
        Lead testLead = getTestLead();

        // Test lead conversion
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);

        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());

        // Asserts to check cpu timeout value
        System.debug('Limits.getCpuTime() = ' + Limits.getCpuTime());
        System.debug('Limits.getLimitCpuTime() = ' + Limits.getLimitCpuTime());
        System.assert(Limits.getCpuTime() < Limits.getLimitCpuTime(), 'CPU time is over the limit!');
    }
}