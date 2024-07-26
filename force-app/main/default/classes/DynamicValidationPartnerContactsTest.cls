/**
* @author        htut zaw/salesforce services
* @date          2019-10-14
* @description   Unit Test class for DynamicValidationPartnerContactsTest
* @group         Test
*
*/
@isTest
public with sharing class DynamicValidationPartnerContactsTest {

    @isTest static void unitTest() {


        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List<Opportunity> opptys = TestDataFactory.opportunities;
        TriggerHandler.clearAllBypasses();

        Test.startTest();
        DynamicValidationPartnerContacts d = new DynamicValidationPartnerContacts();
        d.evaluateRule(opptys);
        Test.stopTest();


    }

}