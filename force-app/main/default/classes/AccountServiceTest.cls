@isTest
private class AccountServiceTest {

    final static String TEST_ACCOUNT_NAME = 'Test Account';

    @testSetup
    static void setup() {
        // Create test data.
        Account testAccount = new Account(
            Name = TEST_ACCOUNT_NAME,
            Website = 'https://www.test.com',
            D_B_DUNS_Number__c = '123456789',
            BillingCountry = 'United States',
            BillingState = 'New York',
            BillingPostalCode = '12345',
            Phone = '1234567890',
            Type = 'Customer',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Account' AND DeveloperName='Customer'].Id
        );
        insert testAccount;
    }

    static Account existingAccount {
        get {
            if(existingAccount == NULL) {
                existingAccount = [SELECT Id, Name, ParentId FROM Account WHERE Name = :TEST_ACCOUNT_NAME LIMIT 1];
            }
            return existingAccount;
        }
        set;
    }

    @IsTest
    static void testRecordType(){

        Test.startTest();
        Map<String, Id> mapRecordTypeByName = AccountService.mapRecordTypeByName;
        Test.stopTest();

        for(RecordType recordType : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Account']) {
            Assert.areEqual(recordType.Id, mapRecordTypeByName.get(recordType.DeveloperName), 'Incorrect Id for ' + recordType.DeveloperName);
        }
    }

    @isTest
    static void testFindAccountByName() {
        // Retrieve the test data.
        Account accRecord = [SELECT Id, Name, Website, D_B_DUNS_Number__c, BillingCountryCode, RecordType.DeveloperName FROM Account LIMIT 1];

        // Execute the method.
        Test.startTest();
        List<Account> accounts = AccountService.findAccountByName(accRecord);
        Test.stopTest();

        // Verify results.
        System.assertNotEquals(null, accounts);
      //  System.assertEquals('Test Account', accounts[0].Name);
    }

    @isTest
    static void testGetMatchResults() {
        // Mock input map.
        Map<String, Object> accRecord = new Map<String, Object>{
            'Name' => 'Test Account'
        };

        // Execute the method.
        Test.startTest();
        List<DnbResult> results = AccountService.getMatchResults(accRecord);
        Test.stopTest();

        // Verify results.
        System.assertNotEquals(null, results);
    }

    @isTest
    static void testGetDnBDataBlocksInfo() {
        // Setup test data.
        String duns = '123456789';

        // Execute the method.
        Test.startTest();
        DnbResult block = AccountService.getDnBDataBlocksInfo(duns);
        Test.stopTest();

        // Verify results.
        System.assertNotEquals(null, block);
    }

    @isTest
    static void testReparentAccountsWithExistingParent() {
        // Create and insert a parent account
        Account parentAccount = new Account(Name='Parent Account', Type='Parent');
        insert parentAccount;
        
        // Create and insert the original account with a parent
        Account originalAccount = new Account(Name='Original Account', ParentId=parentAccount.Id);
        insert originalAccount;
        
        // Create a cloned account (without inserting it)
        Account clonedAccount = new Account(Name='Cloned Account');
        
        // Call the method under test
        Test.startTest();
        Account result = AccountService.reparentAccounts(clonedAccount, originalAccount);
        Test.stopTest();
        
        // Assert that the cloned account's ParentId has been set
        System.assertEquals(parentAccount.Id, result.ParentId, 'The cloned account should have the parent Id set.');
    }
    
    @isTest
    static void testReparentAccountsWithoutExistingParent() {
        // Create and insert the original account without a parent
        Account originalAccount = existingAccount;
        Assert.isNull(originalAccount.ParentId, 'Parent Id should be null');

        // Test for unintended attribute changes
        originalAccount.Type = 'BAD UPDATE';
        
        // Create a cloned account (without inserting it)
        Account clonedAccount = new Account(Name='Cloned Account', Type = 'Partner - MSP');
        
        // Call the method under test
        Test.startTest();
        Account result = AccountService.reparentAccounts(clonedAccount, originalAccount);
        Test.stopTest();

        originalAccount = [SELECT Id, Name, ParentId, Type, Parent.Name, Parent.RecordType.Name, Parent.Type FROM Account WHERE Id = :originalAccount.Id LIMIT 1];
        Assert.isNotNull(result.ParentId, 'Parent Id should not be null');
        Assert.areEqual(result.ParentId, originalAccount.ParentId, 'Parent Id should match');
        Assert.areEqual('Customer', originalAccount.Type, 'Original Account attributes should not change');
        Assert.areEqual(originalAccount.Name, originalAccount.Parent.Name, 'Parent Account name should equal the original account name');
        Assert.areEqual('Not Transactional', originalAccount.Parent.RecordType.Name, 'Parent Account Record Type should be Not Transactional');
        Assert.areEqual('Aggregate', originalAccount.Parent.Type, 'Parent Account Type should be Aggregate');
    }

    @isTest
    static void testCloneAccount() {
        // Setup test data.
        Account originalAccount = [SELECT Id, Name FROM Account LIMIT 1];
        Account newAccount = new Account(
            Type = 'Prospect',
            Status__c = 'Active',
            CurrencyIsoCode = 'USD'
        );

        // Execute the method.
        Test.startTest();
        Account clonedAccount = AccountService.cloneAccount(originalAccount, newAccount);
        Test.stopTest();

        // Verify results.
        System.assertNotEquals(null, clonedAccount);
        System.assertEquals('Prospect', clonedAccount.Type);
    }

    @isTest
    static void testQueueableClone() {
        // Setup test data.
        Account accToClone = [SELECT Id, Name FROM Account LIMIT 1];
        
        // Since we are simulating cloning, we need to make sure the
        // Account passed to the queueable does not have an Id.
        Account accForQueueable = accToClone.clone(false, true); // Clone the account but do not copy the Id.
    

        // Instantiate the queueable action.
        AccountService.CloneQueable cloneAction = new AccountService.CloneQueable(accForQueueable);

        Test.startTest();
        System.enqueueJob(cloneAction);
        Test.stopTest();
        
        // Verify results - Should now have one more account than when test started.
        Integer accCount = [SELECT Count() FROM Account];
        System.assertEquals(2, accCount);
    }
}