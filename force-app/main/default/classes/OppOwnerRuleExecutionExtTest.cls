/**
* @author        salesforce services
* @date          11/04/2020
* @description   Unit Test class for OppOwnerRuleExecutionExt class
* @group         Test
*
*/
@isTest
public class OppOwnerRuleExecutionExtTest {

    @testSetup private static void setup() {
      //List of Opportunity Ownership rules
      List<Opportunity_Ownership_Rule__c> oorList = new List<Opportunity_Ownership_Rule__c>();
      //Prepare Opportunity Ownership Rules
      for(Integer i=0; i< 3; i++){
        Opportunity_Ownership_Rule__c oor = new Opportunity_Ownership_Rule__c(Active__c = true, 
                                                                              Opportunity_Owner__c = UserInfo.getUserId(),
                                                                              TerritoryID__c='TestId' + i);
        oorList.add(oor);
      }

      //Insert rules
      insert oorList;
    }

    @isTest
    private static void createStdSetController(){
      
      //Get rules
      List<Opportunity_Ownership_Rule__c> oorList = [SELECT Id, 
                                                            Active__c
                                                     FROM Opportunity_Ownership_Rule__c];

      //Create StandardSetController
      ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(oorList);
      stdSetController.setSelected(oorList);

      Test.startTest();
        //Call the extension controller
        OppOwnerRuleExecutionExt ext = new OppOwnerRuleExecutionExt(stdSetController);
      Test.stopTest();

      //Assertions
      System.assert(!ext.runRuleFromRecordPage);
      System.assert(ext.ruleIds!=null && !ext.ruleIds.isEmpty());
    }

    @isTest
    private static void createStdController(){
      
      //Get rules
      Opportunity_Ownership_Rule__c oor = [SELECT Id, 
                                                            Active__c
                                                     FROM Opportunity_Ownership_Rule__c Limit 1];

      //Create StandardSetController
      ApexPages.StandardController stdController = new ApexPages.StandardController(oor);

      Test.startTest();
        //Call the extension controller
        OppOwnerRuleExecutionExt ext = new OppOwnerRuleExecutionExt(stdController);
      Test.stopTest();

      //Assertions
      System.assert(ext.runRuleFromRecordPage);
      System.assert(ext.ruleIds!=null && !ext.ruleIds.isEmpty());
    }    
}