@isTest
public class RequestForClosurePopupControllerTest {
	
    @isTest
    static void updateCaseTest(){
        List<String> picklistValues = RequestForClosurePopupController.getPicklistValues();
        List<Case> caseList = TestDataFactory.webCases;
        RequestForClosurePopupController.updateCase(picklistValues[0], 'test', caseList[0].Id);  
        
        RequestForClosurePopupController.isTestRunning = true;
        RequestForClosurePopupController.updateCase(picklistValues[0], 'test running', caseList[0].Id);
    }
}