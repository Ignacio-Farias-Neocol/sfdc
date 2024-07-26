/**
 * Created by iyeung on 2019-08-08.
 */

/**
* @author        Ivan Yeung/salesforce services
* @date          2019 08 08
* @description   Unit Test class for SerialHistoryController
* @group         Test
*
*/
@isTest
public with sharing class SerialHistoryControllerTest {

    /**
     *
     */
    @isTest static void unitTest() {

        // prepare test data
        // by pass business action ,
        // TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        // List <Serial__c> serials = TestDataFactory.serials;
        // TriggerHandler.clearAllBypasses();

        List <Serial__c> serials = new LIst<Serial__c>();

        Serial__c serial1 = new Serial__c();
        serial1.Activation_Date__c = Date.today().addDays(3);
        serial1.Activation_Status__c = 'REPLACED';
        serial1.Serial_Number__c = '11111';
        serial1.Last_Serial__c = '22222';
        serial1.Status__c = 'Active';
        serials.add(serial1);

        Serial__c serial2 = new Serial__c();
        serial2.Activation_Date__c = Date.today().addDays(-2);
        serial2.Activation_Status__c = 'REPLACED';
        serial2.Serial_Number__c = '22222';
        serial2.Last_Serial__c = '33333';
        serial2.Status__c = 'Active';
        serials.add(serial2);

        Serial__c serial3 = new Serial__c();
        serial3.Activation_Date__c = Date.today();
        serial3.Activation_Status__c = 'ACTIVATED';
        serial3.Serial_Number__c = '33333';
        serial3.Last_Serial__c = '33333';
        serial3.Status__c = 'Active';
        serials.add(serial3);

        insert serials;

        Test.startTest();
        String jsonStr = SerialHistoryController.getSerialHistory(serial1.Id);
        System.debug('Json: ' + jsonStr);
        Test.stopTest();



    }

}