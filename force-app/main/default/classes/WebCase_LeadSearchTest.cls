@IsTest
private class WebCase_LeadSearchTest {

    @IsTest
    static void testSearchLeadsBySuppliedEmail() {
        // Create a test Lead
        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@test.com',
            CountryCode = 'IN   ',
            State_Code__c = 'CA',
            PostalCode ='79876',
            CurrencyIsoCode = 'USD',
            Company = 'Dogster Inc'
        );
        insert testLead;

        // Call the searchLeadsBySuppliedEmail method with the test Lead's email
        List<Lead> searchResults = WebCase_LeadSearch.searchLeadsBySuppliedEmail('johndoe@test.com');

        // Verify that the search returned the expected Lead
        System.assertEquals(1, searchResults.size(), 'Search should have returned one Lead');
        System.assertEquals(testLead.Id, searchResults[0].Id, 'Search should have returned the test Lead');
    }

    @IsTest
    static void testSearchLeadsBySuppliedEmailContactExists() {
        // Create a test Contact
        Contact testContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Email = 'janedoe@test.com'
        );
        insert testContact;

        // Call the searchLeadsBySuppliedEmail method with the test Contact's email
        List<Lead> searchResults = WebCase_LeadSearch.searchLeadsBySuppliedEmail('janedoe@test.com');

        // Verify that the search returned null
        System.assertEquals(null, searchResults, 'Search should have returned null when a matching Contact exists');
    }
}