/**
* @author        htut zaw/salesforce services
* @date          2019-10-30
* @description   Unit Test class for DynamicBusinessRuleLeadAssgn
* @group         Test
*
*/
@isTest
public with sharing class DynamicBusinessRuleLeadAssgnTest {

    @isTest static void unitTest() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');

        Id msyncusrId = [select Id from User where username like 'legacy%' LIMIT 1].Id;
        List<Lead> leads = TestDataFactory.postMQLLeads;
        for (Lead l : leads) {
            l.OwnerId = msyncusrId;
        }

        TriggerHandler.clearAllBypasses();

        Test.startTest();
        DynamicBusinessRuleLeadAssgn rule = new DynamicBusinessRuleLeadAssgn();
        rule.processRecords(null, null, leads, '', '', '');
        Test.stopTest();

    }
}