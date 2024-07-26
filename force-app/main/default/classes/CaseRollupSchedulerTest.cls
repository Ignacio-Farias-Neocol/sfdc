@isTest
public with sharing class CaseRollupSchedulerTest {
    
    @isTest
    public static void testCaseRollupScheduler() {

        Account testAccount = new Account(name='Test Company Name');
        insert testAccount;

        Contact conObj = new Contact();
        conObj.AccountId = testAccount.Id;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Test';
        conObj.Email = 'Test@test.com';
        insert conObj;

        Case caseObj = new Case(
            Subject='Test',
            Origin='Inbound Call',
            ContactId = conObj.Id,
            AccountId = testAccount.Id,
            Status = 'New');

        insert caseObj;

        CaseRollupScheduler.performCaseRollupInvocable(new List<Id>{caseObj.Id});

    }

    @isTest
    public static void testCaseRollupSchedulerV1() {

        Account testAccount = new Account(name='Test Company Name');
        insert testAccount;

        Contact conObj = new Contact();
        conObj.AccountId = testAccount.Id;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Test';
        conObj.Email = 'Test@test.com';
        insert conObj;

        List<RecordType> Community_HelpRecordType = [
            SELECT Id FROM RecordType Where DeveloperName = 'Community_Help'
        ];
        Case caseObj = new Case(
            Subject='Test',
            Origin='Inbound Call',
            ContactId = conObj.Id,
            AccountId = testAccount.Id,
            RecordTypeId = Community_HelpRecordType[0].Id,
            Status = 'New');

        insert caseObj;

        CaseRollupScheduler.performCaseRollupInvocable(new List<Id>{caseObj.Id});
        System.schedule('TestJob', '0 0 * * * ?', new CaseRollupScheduler());

    }
}