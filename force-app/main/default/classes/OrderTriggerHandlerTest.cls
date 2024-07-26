/**
* @author        Ivan Yeung/salesforce services       
* @date          2018-10-15
* @description   Unit Test class for OrderTriggerHandler  
* @group         Test
*
*/
@isTest
public with sharing class OrderTriggerHandlerTest {
    @isTest static void testInsertUpdate() {




        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        // create an order
        List <Order> orders = TestDataFactory.orders;
        TriggerHandler.clearAllBypasses();

        Test.startTest();

        // to do: create placed order 4/16/2019
        /*
        for (Order o: orders){
            o.Status = 'Placed';
        }
        DML.save(orders);
        */


        // Perform validations here   
        // Verify that an integration event is created 
        Test.getEventBus().deliver(); 
        System.debug('Integration Events created:' + PlatformEventHelper.eventList );

        // no platform event until place order
        // System.assertNotEquals( 0, PlatformEventHelper.eventList.size(), 'There should be one integration event in the list' );
        /*
            // put sample payload here 

        */

        Test.stopTest(); 

    }
}