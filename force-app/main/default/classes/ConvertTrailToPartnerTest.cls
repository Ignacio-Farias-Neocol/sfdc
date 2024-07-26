/**
* @author        Keerthi Atluri    
* @date          2020-05-15
* @description   Test class to cover ConvertTrailToPartner class
*
* @group         Test
*/

@isTest
global class ConvertTrailToPartnerTest {
    @testSetup static void createRecs() {
                
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List <Contact> contacts = TestDataFactory.customerContacts;
        List <Account> customers = TestDataFactory.customers;
        List <Account> partners = TestDataFactory.partners;
        List <Opportunity> opportunities = TestDataFactory.opportunities;
        TriggerHandler.clearAllBypasses();
    }
    
    @isTest static void testCallout() {        
        Test.startTest();
		Account acc = [SELECT Id,Name,User_na__c FROM Account WHERE Name LIKE 'Partner%' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ConvertTrailToPartnerMock());						
        ConvertTrailToPartner.callAPIToConvert(new List<String>{acc.Id});
        Test.stopTest();
    }
    @isTest static void testCalloutError() {        
        Opportunity opty = [SELECT Id,Name,Country_ISO_Code__c,Account.User_na__c FROM Opportunity WHERE Name LIKE 'Oppty%' LIMIT 1];		
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ConvertTrailToPartnerMock());						
        ConvertTrailToPartner.callAPIToConvert(new List<String>{Opty.Name});
        Test.stopTest();
    }
    @isTest static void testCalloutFailStatus() {        
        Account acc = [SELECT Id,Name,User_na__c FROM Account WHERE Name LIKE 'Partner%' LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ConvertTrailToPartnerMockFail());						
        ConvertTrailToPartner.callAPIToConvert(new List<String>{acc.Id});
        Test.stopTest();
    }
}