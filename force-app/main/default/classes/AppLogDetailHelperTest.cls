/**
* @author HZ
* @date 2019
*
* @description test class for AppLogDetailHelper
*   2019-11-25 : Initial creation
*/
@isTest
public with sharing class AppLogDetailHelperTest {

    @isTest static void unitTest() {

        AppLog__c al = new AppLog__c();
        al.message__c = 'Test';
        insert al;

        AppLogDetail__c ald = new AppLogDetail__c();
        ald.AppLog__c = al.id;
        ald.message_long__c = 'Test';
        ald.RefRecordID__c = al.id;
        ald.display__c = TRUE;

        AppLogDetailHelper.GetAppLogDetailParams param = new AppLogDetailHelper.GetAppLogDetailParams();
        param.recIds = al.id;
        List<AppLogDetailHelper.GetAppLogDetailParams> params = new List<AppLogDetailHelper.GetAppLogDetailParams> {param};

        Test.startTest();
        List<List<AppLogDetail__c>> results = AppLogDetailHelper.getAppLogDetail(params);
        System.assertEquals(1, results.size());
        Test.stopTest();
    }
}