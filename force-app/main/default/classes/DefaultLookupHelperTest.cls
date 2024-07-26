/**
* @author        Ivan Yeung/salesforce services
* @date          2018-11-05
* @description   Unit Test class for DefaultLookupHelper
* @group         Test
*
*/
@isTest
public with sharing class DefaultLookupHelperTest {
    @isTest static void unitTest() {


        Id caseId =  TestDataFactory.supportCases[0].Id;
        Id accountId =   TestDataFactory.supportCases[0].AccountId;
        Entitlement e = TestDataFactory.entitlements[0];


        Test.startTest();
        DefaultLookupHelper.Request req = new DefaultLookupHelper.Request();
        req.targetRecordId = caseId;
        req.targetField = 'EntitlementId';
        req.targetJoinField1 = 'AccountId';
        req.lookupConditionField1 = 'AccountId';
        req.field1Id = accountId;

        req.lookupSOQL = 'select AccountId, AssetId, Asset.AccountId, Id, EndDate, Name, StartDate, Status, Type from Entitlement where StartDate <= Today and EndDate >=Today and Name =\'Premium Support\' ';
        List<DefaultLookupHelper.Request> requests = new List <DefaultLookupHelper.Request> {req};
        DefaultLookupHelper.execute(requests);
        
        Test.stopTest();

        /*

        req.targetRecordId = '5003C0000020nXLQAY';
        req.targetField = 'EntitlementId';
        req.targetJoinField1 = 'AccountId';
        req.lookupConditionField1 = 'AccountId';
        req.field1Id = '0013C00000AYrzzQAD';

        req.lookupSOQL = 'select AccountId, AssetId, Asset.AccountId, Id, EndDate, Name, StartDate, Status, Type from Entitlement where StartDate <= Today and EndDate >=Today and Name =\'Premium Support\' ';
        List<DefaultLookupHelper.Request> requests = new List <DefaultLookupHelper.Request> {req};
        DefaultLookupHelper.execute(requests);
        */





    }
}