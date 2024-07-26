/**
* @author        htut zaw/salesforce services
* @date          2020-05-13
* @description   Unit Test class for DynamicValidationResellerContacts
* @group         Test
*
*/
@isTest
public with sharing class DynamicValidationResellerContactsTest {

    @isTest static void unitTest() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List<Opportunity> opptys = TestDataFactory.opportunities;
        List<Opportunity> updOpptys = new List<Opportunity>();
        for (Opportunity opp: opptys){
            opp.StageName = 'Discovery';
            updOpptys.add(opp);
        }
        update updOpptys;
        TriggerHandler.clearAllBypasses();

        Test.startTest();
        DynamicValidationResellerContacts d = new DynamicValidationResellerContacts();
        d.evaluateRule(opptys);
        Test.stopTest();
    }
}