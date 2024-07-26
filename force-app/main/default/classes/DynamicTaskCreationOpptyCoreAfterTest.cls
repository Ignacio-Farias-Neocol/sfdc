/**
* @author        Aditya Padhy
* @date          2022-12-22
* @description   Unit Test class for DynamicTaskCreationOpptyCoreAfter.
                 This test Class also covers the newly added code on TaskTrigger 
                 as a part of SFDC-17589
* @group         Test
*
*/
@isTest
public class DynamicTaskCreationOpptyCoreAfterTest {
    @testSetup static void setup() {
        // TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        List <Account> customers = TestDataFactory.customers;
        //Opportunity
        Opportunity testOpp = TestDataFactory.createOpportunity(customers[0]);
        testOpp.Business_Group__c = 'Core';
        insert testOpp;
    }
    @IsTest
    static  void test_createTask() {
        Opportunity opp = [Select Id , NextStep From Opportunity Limit 1];
        opp.NextStep = 'Next Step Logged';
        update opp;
    }
}