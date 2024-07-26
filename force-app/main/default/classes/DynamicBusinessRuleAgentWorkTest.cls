/**
* @author        salesforce services
* @date          10/28/2019
* @description   Unit Test class for DynamicBusinessRuleAgentWork
* @group         Test
*
*/
@isTest
public with sharing class DynamicBusinessRuleAgentWorkTest {
  //Scenario: BOS Sync is successful
  @isTest static void test_ShouldUpdateCaseStatus() {

    //Create a case for test 
    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
    Case newCase = TestDataFactory.supportCases[0];
    TriggerHandler.clearAllBypasses();

    //Create AgentWork Record
    AgentWork aw = new AgentWork(WorkItemId = newCase.Id);

    Test.startTest();

    //Call the process records method
    DynamicBusinessRuleAgentWork businessRule = new DynamicBusinessRuleAgentWork();
    businessRule.processRecords(null, null, new List<AgentWork>{aw}, null, null, null);
    
    Test.stopTest();

    //Fetch the updated Case
    Case updatedCase = [Select Status
                         From Case 
                         Where Id = :newCase.Id 
                         Limit 1];
    //Assertions
    System.assertEquals('In Progress', updatedCase.Status);
  }

  //Code coverage for AgentWorkTrigger
  @isTest static void test_ShouldCallTrigger() {

    //Create a case for test 
    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
    Case newCase = TestDataFactory.supportCases[0];
    TriggerHandler.clearAllBypasses();

    //Get a service channel ID
    ServiceChannel serviceChannel = [SELECT Id FROM ServiceChannel WHERE DeveloperName = 'Case'];    

    Test.startTest();
    //Create AgentWork Record
    try{
      AgentWork aw = new AgentWork(WorkItemId = newCase.Id,
                                  ServiceChannelId = serviceChannel.Id,
                                  UserId = UserInfo.getUserId());
      insert aw;
    }
    catch (Exception e){
      system.debug('---Exception---' + e.getMessage());
    }
    Test.stopTest();

  }  
}