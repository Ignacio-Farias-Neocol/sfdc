@isTest
public with sharing class DynamicBusinessRuleSetSalesRwOnCsTest {
    public testMethod static void testSalesReviewMethod(){
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Request Quote').getRecordTypeId();
        List<Account> newAccount = TestDataFactory.customers;
        newAccount[0].Terr_Theater__c = 'EMEA';
        update newAccount;
        Case caseRec = TestDataFactory.webCases[0];
        caseRec.RecordTypeId = caseRecordTypeId;
        caseRec.AccountId = newAccount[0].id;
        List<Case> lstCS = new List<Case>();
        lstCS.add(caseRec);
        update lstCS;
    }
}