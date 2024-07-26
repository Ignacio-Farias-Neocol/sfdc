/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-22-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class FlowActionQueuableHandlerTest {
    // Test method to cover the execute method of FlowActionQueuableHandler class
    static testMethod void testExecuteMethod() {
        // Test data setup
        // Create a Map<String, SObject> containing the payload data
        Map<String, SObject> payLoadMap = new Map<String, SObject>();

        // Call the constructor of FlowActionQueuableHandler with the test data
        FlowActionQueuableHandler handler = new FlowActionQueuableHandler(payLoadMap);
        
        // Call the execute method
        Test.startTest();
        System.enqueueJob(handler);
        Test.stopTest();
        

    }
}