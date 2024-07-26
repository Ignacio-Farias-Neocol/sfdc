@isTest 
public class LiveChatTranscriptUserAcceptedTest
{

	@testSetup static void setup() {

	}

	@isTest static void testUserAccpetedChats() {

		TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
		List<Case> lCases = TestDataFactory.webCases;
		TriggerHandler.clearAllBypasses();

		Test.StartTest();
			try {
				LiveChatVisitor vistor = new LiveChatVisitor();
				insert vistor;

				LiveChatTranscript transcript = new LiveChatTranscript();
				transcript.body = 'Test';
				transcript.LiveChatVisitorId = vistor.Id;
				transcript.CaseId = lCases[0].Id;
				insert transcript;
				
				transcript.Status = 'InProgress';
				update transcript;
			}catch(Exception err) {
				System.debug('@@Error: '+err.getMessage());
			}
		Test.StopTest();
	}
}