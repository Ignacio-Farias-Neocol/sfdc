/**
* @author Salesforce Services
* @date 10/28/2019
*
* @group N/A
* @group-content N/A
*
* @description Trigger on AgentWork object to execute logic during Omni Channel Routing. 
  Created initially for SFDC 8141.
*/
trigger AgentWorkTrigger on AgentWork (before insert, before update, after insert, after update, after delete) {
    new AgentWorkTriggerHandler().run();
}