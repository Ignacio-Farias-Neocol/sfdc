/**
* @author        salesforce services
* @date          2020-11-18
* @description   Unit Test class for DynamicBusinessRuleCaseEntitlement class
* @group         Test
*
*/


@isTest
public with sharing class DynamicBusinessRuleCaseEntitlementTest {
    
    /*
  @TestSetup
  static void setup() {
    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   

    //Create Parent Product
    Product2 testProduct                  = new Product2();
    testProduct.Name                      = 'Premium Support';
    testProduct.is_pst_enterprise__c      = true;
    testProduct.Base_SKU__c               = 'TEST_SKU';
    testProduct.ProductCode               = 'TEST_SKU';
    testProduct.Product_Sales_Grouping__c = 'Cloud Email Services';    

    insert testProduct;
    
    //Opportunity
    Opportunity testOpp = TestDataFactory.opportunities[0];

    //Quote
    SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, 
                                                  SBQQ__Primary__c      = true);
    insert testQuote;

    //Contract
    Contract testContract = new Contract(AccountId            = TestDataFactory.customers[0].Id, 
                                          Business_Group__c   = 'Core', 
                                          SBQQ__Quote__c      = testQuote.Id, 
                                          StartDate           = System.today(),
                                          SBQQ__RenewalTerm__c = 12);
                                        
    insert testContract;

    SBQQ__Subscription__c testSub1 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                                SBQQ__Contract__c              = testContract.Id, 
                                                                SBQQ__SubscriptionStartDate__c = System.today(),
                                                                SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                                SBQQ__Product__c               = testProduct.Id,
                                                                SBQQ__Account__c               = TestDataFactory.customers[0].Id);     
    insert testSub1;

    //Create an entitlement
    //Get SLA process
    List <SlaProcess> slaProcesses = [SELECT  Id,  Name FROM SlaProcess WHERE name = 'Premium Cases' AND isActive = true];
      if(!slaProcesses.isEmpty()){
         Entitlement testEnt = new Entitlement(AccountId = TestDataFactory.customers[0].Id,
                                              SlaProcessId = slaProcesses[0].Id,
                                              Subscription__c = testSub1.Id,
                                              Name = 'Test Entitlement - Premium Support',
                                              StartDate = Date.today().addDays(-1),
                                              EndDate = testSub1.SBQQ__SubscriptionEndDate__c); 
          
              insert testEnt;           
      }

    TriggerHandler.clearAllBypasses();  
  }


   * Scenario 1: Premium Flag should turn on 

  @isTest
  public static void test_ShouldCreatePremiumCase(){

    //Get Account
    Account acc = [SELECT Id FROM Account LIMIT 1];
    //Get Subscription
    SBQQ__Subscription__c sub = [SELECT Id, SBQQ__Product__r.Name, Active__c FROM SBQQ__Subscription__c LIMIT 1];
    Test.startTest();
      //Create case
      Case webCase = new Case(Status = 'New',
                              Subject = 'Unit Test' + Date.Today(),
                              Origin = 'Web',
                              Subscription__c = sub.id,
                              AccountId = acc.Id);

      insert webCase;
      System.debug('webcase:: ' + JSON.serialize(webCase));
    Test.stopTest();

    //Assertion
    //Get updated case
    Case updatedCase = [Select Is_Premium_Support__c, Subscription__c, EntitlementId from Case where Id =:webCase.id];
      System.debug('updatedCase:: ' + JSON.serialize(updatedCase));
    //System.assert(updatedCase.Is_Premium_Support__c);

  }


   * Scenario 1: Premium Flag should turn on 

  @isTest
  public static void test_ShouldNotCheckPremiumFlag(){

    //Get Account
    Account acc = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();
      //Create case
      Case webCase = new Case(Status = 'New',
                              Subject = 'Unit Test' + Date.Today(),
                              Origin = 'Web',
                              AccountId = acc.Id);

      insert webCase;
    Test.stopTest();

    //Assertion
    //Get updated case
    Case updatedCase = [Select Is_Premium_Support__c, Subscription__c, EntitlementId from Case where Id =:webCase.id];
    System.assert(!updatedCase.Is_Premium_Support__c);
    System.assert(String.isBlank(updatedCase.EntitlementId));

  } */ 
}