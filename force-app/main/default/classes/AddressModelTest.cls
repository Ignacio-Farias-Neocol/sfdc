/**
* @author        Ivan Yeung/salesforce services
* @date          2018-11-10
* @description   Unit Test class for AddressModel
* @group         Test
*
*/
@isTest
public with sharing class AddressModelTest {
    @isTest static void unitTest() {

    // create test address
        Map<String, Map<String, State__c>> states = TestDataFactory.states;
        Map<String, Country__c> countries = TestDataFactory.countries;


    Test.startTest();

        Map<Id, Country__c>  countryMap = AddressModel.countryMap;
        Map<Id, State__c>  stateMap = AddressModel.stateMap;
        Map<Id , Map <Id, State__c>>  countryStateMap = AddressModel.countryStateMap;

    Test.stopTest();

    }
}