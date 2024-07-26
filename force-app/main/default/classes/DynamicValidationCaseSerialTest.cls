/**
* @author        Ivan Yeung/salesforce services
* @date          2019-07-01
* @description   Unit Test class for DynamicValidationCaseSerialTest
* @group         Test
*
*/
@isTest
public with sharing class DynamicValidationCaseSerialTest {

    @isTest static void unitTest() {


        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List<Case> cases = TestDataFactory.supportCases;
        TriggerHandler.clearAllBypasses();


        Test.startTest();
        DynamicValidationCaseSerial d = new DynamicValidationCaseSerial();
        d.evaluateRule( cases);
        Test.stopTest();


    }

}