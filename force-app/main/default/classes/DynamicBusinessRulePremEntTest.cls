/**
* @author        Ivan Yeung/salesforce services
* @date          2019-02-15
* @description   Unit Test class for DynamicBusinessRulePremEnt
* @group         Test
*
*/
@isTest
public with sharing class DynamicBusinessRulePremEntTest {
    
    /*

    @isTest static void unitTest() {

        Test.startTest();
        // to do: create a proper SBQQ__Subscription__c
        SBQQ__Subscription__c s = new SBQQ__Subscription__c();
        s.ExtendedMonthlyPrice__c = 1;
        s.SBQQ__Quantity__c = 1;
        s.OverageRate__c = 1;
        s.SBQQ__Account__c = TestDataFactory.customers[0].Id;

        List <SBQQ__Subscription__c> subscriptions = new List <SBQQ__Subscription__c>();
        subscriptions.add(s);

        DynamicBusinessRulePremEnt d = new DynamicBusinessRulePremEnt();
        d.processRecords(null, null, subscriptions, '', '', '');
        Test.stopTest();

        //Fetch the newly created entitlement
        List<Entitlement> entList = [Select Name, 
                                  StartDate 
                           From Entitlement limit 1];

        //Assertion
        System.assert(entList.isEmpty());
        //System.assert(String.isNotBlank(entList[0].Name) && entList[0].Name.contains('Premium Support'));
        //System.assertEquals(Date.today().addDays(-1), entList[0].StartDate);

    } */

}