/**
 * Created by iyeung on 3/25/19.
 */


/**
* @author        Ivan Yeung/salesforce services
* @date          2019-03-15
* @description   Unit Test class for CreditCardTriggerHandler
* @group         Test
*
*/
@isTest
public with sharing class CreditCardTriggerHandlerTest {

    @isTest
    static void unitTest(){


        // prepare test data
        // by pass business action ,
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List <Account> customers = TestDataFactory.customers;
        TriggerHandler.clearAllBypasses();

        // create credit card
        Credit_Card__c cc = new Credit_Card__c();
        cc.Account__c = customers[0].Id;
        cc.token__c = '29938282811191';
        insert cc;

    }

}