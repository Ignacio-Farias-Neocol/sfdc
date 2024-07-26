/**
 * Created by pshetty on 12/09/2019
 * Mock callout response for BOS Account Update.
 */
@isTest
global class BOSAccountUpdateCalloutMock implements HttpCalloutMock{
  // Implement this interface method
  global HTTPResponse respond(HTTPRequest req) {
    // Create a fake response
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setBody('{"message":"test", "bos_account_id" : "12345678", "status":"1"}');
    res.setStatusCode(200);
    return res;
  }
}