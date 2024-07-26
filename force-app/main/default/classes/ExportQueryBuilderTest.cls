/**
* @author        Ivan Yeung/salesforce services
* @date          2018-11-10
* @description   Unit Test class for ExportQueryBuilder
* @group         Test
*
*/
@isTest
public with sharing class ExportQueryBuilderTest {

    @isTest static void unitTest() {


        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = '/services/apexrest/ExportQueryBuilder/Product2';
        request.httpMethod = 'GET';
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest();

        String soql = ExportQueryBuilder.returnExportQuery();
        System.debug('~~~ Export SOQL : ' + soql);

        Test.stopTest();

    }


}