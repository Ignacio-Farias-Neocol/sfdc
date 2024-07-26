@isTest
public with sharing class UpsellGuidanceControllerTest {
    
    @testSetup
  static void setup() {
    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   

      Account customerAccount = TestDataFactory.customers[0];
      Opportunity testOpp = TestDataFactory.opportunities[0];

    Contract testContract = new Contract(AccountId = customerAccount.id, Business_Group__c = 'Core',
     StartDate = System.Today().addDays(-10),ContractTerm = 1
     
     );
    insert testContract;

  }

  @isTest public  static void initiateUpsellTest() {

    Test.startTest();
  
    Contract testCont = [Select id from Contract  LIMIT 1];

    UpsellGuidanceController.UpsellGuidanceResult res=UpsellGuidanceController.initiateUpsell(testCont.id);
     
    Test.stopTest();

    
   // To Do: Asserts
   

  }
}