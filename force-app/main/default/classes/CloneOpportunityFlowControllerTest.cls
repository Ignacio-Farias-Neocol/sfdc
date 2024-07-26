/**
* @author HZ
* @date 2020
*
* @description test class for CloneOpportunityFlowController
*   2020-03-04 : Initial creation
*/
@isTest
public with sharing class CloneOpportunityFlowControllerTest {

    @isTest static void unitTestPositive() {

        User usr = TestDataFactory.createUser('System Administrator');
        CustomPermission cp = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'Clone_Opportunity'];
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
            results = CloneOpportunityFlowController.checkClonePermission();
        }
        System.assertEquals(true, results);
        Test.stopTest();
    }

    @isTest static void unitTestNegative() {

        User usr = TestDataFactory.createUser('Read Only');
        Boolean results;

        Test.startTest();
        System.runAs(usr) {
            results = CloneOpportunityFlowController.checkClonePermission();
        }
        System.assertEquals(false, results);
        Test.stopTest();
    }
}