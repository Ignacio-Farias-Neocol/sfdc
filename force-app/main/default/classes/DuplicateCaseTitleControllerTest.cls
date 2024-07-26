@isTest
public class DuplicateCaseTitleControllerTest {
	
    @isTest
    static void checkIfDuplicate(){
        Id webCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();
        
        Contact con = new Contact();
        con.LastName = 'test';
        insert con;        
        
        Case c = new Case();
        c.RecordTypeId = webCaseRTId;
        c.ContactId = con.Id;
        c.Subject = 'test';
        insert c;
        
        DuplicateCaseTitleController.checkIfDuplicate(c.Id);
        
        Case newCase = new Case();
        newCase.RecordTypeId = webCaseRTId;
        newCase.ContactId = con.Id;
        newCase.Subject = 'test';
        insert newCase; 
        
        DuplicateCaseTitleController.checkIfDuplicate(newCase.Id);
        DuplicateCaseTitleController.checkIfDuplicate(con.Id);
    }
}