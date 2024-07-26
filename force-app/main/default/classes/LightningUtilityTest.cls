@isTest
private class LightningUtilityTest {

    static testMethod void myUnitTest() {
        LightningUtility.KeyValueResults r = LightningUtility.retrievePicklistValues('Account', 'Type');
        System.Debug(r.errorMsg);
        r.results.sort();
        //LightningUtility.KeyValue r3 = new LightningUtility.KeyValue('key', 'value');
        
        LightningUtility.retrieveRecordTypes('Account');
        //List<RecordType> recordTypes = [Select ID, SObjectType, Name From RecordType LIMIT 1];
        
        List<Account> testAccounts = new List<Account>{
            new Account(Name = 'Test Compucom Account', Website = 'https://www.yahoo.com', AnnualRevenue = 1000, NumberOfEmployees = 1000, BillingState = 'Colorado', BillingPostalCode = '80302', BillingCountry = 'United States'),
            new Account(Name = 'Best Compucom Account 2', Website = 'https://www.yahoo.com', AnnualRevenue = 1000, NumberOfEmployees = 1000, BillingState = 'Colorado', BillingPostalCode = '80302', BillingCountry = 'United States')
        };
        insert testAccounts;
        
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', Birthdate = System.Today(), AccountId = testAccounts[0].Id, MailingCity = 'Denver', MailingState = 'Colorado', Phone='(555) 555-5555', Email='123@123.com', MailingCountry = 'United States');
        insert testContact;
        
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = 'Accepted', CloseDate = System.Today(), TotalOpportunityQuantity = 100, Probability = 0.1, AccountId = testAccounts[0].Id);
        insert testOpportunity;
        
        LightningUtility.SearchEntityInfo entity = new LightningUtility.SearchEntityInfo();
        entity.sObjectName = 'Account';
        entity.sObjectIcon = 'standard:account';
        entity.queryLimit = '10';
        List<LightningUtility.SearchEntityInfo> searchEntities = new List<LightningUtility.SearchEntityInfo>{entity};
        for (LightningUtility.SearchEntityInfo sei : searchEntities) {
            System.Debug(sei.FieldSetAPIName);
            System.Debug(sei.sObjectIcon);
        }
        LightningUtility.SObjectHierarchyResults r3 = LightningUtility.retrieveRecordByID(testAccounts[0].Id, searchEntities);
        System.Debug('*** r3.errorMsg ' + r3.errorMsg);
        r3.setRecords(testAccounts);
        
        entity = new LightningUtility.SearchEntityInfo();
        entity.sObjectName = 'Account';
        entity.sObjectIcon = 'standard:account';
        entity.queryLimit = 'xxx';
        searchEntities = new List<LightningUtility.SearchEntityInfo>{entity};
        LightningUtility.SearchResults sr = LightningUtility.searchRecords('Test', searchEntities);
        
        entity = new LightningUtility.SearchEntityInfo();
        entity.sObjectName = 'Account';
        entity.sObjectIcon = 'standard:account';
        entity.queryLimit = '200';
        entity.displayFields = new List<String> {'Website', 'Name', 'AnnualRevenue', 'NumberOfEmployees', 'CreatedById', 'LastModifiedById'};
        entity.lookupFilter = 'BillingState = \'CO\'';
        entity.displayActions = new List<LightningUtility.ActionDefinition>{
            new LightningUtility.ActionDefinition('View', 'View', '|'), 
            new LightningUtility.ActionDefinition('Edit', 'Edit', '|'), 
            new LightningUtility.ActionDefinition('Delete', 'Delete', '|')
        };
        searchEntities = new List<LightningUtility.SearchEntityInfo>{entity};
        sr = LightningUtility.searchRecords('Test', searchEntities);
        for (LightningUtility.SObjectHierarchyResults hr : sr.results) {
            for (LightningUtility.SObjectInfo so : hr.results) {
                System.Debug(so.checked);
                System.Debug(so.checkable);
                System.Debug(so.focused);
                System.Debug(so.focusedBranch);
            }

            List<LightningUtility.AuraGridColumn> acols = hr.getAuraGridColumnDefinition();
            List<Map<String, Object>> arecords = hr.getAuraGridData();
            hr.adjustAuraGridColumnWidth();
            for (LightningUtility.AuraGridColumn agc : acols) {
                System.Debug('*** ' + agc.cellAttributes);
            }
            for (Map<String, Object> agd : arecords) {
                System.Debug('*** ' + agd);
            }
        }

        entity = new LightningUtility.SearchEntityInfo();
        entity.sObjectName = 'Contact';
        entity.sObjectIcon = 'standard:contact';
        entity.queryLimit = '200';
        entity.displayFields = new List<String> {'MailingCity', 'AccountId', 'HasOptedOutOfEmail', 'Email', 'Phone'};
        entity.lookupFilter = 'MailingState = \'CO\'';
        searchEntities = new List<LightningUtility.SearchEntityInfo>{entity};
        sr = LightningUtility.searchRecords(null, searchEntities);
        
        entity = new LightningUtility.SearchEntityInfo();
        entity.sObjectName = 'Opportunity';
        entity.sObjectIcon = 'standard:opportunity';
        entity.queryLimit = '200';
        entity.displayFields = new List<String> {'TotalOpportunityQuantity', 'Probability', 'CloseDate'};
        entity.lookupFilter = 'Account.BillingState = \'CO\'';
        searchEntities = new List<LightningUtility.SearchEntityInfo>{entity};
        sr = LightningUtility.searchRecords('te', searchEntities);
        System.Debug('*** sr.errorMsg ' + sr.errorMsg);

        LightningUtility.SaveResult r1 = new LightningUtility.SaveResult();
        System.Debug(r1.result);
        System.Debug(r1.errorMsg);
        
        LightningUtility.SObjectHierarchyResults r4 = new LightningUtility.SObjectHierarchyResults();
        LightningUtility.ColumnDefinition column = new LightningUtility.ColumnDefinition();
        Set<String> acctFields = LightningUtility.getCustomFieldNames(Account.getSObjectType(), false);
        acctFields.add('Name');
        LightningUtility.buildObjectQuery(acctFields, 'Owner.FirstName', 'BillingState=\'CO\'', 'Account');

        LightningUtility.transverse(null, '');
        LightningUtility.auraGridAttributes aga = new LightningUtility.auraGridAttributes();
        System.Debug(aga.maximumFractionDigits);
        System.Debug(aga.maximumSignificantDigits);
        System.Debug(aga.minimumSignificantDigits);
    }
}