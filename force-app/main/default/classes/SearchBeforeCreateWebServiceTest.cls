@isTest
private class SearchBeforeCreateWebServiceTest {

    static RestRequest getRequest(String requestString) {
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/SearchBeforeCreateWebService/account';
        request.httpMethod = 'POST';
        request.requestBody= Blob.valueOf(requestString);
        return request;
    }

    static MockHttpResponseGenerator mockedHttpResponse = MockHttpResponseGenerator.getDnbSearchApiResponse();

    @isTest
    static void testAccount() {
        Test.setMock(HttpCalloutMock.class, mockedHttpResponse);

        RestContext.request = getRequest('{"account":{"name":"ACME Inc.","type":"Customer","BillingCountryCode":"US"},"dryrun":false,"enrich":false}');
        RestContext.response = new RestResponse();

        // User Case: No DnB Enrichment
        Test.startTest();
        SearchBeforeCreateWebService.Response result = SearchBeforeCreateWebService.createAccount();
        Test.stopTest();

        // Verify the result
        System.assertEquals(true, result.success);
        System.assert(result.id != null);
        System.assert(result.errors.isEmpty());
    }

    @isTest
    static void testAccount_DnbEnriched() {
        Test.setMock(HttpCalloutMock.class, mockedHttpResponse);

        RestContext.request = getRequest('{"account":{"name":"Test Name","D_B_DUNS_Number__c":"12345","type":"Customer","BillingCountryCode":"US"}}');
        RestContext.response = new RestResponse();

        // User Case: With DnB Enrichment
        Test.startTest();
        SearchBeforeCreateWebService.Response result = SearchBeforeCreateWebService.createAccount();
        Test.stopTest();

        // Verify the result
        System.assertEquals(true, result.success);
        System.assert(result.id != null);
        System.assert(result.errors.isEmpty());
    }

    @isTest
    static void testAccount_DnbEnriched_NoDUNS_Number() {
        Test.setMock(HttpCalloutMock.class, mockedHttpResponse);

        RestContext.request = getRequest('{"account":{"name":"Test Name","type":"Customer","BillingCountryCode":"US"},"dryrun":false,"enrich":true}');
        RestContext.response = new RestResponse();

        // User Case: With DnB Enrichment
        Test.startTest();
        SearchBeforeCreateWebService.Response result = SearchBeforeCreateWebService.createAccount();
        Test.stopTest();

        // Verify the result
        System.assertEquals(true, result.success);
        System.assert(result.id != null);
        System.assert(result.errors.isEmpty());
    }

    @isTest
    static void testAccount_DnbEnriched_ExistingAcct_SameType() {
        Test.setMock(HttpCalloutMock.class, mockedHttpResponse);

        RestContext.request = getRequest('{"account":{"name":"Test Name","D_B_DUNS_Number__c":"12345","type":"Customer","BillingCountryCode":"US"},"dryrun":false,"enrich":true}');
        RestContext.response = new RestResponse();

        Account existingAcct = new Account(Name = 'Test Name', Type = 'Customer', D_B_DUNS_Number__c = '12345');
        insert existingAcct;

        // User Case: With DnB Enrichment & existing account with the same Type
        Test.startTest();
        SearchBeforeCreateWebService.Response result = SearchBeforeCreateWebService.createAccount();
        Test.stopTest();

        // Verify the result
        System.assertEquals(true, result.success);
        System.assert(result.id != null);
        System.assertEquals(existingAcct.Id, result.Id, 'New account should not be inserted');
    }

    @isTest
    static void testAccount_DnbEnriched_ExistingAcct_DifferentType() {
        Test.setMock(HttpCalloutMock.class, mockedHttpResponse);

        RestContext.request = getRequest('{"account":{"name":"Test Name","D_B_DUNS_Number__c":"12345","type":"Customer","BillingCountryCode":"US"},"dryrun":false,"enrich":true}');
        RestContext.response = new RestResponse();

        Account existingAcct = new Account(Name = 'Test Name', Type = 'Partner - MSP', D_B_DUNS_Number__c = '12345');
        insert existingAcct;

        // User Case: With DnB Enrichment & existing account with different Type
        Test.startTest();
        SearchBeforeCreateWebService.Response result = SearchBeforeCreateWebService.createAccount();
        Test.stopTest();

        // Verify the result
        System.assertEquals(true, result.success);
        System.assert(result.id != null);
        System.assertNotEquals(existingAcct.Id, result.Id, 'New account should be inserted');
    }

