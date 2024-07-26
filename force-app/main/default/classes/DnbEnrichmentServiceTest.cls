@isTest
private class DnbEnrichmentServiceTest {
    static MockHttpResponseGenerator mockedHttpResponse = MockHttpResponseGenerator.getDnbSearchApiResponse();

    @isTest
    static void testGetMatchResults() {

            Test.setMock(HttpCalloutMock.class, mockedHttpResponse);

            DnbEnrichmentService enrichmentService = new DnbEnrichmentService();

            List<Account> accounts = new List<Account>();
            Account acc =  new Account(Name = 'test account');
            accounts.add(acc);
            insert accounts;

            DnbEnrichmentService.mapAccountSearchCriteria(accounts[0]);

            List<DnbResult> results = enrichmentService.getMatchResults(createDnbRequest(accounts));

            Map<String, Object> fieldsToValue = acc.getPopulatedFieldsAsMap();
            results = DnbEnrichmentService.getMatchResults(fieldsToValue);

            System.assertNotEquals(0, results.size());
    }

    // Helper method to create DNB request
    static ExternalService.DnbMatch.identityResolution_Request createDnbRequest(List<Account> accounts) {
        ExternalService.DnbMatch.identityResolution_Request request = new ExternalService.DnbMatch.identityResolution_Request();

            request.duns='123456789';
            request.name='test account';
            request.candidateMaximumQuantity = 10;
            request.confidenceLowerLevelThresholdValue = 6;
            request.isCleanseAndStandardizeInformationRequired = true;
            request.Authorization_set = true;

            return request;
    }

    @isTest
    static void testMapSearchCriteria() {

        Test.setMock(HttpCalloutMock.class, mockedHttpResponse);
        Map<String, Object> searchCriteria = new Map<String, Object>();
        searchCriteria.put('D_B_DUNS_Number__c', '123456789');

        ExternalService.DnbMatch.identityResolution_Request request = DnbEnrichmentService.mapSearchCriteria(searchCriteria);

        System.assertEquals('123456789', request.DUNS);
    }

    @isTest
    static void testGetSearchData() {

        Test.setMock(HttpCalloutMock.class, mockedHttpResponse);
        List<String> dunsList = new List<String>();
        dunsList.add('123456789');

        List<ExternalService.DnbSearch_searchCriteria_OUT_200_searchCandidates> searchCandidates = DnbEnrichmentService.getSearchData(dunsList);

        System.assertEquals(dunsList.size(), searchCandidates.size());
    }

    @isTest
    static void testGetDnBDataBlocksInfo() {


        Test.setMock(HttpCalloutMock.class, mockedHttpResponse);
        String dunsNumber = '123456789';

        // Call the getDnBDataBlocksInfo method
        DnbResult result = DnbEnrichmentService.getDnBDataBlocksInfo(dunsNumber);

        System.assertEquals(null, result.NumberofEmployees);

    }
}