@isTest
public class AccountSelectorTest {
    
    @testSetup
    static void setup() {
        // Insert a test account with all the fields that are used in the AccountSelector logic
        Account acc = new Account(
            Name = 'Test Account',
            Website = 'http://www.test.com',
            D_B_DUNS_Number__c = '123456789',
            BillingCountry = 'United States',
            BillingState = 'California',
            BillingPostalCode = '90001',
            Phone = '1234567890',
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Account' AND DeveloperName='Customer'].Id
        );
        insert acc;
    }
	static testMethod void testFindByAccountName() {
        // Retrieve the test account
        Account testAccount = [SELECT Id, Name, Website, D_B_DUNS_Number__c,BillingCountry,RecordType.DeveloperName FROM Account LIMIT 1];

        // Initialize the inner class
        AccountSelector.AccountSelectorWithoutSharing selector = new AccountSelector.AccountSelectorWithoutSharing();

        // Call the method with the test account record
        List<List<SObject>> searchResults = selector.findByAccountName(testAccount);

        // Assert that a list is returned
        System.assertNotEquals(null, searchResults, 'The search result should not be null.');
        // Since it's a SOSL query in the method, you might want to check the size of the result
        System.assertEquals(1, searchResults.size(), 'Should return one list.');
    }
    
    static testMethod void testFindByAccountId() {
        // Retrieve the test account
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];

        // Initialize the inner class
        AccountSelector.AccountSelectorWithoutSharing selector = new AccountSelector.AccountSelectorWithoutSharing();

        // Call the method with the test account ID
        Account accountById = selector.findByAccountId(testAccount.Id);

        // Assert that an account is returned with the correct ID
        System.assertEquals(testAccount.Id, accountById.Id, 'The account ID should match the test account ID.');
    }
    
    static testMethod void testFindMatch() {
        // Create a test account
        Account acc = new Account(
            Name = 'Unique Test Account',
            D_B_DUNS_Number__c = '987654321',
            BillingCountry = 'United States',
            BillingState = 'New York',
            BillingPostalCode = '10001',
            Phone = '0987654321',
            Website = 'http://www.unique-test.com'
        );
        insert acc;
        
        Account testAcc = [SELECT Id, Name, Website, D_B_DUNS_Number__c, BillingCountry, BillingState, BillingPostalCode, Phone FROM Account LIMIT 1];

        // Call the static method of AccountSelector
 		List<Account> accounts = AccountSelector.findMatch(testAcc);  
        
        System.assertEquals(1, accounts.size(), 'There should be one account found that matches the criteria.');
        System.assertEquals(testAcc.Id, accounts[0].Id, 'The account ID should match the test account.');
    }   
}