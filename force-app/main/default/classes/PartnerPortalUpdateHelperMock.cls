/**
 * Created by iyeung on 2019-05-28.
 */
@isTest
global class PartnerPortalUpdateHelperMock implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
    // Optionally, only send a mock response for a specific endpoint
    // and method.
    // System.assertEquals('http://example.com/example/test', req.getEndpoint());
    // System.assertEquals('GET', req.getMethod());

    // Create a fake response
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setBody('{"message":"test"}');
    res.setStatusCode(200);
    return res;
    }
}