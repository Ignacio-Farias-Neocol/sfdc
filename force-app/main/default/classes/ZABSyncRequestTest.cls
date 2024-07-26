/**
* @author        Salesforce Services       
* @date          2021-21-01
* @description   Test class for ZABSyncRequest
*
* @group         Helper
*/
@isTest
public with sharing class ZABSyncRequestTest {

  /** Scenario1 : Mock service should return a success when accountId is passed
   */
  @isTest static void test_shouldSubmitRequest() {
    
    //Get account Id
    Account acc = TestDataFactory.customers[0];

    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('mockSyncToZABResponse');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
      // Call the method that performs the callout
      List<ZABSyncRequest.SyncResponse> result = ZABSyncRequest.submitSyncRequest(new List<Id>{acc.Id});
    Test.stopTest();

    // Verify response received contains values returned by the mock response.
    System.assert(result[0].result);
    System.assertEquals('Request submitted successfully.',result[0].message);
  }

 /** Scenario 2 : Mock service should return a failure when accountId is passed
   */
  @isTest static void test_shouldReturnError() {
    
    //Get account Id
    Account acc = TestDataFactory.customers[0];

    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('mockSyncToZABError');
    mock.setStatusCode(404);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
      // Call the method that performs the callout
      List<ZABSyncRequest.SyncResponse> result = ZABSyncRequest.submitSyncRequest(new List<Id>{acc.Id});
    Test.stopTest();
    // Verify response received contains values returned by the mock response.
    System.assert(!result[0].result);
    System.assertEquals('Error submitting the request',result[0].message);
  }  
}