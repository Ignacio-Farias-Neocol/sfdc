@isTest
class CaseAnalyticsContollerTest {
    @isTest
    static  void testCaseAnalyticsContoller() {


        Account accObj = new Account();
        accObj.Name = 'Test';
        insert accObj;

        Contact c = new Contact();
        c.AccountId = accObj.ID;
        c.FirstName = 'test';
        c.LastName = 'test';
        c.email = 'test@test.com';
        insert c;


        Case caseObj = new Case(
            ContactId = c.id,
            AccountId = accObj.id,
            Status = 'In Progress',
            Origin = 'Web');
        insert caseObj;

        CaseAnalyticsContoller.initData();
        Map<String, Object> req= new Map<String, Object>();
        req.put('caseId', caseObj.Id);
        req.put('opr', 'In');
        CaseAnalyticsContoller.trackCaseActivity(JSON.serializePretty(req));
         req.put('opr', 'Out');
        CaseAnalyticsContoller.trackCaseActivity(JSON.serializePretty(req));
        CaseAnalyticsContoller.getTrackingStatus(caseObj.Id);
        CaseAnalyticsContoller.getTrackingOnUnloadStatus(caseObj.Id);
        CaseAnalyticsContoller.getCaseAnalytics(caseObj.Id);
        List<Case_Analytics__c> caseAn = [Select Id,In_Time__c,Out_Time__c From Case_Analytics__c limit 1];
        caseAn[0].In_Time__c = Datetime.now();
        caseAn[0].Out_Time__c = Datetime.now();
        caseAn[0].Case__c = caseObj.Id;
        update caseAn;
        CaseAnalyticsContoller.getCaseAnalytics(caseObj.Id);
        CaseAnalyticsContoller.upadateCaseAnalyticsWithCase(caseObj.Id, caseAn[0].Id);
       
    }
    
    @isTest
    static  void testCaseAnalyticsContollerForCommunityHelp() {

        String communityHelpRecordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Community Help').getRecordTypeId();

        Account accObj = new Account();
        accObj.Name = 'Test';
        insert accObj;

        Contact c = new Contact();
        c.AccountId = accObj.ID;
        c.FirstName = 'test';
        c.LastName = 'test';
        c.email = 'test@test.com';
        insert c;


        Case caseObj = new Case(
            ContactId = c.id,
            AccountId = accObj.id,
            Status = 'In Progress',
            recordTypeId = communityHelpRecordtypeId,
            Origin = 'Web');
        insert caseObj;

        CaseAnalyticsContoller.initData();
        Map<String, Object> req= new Map<String, Object>();
        req.put('caseId', caseObj.Id);
        req.put('opr', 'In');
        CaseAnalyticsContoller.trackCaseActivity(JSON.serializePretty(req));
        req.put('opr', 'Out');
        CaseAnalyticsContoller.trackCaseActivity(JSON.serializePretty(req));
        Delete [SELECT Id FROM Case_Time_Summary__c];
        CaseAnalyticsContoller.getTrackingStatus(caseObj.Id);
        Case_Analytics__c caseAnalyticObj = new Case_Analytics__c();
        caseAnalyticObj.Case__c = caseObj.Id;
        caseAnalyticObj.In_Time__c = Datetime.now();
        caseAnalyticObj.User__c = UserInfo.getUserId();
        insert caseAnalyticObj;        
        CaseAnalyticsContoller.getTrackingOnUnloadStatus(caseObj.Id);
        CaseAnalyticsContoller.getCaseAnalytics(caseObj.Id);
        List<Case_Analytics__c> caseAn = [Select Id,In_Time__c,Out_Time__c From Case_Analytics__c limit 1];
        caseAn[0].In_Time__c = Datetime.now();
        caseAn[0].Out_Time__c = Datetime.now();
        caseAn[0].Case__c = caseObj.Id;
        update caseAn;
        CaseAnalyticsContoller.getCaseAnalytics(caseObj.Id);
        CaseAnalyticsContoller.upadateCaseAnalyticsWithCase(caseObj.Id, caseAn[0].Id);
       
    }
}