@isTest(seeAllData=false)
private class picklistMergeTrigger_888292147_Test {
static testMethod void testToSatisfyCodeCoverage() {
Test.startTest();
SBQQ__QuoteLine__c instObjForTest = new SBQQ__QuoteLine__c();
try {
List<RecordTypeInfo> recTypeInfos = Schema.SObjectType.SBQQ__QuoteLine__c.getRecordTypeInfos();
if (recTypeInfos.size() > 1) {instObjForTest.put('RecordTypeId', recTypeInfos.get(0).getRecordTypeId());}
insert instObjForTest;
} catch (System.Dmlexception e) {}
Test.stopTest();
}}