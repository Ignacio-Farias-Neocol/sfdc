/**
* @author        Ivan Yeung/salesforce services
* @date          2018-11-10
* @description   Unit Test class for FieldsetRelatedListCon
* @group         Test
*
*/
@isTest
public with sharing class FieldsetRelatedListConTest {

    @isTest static void unitTest() {

        // Note: this assume that CPQ package is installed
        Object columns = FieldsetRelatedListCon.fetchGridColumns('SBQQ__Quote__c.SBQQ__Type__c', 'SBQQ__CalculatingFields');

        Object columns2 = FieldsetRelatedListCon.fetchGridColumns('SBQQ__Quote__c.Type', 'SBQQ__CalculatingFields');

        // TO do: improve coverage when other CPQ data is created later on Nov-11-2018
        // set up data
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        List <SBQQ__Quote__c> quotes = TestDataFactory.quotes;
        TriggerHandler.clearAllBypasses();

        List<sObject> objects = FieldsetRelatedListCon.fetchData(quotes[0].Id,  'SBQQ__Quote__c.SBQQ__Type__c', 'SBQQ__CalculatingFields', new list<string>() );

    }

}