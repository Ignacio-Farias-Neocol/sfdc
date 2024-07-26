@isTest
public class CaseProfessionalServicesHelperTest {
    
    @isTest
    static void createTaskOnCaseCommentTest(){
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List<Case> caseList = TestDataFactory.webCases;
        Case caseRec = [Select Id, CaseNumber, Account.Name, Contact.Name, OwnerId, Owner.Email from Case where Id =: caseList[0].Id limit 1];
        System.debug('##caseRec:: ' + JSON.serialize(caseRec));
        CaseProfessionalServicesHelper.WrapperObj wrapper = new CaseProfessionalServicesHelper.WrapperObj();        
        wrapper.caseRec = caseRec;
        wrapper.comment = 'test';
        List<CaseProfessionalServicesHelper.WrapperObj> wrapperList = new List<CaseProfessionalServicesHelper.WrapperObj>();
        wrapperList.add(wrapper);        
        Test.StartTest();
        CaseProfessionalServicesHelper.createTaskOnCaseComment(wrapperList);
        Test.StopTest();
        TriggerHandler.clearAllBypasses();  
    }
}