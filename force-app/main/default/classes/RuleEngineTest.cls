@isTest public with sharing class RuleEngineTest {
	
	@isTest static void test_BooleanRuleEngineSetTargetValue() {
		TriggerHandler.bypass('RollUpSummaryUtilityTriggerHandler');
		TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
		
		RuleEngine re = new RuleEngine();
		
		Case supportCase = TestDataFactory.supportCases[0];
		Id supportCaseId = supportCase.Id;
		
		re.setTargetValue(supportCase, 'Is_Enterprise_Account__c', 'false');
		
		update supportCase;
		
		supportCase = [select Is_Enterprise_Account__c from Case Where Id = :supportCaseId];
		
		System.assertEquals(false, supportCase.Is_Enterprise_Account__c);
		
		re.setTargetValue(supportCase, 'Is_Enterprise_Account__c', 'true');
		
		update supportCase;
		
		supportCase = [select Is_Enterprise_Account__c from Case Where Id = :supportCaseId];
		
		System.assertEquals(true, supportCase.Is_Enterprise_Account__c);
	}
	
	@isTest static void test_StringRuleEngineSetTargetValue() {
		TriggerHandler.bypass('RollUpSummaryUtilityTriggerHandler');
		TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
		RuleEngine re = new RuleEngine();
		
		Case supportCase = TestDataFactory.supportCases[0];
		Id supportCaseId = supportCase.Id;
		
		re.setTargetValue(supportCase, 'Web_First_Name__c', 'Jose Vega');
		
		update supportCase;
		
		supportCase = [select Web_First_Name__c from Case Where Id = :supportCaseId];
		
		System.assertEquals('Jose Vega', supportCase.Web_First_Name__c);
	}
    
    
}