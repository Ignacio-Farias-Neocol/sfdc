/**
* @author HZ
* @date 2019
*
* @description test class for OppTerrAssignDefaultLogicFilter
*   2019-11-27 : Initial creation
*/

@isTest
public with sharing class OppTerrAssignDefaultLogicFilterTest{

    @isTest static void unitTest(){

        // prepare test data by pass business action ,
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        List <Contact> contacts = TestDataFactory.customerContacts;
        List <Account> customers = TestDataFactory.customers;
        List <Opportunity> opportunities = TestDataFactory.opportunities;
        TriggerHandler.clearAllBypasses();

        Id opportunityId = [Select Id From Opportunity].Id;
        OppTerrAssignDefaultLogicFilter filter = new OppTerrAssignDefaultLogicFilter();

        Test.startTest();
        Map<Id, Id> resultMap = filter.getOpportunityTerritory2Assignments(new List<Id> {opportunityId});
        OppTerrAssignDefaultLogicFilter.Territory2Priority tp = new OppTerrAssignDefaultLogicFilter.Territory2Priority(opportunityId, 1, false);
        Test.stopTest();

        System.assertEquals(tp.territory2Id, opportunityId);
    }
}