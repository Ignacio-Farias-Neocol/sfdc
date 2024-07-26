/**
* @author        salesforce services
* @date          11/04/2020
* @description   Unit Test class for RuleExecutionComponentController class
* @group         Test
*
*/
@isTest
public class RuleExecutionComponentControllerTest {

  @TestSetup
  static void setUpTestData(){
    //Create Territory Model
    List<Territory2Model> tm = [SELECT Id FROM Territory2Model LIMIT 1];

    //Insert Territory type
    List<Territory2Type> tt = [SELECT Id FROM Territory2Type LIMIT 1];

    if(tm!=null && tt!=null){
      //Territory
      Territory2 terr = new Territory2(DeveloperName='TestTerritory',
                                      Name ='Test Territory',
                                      Territory2ModelId = tm[0].Id,
                                      Territory2TypeId = tt[0].Id);

      insert terr;
    }


  }

  //Scenario 1 - Should not execute a batch job as there are no rules
  @isTest
  private static void test_shouldNotExecuteBatchNoRules(){

    Test.startTest();
      //Create an instance of the controller
      RuleExecutionComponentController controller = new RuleExecutionComponentController();

      //Call the method
      controller.runOwnershipRules();

    Test.stopTest();

    //Assertion
    System.assert(controller.showOkButton);
    System.assertEquals(Label.Opp_Owner_Rule_No_Rules_Selected, controller.message);

  }

  //Scenario 2 - Should execute a batch job for multiple rules
  @isTest
  private static void test_shouldExecuteBatchForMultipleRules(){

    //Get territory
    List<Territory2> terr = [SELECT Id FROM Territory2 LIMIT 1]; 

    //Create Opportunity Ownership Rules
    List<Opportunity_Ownership_Rule__c> oorList = new List<Opportunity_Ownership_Rule__c>();
    //Prepare Opportunity Ownership Rules
    for(Integer i=0; i< 3; i++){
      Opportunity_Ownership_Rule__c oor = new Opportunity_Ownership_Rule__c(Active__c = true, 
                                                                            Opportunity_Owner__c = UserInfo.getUserId(),
                                                                            TerritoryID__c=terr[0]?.Id);
      oorList.add(oor);
    }

    //Insert rules
    insert oorList;

    List<Id> ruleIdList = new List<id>();
    for(Opportunity_Ownership_Rule__c oor: oorList){
      ruleIdList.add(oor.id);
    }

    Test.startTest();
      //Create an instance of the controller
      RuleExecutionComponentController controller = new RuleExecutionComponentController();
      controller.ruleIds = ruleIdList;
      controller.runRuleFromRecordPage = false;

      //Call the method
      controller.runOwnershipRules();

      Pagereference pr = controller.goBack();

    Test.stopTest();

    //Assertion
    System.assert(controller.showOkButton);
    System.assertNotEquals(Label.Opp_Owner_Rule_Job_Not_Submitted,controller.message);
    System.assert(pr.getUrl().contains('/'+Schema.SObjectType.Opportunity_Ownership_Rule__c.getKeyPrefix()+'/o'));

  }

  //Scenario 3 - Should execute a batch job for one rule
  @isTest
  private static void test_shouldExecuteBatchForOneRule(){
    //Get territory
    List<Territory2> terr = [SELECT Id FROM Territory2 LIMIT 1]; 

    //Create Opportunity Ownership Rule
      Opportunity_Ownership_Rule__c oor = new Opportunity_Ownership_Rule__c(Active__c = true, 
                                                                            Opportunity_Owner__c = UserInfo.getUserId(),
                                                                            TerritoryID__c=terr[0]?.Id);
    //Insert rules
    insert oor;

    Test.startTest();
      //Create an instance of the controller
      RuleExecutionComponentController controller = new RuleExecutionComponentController();
      controller.ruleId = oor.Id;
      controller.runRuleFromRecordPage = true;

      //Call the method
      controller.runOwnershipRules();

      Pagereference pr = controller.goBack();

    Test.stopTest();

    //Assertion
    System.assert(controller.showOkButton);
    System.assertNotEquals(Label.Opp_Owner_Rule_Job_Not_Submitted,controller.message);
    System.assert(pr.getUrl().contains('/'+oor.Id));

  }

}