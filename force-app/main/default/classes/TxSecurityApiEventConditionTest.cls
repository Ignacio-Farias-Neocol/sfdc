@isTest
public class TxSecurityApiEventConditionTest {
    public TxSecurityApiEventConditionTest() {

    }

    @testSetup
    static void setupTestData(){

        List<User> usersToinsert = new List<User>();

        Profile p = [Select Id, Name from Profile Where Name = 'System Administrator'];

        User testUser1 = new User(Alias = 'tstUser1', Email='testTxuser1@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='testTxuser1@testorg.com');
        usersToinsert.add(testUser1);

        User testUser2 = new User(Alias = 'tstUser2', Email='testTxuser2@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='testTxuser2@testorg.com');
        usersToinsert.add(testUser2);

        insert usersToinsert;

        //Assign permission set to testUser1
        PermissionSet perSet = [Select Id, Name from PermissionSet Where Name = 'Execute_Workbench_Queries'];

        PermissionSetAssignment permAssign = new PermissionSetAssignment(AssigneeId = testUser1.Id, PermissionSetId = perSet.Id);
        insert permAssign;
        
    }

    static testMethod void testWorkbenchQueryEvent(){
        User u1 = [Select Id, Name, Email from User where Email = 'testTxuser1@testorg.com' AND LastName = 'Testing1'];
        User u2 = [Select Id, Name, Email from User where Email = 'testTxuser2@testorg.com' AND LastName = 'Testing2'];
        
        //User u1 has the permission assigned and should be able to run the query event
        System.runAs(u1){
            ApiEvent testApiEvent = new ApiEvent();
            testApiEvent.Query = 'Select Id, Name from Account LIMIT 1';
            testApiEvent.UserId = u1.Id;
            testApiEvent.Client = TxSecurityApiEventCondition.WORKBENCH_CLIENT;
            
            TxSecurityApiEventCondition eventCondition = new TxSecurityApiEventCondition();
            Boolean conditionEvaluated = eventCondition.evaluate(testApiEvent);
            system.assertEquals(false,conditionEvaluated);
        }

        System.runAs(u2){
            ApiEvent testApiEvent2 = new ApiEvent();
            testApiEvent2.Query = 'Select Id, Name from Account LIMIT 1';
            testApiEvent2.UserId = u2.Id;
            testApiEvent2.Client = TxSecurityApiEventCondition.WORKBENCH_CLIENT;
            
            TxSecurityApiEventCondition eventCondition2 = new TxSecurityApiEventCondition();
            Boolean conditionEvaluated2 = eventCondition2.evaluate(testApiEvent2);
            system.assertEquals(true,conditionEvaluated2);

            //Test Negative conditions
            Boolean nullConditionEvaluate = eventCondition2.evaluate(null);
            system.assertEquals(false, nullConditionEvaluate);
            

        }
    }

}