/**
 * Created by iyeung on 2/19/19.
 */

@isTest public class  OpportunityTriggerHandlerTest {



    @isTest
    static void unitTest() {

        // by pass business action ,
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        List <Contact> contacts = TestDataFactory.customerContacts;
        List <Account> customers = TestDataFactory.customers;
        List <Account> partners = TestDataFactory.partners;
        TriggerHandler.clearAllBypasses();



        Test.StartTest();
         List <Opportunity> opportunities = TestDataFactory.opportunities;
        Test.StopTest();
    }


}