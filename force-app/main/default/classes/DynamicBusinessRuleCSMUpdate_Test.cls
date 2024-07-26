/**
* @author        Aditya      
* @date          2024-04-10
* @description   Unit Test class for DynamicBusinessRuleCSMUpdate 
* @group         Test
*
*/
@isTest
public class DynamicBusinessRuleCSMUpdate_Test {
    
    @testSetup static void setup() {
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); 
        List <Account> customers = TestDataFactory.customers;
    }
    
    @IsTest
    static  void unitTest() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Apollo: Custom - Customer Success Profile']; 
        User u1 = new User(Alias = 'unit', Email='noonecsm@barracuda.com', 
            EmailEncodingKey='UTF-8', LastName='TestingMgr', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='noonecsm@barracuda.com.unit');
        insert u1;
        User u2 = new User(Alias = 'unit1', Email='noonecsm1@barracuda.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, ManagerId=u1.Id,
            TimeZoneSidKey='America/Los_Angeles', UserName='noonecsm1@barracuda.com.unit');
        insert u2;  
        Account acc = [SELECT Id,CSM_Name__c,CSM_Manager__c FROM Account LIMIT 1];
        System.AssertEquals(acc.CSM_Name__c,null); 
        System.AssertEquals(acc.CSM_Manager__c,null);
        acc.CSM2__c = u2.Id;
        Test.StartTest();
        	Update acc;
        Test.stopTest();
        
		Account acc1 = [SELECT Id,CSM_Name__c,CSM_Manager__c FROM Account WHERE Id= :acc.Id LIMIT 1];
		System.AssertEquals(acc1.CSM_Name__c,'Testing'); 
        System.AssertEquals(acc1.CSM_Manager__c,'TestingMgr');
    }
    
 }