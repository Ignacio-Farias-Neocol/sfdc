/**
* @author HZ
* @date 2020
*
* @description test class for NewOpportunityCheckController
*   2020-06-05 : Initial creation
*/
@isTest
public with sharing class NewOpportunityCheckControllerTest {

    @isTest static void unitTestPositive() {

        User usr = TestDataFactory.createUser('System Administrator');
        CustomPermission cp = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'Create_New_Opportunity'];
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        PermissionSet ps = new PermissionSet();
        ps.Name = 'Test';
        ps.Label = 'Test';
        insert ps;

        SetupEntityAccess sea = new SetupEntityAccess();
        sea.ParentId = ps.Id;
        sea.SetupEntityId = cp.Id;
        insert sea;

        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = usr.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;

        Boolean results;

        Test.startTest();
        System.runAs(usr) {
            results = NewOpportunityCheckController.checkNewOppPermission();
        }
        System.assertEquals(true, results);
        Test.stopTest();
    }

    @isTest static void unitTestNegative() {

        User usr = TestDataFactory.createUser('Read Only');
        Boolean results;

        Test.startTest();
        System.runAs(usr) {
            results = NewOpportunityCheckController.checkNewOppPermission();
        }
        System.assertEquals(false, results);
        Test.stopTest();
    }
}