    @isTest
    static void testAccount_DnbEnriched_ExistingAcct_DifferentTypeWithParentId() {
        final String DUNS_NUMBER = '12345';
        final String ACCOUNT_NAME = 'Test Name';
        final String jsonBody = '{' +
        '"responseCode": 200,' +
        '"matchCandidates": [{' +
            '"organization":' +
                '{"duns": "' + DUNS_NUMBER + '",' +
                '"primaryName": "' + ACCOUNT_NAME + '",' +
                '"telephone":[{ "telephoneNumber":"6505550000","isUnreachable":false }],' +
                '"corporateLinkage":' +
                    '{"familytreeRolesPlayed":[' +
                        ' {"description":"Parent / Headquarters","dnbCode":"9141"}' +
                    ']}' +
                '},' +
            '"matchQualityInformation":' +
                '{"confidenceCode": ' + SearchBeforeCreateWebService.CONFIDENCE_THRESOLD + '}' +
            '}' +
        '],' +
        '"transactionDetail": {"transactionID": "0dae58047eafe4568", "transactionTimestamp": "2019-09-18T16:22:32.079Z", "inLanguage": "en-US", "serviceVersion": "1"},' +
        '"searchCandidates": [' +
            '{"organization": {"duns": "' + DUNS_NUMBER + '", "primaryName": "' + ACCOUNT_NAME + '"}}' +
        ']}';
        mockedHttpResponse.mockedHttpResponse.setBody(jsonBody);

        Test.setMock(HttpCalloutMock.class, mockedHttpResponse);

        RestContext.request = getRequest('{"account":{"name":"Test Name","D_B_DUNS_Number__c":"' + DUNS_NUMBER + '","type":"Customer","BillingCountryCode":"US"},"dryrun":false,"enrich":true}');
        RestContext.response = new RestResponse();

        Account existingParentAcct = new Account(Name = 'Test Parent Name', Type = 'Aggregate');
        insert existingParentAcct;

        Account existingAcct = new Account(Name = ACCOUNT_NAME, Type = 'Partner - MSP', D_B_DUNS_Number__c = DUNS_NUMBER, ParentId = existingParentAcct.Id);
        insert existingAcct;

        // User Case: With DnB Enrichment & existing account with different Type
        Test.startTest();
        SearchBeforeCreateWebService.Response result = SearchBeforeCreateWebService.createAccount();
        Test.stopTest();

        // Verify the result
        System.assertEquals(true, result.success);
        System.assert(result.id != null);
        System.assertNotEquals(existingAcct.Id, result.Id, 'New account should be inserted');

        Account insertedAccount = [SELECT Id, ParentId FROM Account WHERE Id = :result.id LIMIT 1];
        System.assertEquals(existingParentAcct.Id, insertedAccount.ParentId, 'Failed to parent inserted account');
    }

    @isTest
    static void testAccount_DnbEnriched_ExistingAcct_DifferentTypeWithParentId_DryRun() {
        Test.setMock(HttpCalloutMock.class, mockedHttpResponse);

        RestContext.request = getRequest('{"account":{"name":"Test Name","D_B_DUNS_Number__c":"12345","type":"Customer","BillingCountryCode":"US"},"dryrun":true,"enrich":true}');
        RestContext.response = new RestResponse();

        Account existingParentAcct = new Account(Name = 'Test Parent Name', Type = 'Aggregate');
        insert existingParentAcct;

        Account existingAcct = new Account(Name = 'Test Name', Type = 'Partner - MSP', D_B_DUNS_Number__c = '12345', ParentId = existingParentAcct.Id);
        insert existingAcct;

        // User Case: With DnB Enrichment & existing account with different Type
        Test.startTest();
        SearchBeforeCreateWebService.Response result = SearchBeforeCreateWebService.createAccount();
        Test.stopTest();

        // Verify the result
        System.assertEquals(true, result.success);
        System.assert(result.id != null);
    }

    @isTest
    static void testAccount_Negative() {
        Test.setMock(HttpCalloutMock.class, mockedHttpResponse);

        RestContext.request = getRequest('{"account":{"name":"ACME Inc.","type":"Customer"},"dryrun":true,"enrich":false}');
        RestContext.response = new RestResponse();

        // User Case: missing required information
        Test.startTest();
        SearchBeforeCreateWebService.Response result = SearchBeforeCreateWebService.createAccount();
        Test.stopTest();

        // Verify the result
        System.assertEquals(false, result.success);
        System.assert(!result.errors.isEmpty());
    }
}