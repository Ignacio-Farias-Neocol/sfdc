/**
* @author        salesforce services
* @date          2020-02-05
* @description   Unit Test class for EchoPartnerHelper
* @group         Test
*
*/
@isTest
public with sharing class EchoPartnerHelperTest {

    //API request instance
    private static EchoPartnerHelper.EchoAPIRequest apiRequest= new EchoPartnerHelper.EchoAPIRequest();

    @testSetup
    static void setup() {
        apiRequest.username        = 'TestEchoPartnerUser';
        //apiRequest.password        = 'TestPassword1234';
        apiRequest.name            = 'Test Contact Name';
        apiRequest.company         = 'Big Huge Enterprise';
        apiRequest.streetAddress   = '123 Main St';
        apiRequest.streetAddress2  = '';
        apiRequest.streetAddress3  = '';
        apiRequest.streetAddress4  = '';
        apiRequest.city            = 'San Francisco';
        apiRequest.state           = 'CA';
        apiRequest.zip             = '94105';
        apiRequest.country         = 'USA';
        apiRequest.countryCode     = 'US';
        apiRequest.email           = 'test@bhe.tst';
        apiRequest.phone           = '123-444-5555';
        apiRequest.sfAccountId     = '001000001234AAA';
        apiRequest.extension       = '';
        apiRequest.fax             = '';
        apiRequest.partnerCurrency = '';
        apiRequest.planId          = '';
        apiRequest.pricingPlanIds  = '';
        apiRequest.partner         = '';
        apiRequest.accName 		   = 'Test Contact Name';
        apiRequest.conName         = 'Test Contact 01';
        apiRequest.conEmail        = 'test@test.com';
        apiRequest.bccAuthDBAdminId = '123456789';
    }

    @isTest
    static void usernameShouldBeCreated(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('echoPartnerSuccess');
        mock.setStatusCode(201);
        mock.setHeader('Content-Type', 'application/json');

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            // Call the method that performs the callout
            List<EchoPartnerHelper.EchoAPIResult> result = EchoPartnerHelper.upsertEchoPartner(new List<EchoPartnerHelper.EchoAPIRequest>{apiRequest});        
        Test.stopTest();

        // Verify response received contains values returned by the mock response.
        System.assertEquals(Label.ECHO_Username_Creation_Message, result[0].message);
        System.assert(result[0].result);
    }

    @isTest
    static void apiShouldSendError(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('echoPartnerFailure');
        mock.setStatusCode(400);
        mock.setHeader('Content-Type', 'application/json');

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
            // Call the method that performs the callout
            List<EchoPartnerHelper.EchoAPIResult> result = EchoPartnerHelper.upsertEchoPartner(new List<EchoPartnerHelper.EchoAPIRequest>{apiRequest});        
        Test.stopTest();

        // Verify response received contains values returned by the mock response.
        System.assertEquals('Username already used..', result[0].message);
        System.assert(!result[0].result);
    }
}