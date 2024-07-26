/**
* @author        salesforce services
* @date          2020-07-08
* @description   Mock response to throw callout exception
* @group         Test
*/
@TestVisible
public with sharing class MockCalloutError implements HttpCalloutMock{
  public HttpResponse respond(HttpRequest request) {
    CalloutException coe = (CalloutException)CalloutException.class.newInstance();
    coe.setMessage('Mock Callout Exception');
    throw coe;
  }
}