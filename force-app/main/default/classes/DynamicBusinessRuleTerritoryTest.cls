@isTest
private  class DynamicBusinessRuleTerritoryTest {

    @TestSetup
    private static void testDataSetup(){
        Account act = new Account(
            Name = 'Dummy Account'   
            );

            insert act;   
    }

    @IsTest
    static void checkTerrAssignmentRun(){

        Test.setMock(HttpCalloutMock.class, new RestMock());
        Account acct = [Select id from Account limit 1];

        Test.startTest();
      
        acct.BillingCountry='India';
        acct.BillingState='Delhi';
        acct.BillingCity='Delhi';
        acct.BillingPostalCode='110001';

        update acct;

        Test.stopTest();
    }

    private class RestMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String responseJson = '[{"id":"0010300000f7qUbAAI","success":true,"errors":[]}]';
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(responseJson);
            res.setStatusCode(200);
            return res;
        }
    }
}