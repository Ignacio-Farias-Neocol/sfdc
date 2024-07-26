@isTest
class CaseDependentPicklistControllerTest {
    @isTest
    static void testCaseDependentPicklistController() {
        new CaseDependentPicklistController();


        Account accObj = new Account();
        accObj.Name = 'Test';
        insert accObj;

        Contact conObj = new Contact();
        conObj.AccountId = accObj.Id;
        conObj.FirstName = 'Test';
        conObj.LastName = 'Test';
        conObj.Email = 'Test@test.com';
        insert conObj;

        Case caseObj = new Case(
            ContactId = conObj.id,
            AccountId = accObj.id,
            Status = 'In Progress',
            Origin = 'Web');
        insert caseObj;
        
        CaseDependentPicklistController.initData(
            JSON.serializePretty(new Map<String, Object>{'recordId'=> caseObj.Id}));
    }
}