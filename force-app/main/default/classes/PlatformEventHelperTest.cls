/**
* @author        Ivan Yeung/salesforce services       
* @date          2018-10-15
* @description   Unit Test class for PlatformEventHelper
*  note use without sharing to make sure that integration is supported regardless of user
*  SFDC_13498: Modified to add test for findFilteredRecords and increase code coverage
* @group         Test
*
*/

@isTest
public class PlatformEventHelperTest {

    @isTest static void testProcessRecords() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List <Account> accounts = TestDataFactory.customers;
        TriggerHandler.clearAllBypasses();

        PlatformEventHelper helper = new PlatformEventHelper();

        Test.startTest();
        
        helper.processRecords(null, null, accounts, '', '', 'Insert');
        helper.processRecords(null, null, accounts, '', '', 'Update');
        helper.processRecords(null, null, accounts, '', '', 'Delete');

        Test.stopTest();

    }

    @isTest static void testPublishObject() {
        

        // create an object for integration test. choose one that does not have trigger to publish event already e.g. Task
        Campaign acc = new Campaign();
        acc.Name = 'Test Campaign';
        DML.save(acc);

        Test.startTest();
        PlatformEventHelper helper = new PlatformEventHelper();
        List <Database.SaveResult> results = helper.publishObject(PlatformEventHelper.EVENT_TYPE_INSERT, (List <sObject>) new List<Campaign> {acc});
        // In test context, the EventBus.publish() method enqueues the publish operation. The Test.stopTest() statement causes the event publishing to be carried out and event messages to be delivered to the test event bus.
        Test.stopTest(); // Implicitly deliver test event messages after the Test.stopTest() statement. 
    
                
        // Perform validations here    
        // Verify that an integration event is created 
        System.assertEquals( 1, PlatformEventHelper.eventList.size(), 'There should be one integration event in the list' );
        // Verify SaveResult value
        // Inspect publishing result for each event
        Integer numFailure = 0; 
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' +
                                err.getStatusCode() +
                                ' - ' +
                                err.getMessage());
                }
                numFailure++; 
            }       
        }
        System.assertEquals(0, numFailure);

        // get event state 
        // List <EventBusSubscriber> lEventSubscribers = [SELECT Name, Position, Retries, LastError FROM EventBusSubscriber WHERE Topic='Integration_Event__e' AND Type='ApexTrigger'];
        // System.assertNotEquals(0, lEventSubscribers.size()); 
        // for (EventBusSubscriber sub:lEventSubscribers){
        //     system.debug('sub.Retries=' + sub.Retries);
        //     system.debug('sub.lastError=' + sub.lastError);
        // }


    }
    
    @isTest static void testFindFilteredRecords() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        Account account = TestDataFactory.customers[0];
        //Clone the account 
        Account clonedAccount = account.clone();
        clonedAccount.Name = 'Different Name';
        TriggerHandler.clearAllBypasses();

        Test.startTest();
        Boolean filterResult = PlatformEventHelper.findFilteredRecords('Account', 
                                                                       new Map<Id, SObject>{account.Id => account}, 
                                                                       new Map<Id, SObject>{account.Id => clonedAccount}, 
                                                                       new List<SObject>());

        Test.stopTest();
        System.assert(filterResult);

    }
}