/**
 * Created by iyeung on 2/19/19.
 */

@isTest public class LiveChatTranscriptTriggerHandlerTest
{

@testSetup static void setup() {


}


@isTest
static void unitTest(){

    // by pass business action ,
    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
    List <Lead> l = TestDataFactory.postMQLLeads;
    TriggerHandler.clearAllBypasses();

    Test.StartTest();

    // LiveChatDeployment deployment = new LiveChatDeployment();
    // insert deployment;

    // LiveChatButtonDeployment button = new LiveChatButtonDeployment();
    // insert button;

    LiveChatVisitor vistor = new LiveChatVisitor();
    insert vistor;

    LiveChatTranscript transcript = new LiveChatTranscript();
    transcript.ChatKey = l[0].LiveChatTranscript_External_Id__c;
    transcript.External_Id__c  = l[0].LiveChatTranscript_External_Id__c;
    transcript.Chat_Type__c = 'Sales';
    transcript.Custom_Visitor_ID__c = '12345';
    transcript.Custom_Session_ID__c = '12345';
    transcript.Product_Reference__c = 'test product';
    transcript.Website__c = 'https://test.com';
    transcript.Visitor_FirstName__c = 'Unit';
    transcript.Visitor_LastName__c = 'test';
    transcript.Email__c = l[0].Email;
    transcript.Message__c = 'Test';
    transcript.Company__c = 'Test INC';

    // transcript.LiveChatButtonId   = button.Id;
    transcript.LiveChatVisitorId = vistor.Id;

    insert transcript;

    transcript.leadId = l[0].id;
    update transcript;

    Test.StopTest();
}


}