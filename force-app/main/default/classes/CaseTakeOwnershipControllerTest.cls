/**
* @author        Ivan Yeung/salesforce services
* @date          2019-05
* @description   Unit Test class for CaseTakeOwnershipController
* @group         Test
*
*/
@isTest
public with sharing class CaseTakeOwnershipControllerTest {

    @isTest static void unitTest() {

        // by pass business action ,
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        List <Case> l = TestDataFactory.supportCases; // TestDataFactory.webCases;
        TriggerHandler.clearAllBypasses();

        ServiceChannel sc = [Select Id from ServiceChannel Where DeveloperName = 'Case'];

        PendingServiceRouting p = new PendingServiceRouting(
        	CapacityWeight = 1,
        	PushTimeout = 0,
            IsReadyForRouting = FALSE,
            RoutingModel  = 'MostAvailable',
            RoutingPriority = 1,
            RoutingType = 'SkillsBased',
            ServiceChannelId=sc.Id,
 			WorkItemId = l[0].id);
        
        insert p;

        CaseTakeOwnershipController.changeOwner(l[0].id);


    }

}