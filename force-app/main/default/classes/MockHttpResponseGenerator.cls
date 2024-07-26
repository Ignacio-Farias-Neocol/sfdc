@IsTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    public HttpResponse mockedHttpResponse;

    global HttpResponse respond(HTTPRequest req) {
        return this.mockedHttpResponse;
    }

    public static MockHttpResponseGenerator getDnbSearchApiResponse() {
        MockHttpResponseGenerator response = new MockHttpResponseGenerator();

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        String jsonBody = '{' +
        '"responseCode": 200,' +
        '"matchCandidates": [' +
            '{"organization":' +
                '{"duns": "123456789",' +
                '"primaryName": "ABC Test",' +
                '"telephone":[{ "telephoneNumber":"6505550000","isUnreachable":false }],' +
                '"corporateLinkage":' +
                    '{"familytreeRolesPlayed":[' +
                        ' {"description":"Parent / Headquarters","dnbCode":"9141"}' +
                    ']}' +
                '}' +
            '}' +
        '],' +
        '"transactionDetail": {"transactionID": "0dae58047eafe4568", "transactionTimestamp": "2019-09-18T16:22:32.079Z", "inLanguage": "en-US", "serviceVersion": "1"},' +
        '"searchCandidates": [' +
            '{"organization": {"duns": "123456789", "primaryName": "ABC Test"}}' +
        ']}';

        res.setBody(jsonBody);
        res.setStatusCode(200);

        response.mockedHttpResponse = res;
        return response;
    }
}