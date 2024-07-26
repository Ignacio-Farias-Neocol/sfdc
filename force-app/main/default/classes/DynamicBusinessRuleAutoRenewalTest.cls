/**
* @author        salesforce services
* @date          2020-11-24
* @description   Unit Test class for DynamicBusinessRuleAutoRenewalTest
* @group         Test
*
*/
@isTest
public with sharing class DynamicBusinessRuleAutoRenewalTest {
  @testSetup
  static void setup() {
    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); 
    
    //Account
    Account acc = TestDataFactory.customers[0];
    acc.Terr_Theater__c = 'AMERICAS';
    update acc;

    //Opportunity
    Opportunity testOpp = TestDataFactory.createOpportunity(acc);
    //Remove partners from the oppty
    testOpp.Distributor__c = null;
    testOpp.Distributor_Contact__c = null;
    testOpp.Reseller__c =  null;
    testOpp.Reseller_Contact__c = null;
    // testOpp.Business_Group__c = 'MSP';

    //Get addresses for the opportunity
    for(Address__c addr : [SELECT id, 
                                  Street__c, 
                                  City__c, 
                                  State_Name__c, 
                                  Country_Name__c, 
                                  Zip_Postal_Code__c,
                                  Type__c
                          FROM Address__c 
                          WHERE Account__c = :acc.Id ]){
      if(addr.Type__c == 'Billing'){
        System.debug('Inside billing');
        testOpp.Billing_Address__c = addr.Id;
        testOpp.Street__c = addr.Street__c;
        testOpp.City__c = addr.City__c;
        testOpp.State__c = addr.State_Name__c;
        testOpp.Country__c = addr.Country_Name__c;
        testOpp.Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
      }
      else if(addr.Type__c == 'Shipping'){
        System.debug('Inside shipping');
        testOpp.Shipping_Address__c = addr.Id;
        testOpp.Ship_To_Street__c = addr.Street__c;
        testOpp.Ship_To_City__c = addr.City__c;
        testOpp.Ship_To_State__c = addr.State_Name__c;
        testOpp.Ship_To_Country__c = addr.Country_Name__c;
        testOpp.Ship_To_Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
      }
    }

    insert testOpp;

    //Quote
    SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, 
                                                  SBQQ__Primary__c      = true);
    insert testQuote;

    //Contract

    Contract testContract1 = new Contract(AccountId           = acc.Id, 
                                         SBQQ__Opportunity__c = testOpp.Id,
                                         Business_Group__c    = 'Core', 
                                         SBQQ__Quote__c       = testQuote.Id, 
                                         StartDate            = System.today(),
                                         Has_SaaS_Products__c = true,
                                         ContractTerm         = 12,
                                         SBQQ__RenewalTerm__c = 12,
                                         Auto_Renewal_Status_Core__c = '',
                                         RMA_Detected__c = FALSE,
                                         SBQQ__Evergreen__c = FALSE,
                                         EndDate = Date.today());
    Contract testContract2 = new Contract(AccountId           = acc.Id, 
                                         SBQQ__Opportunity__c = testOpp.Id,
                                         Business_Group__c    = 'Core', 
                                         SBQQ__Quote__c       = testQuote.Id, 
                                         StartDate            = System.today(),
                                         Has_SaaS_Products__c = false,
                                         ContractTerm         = 12,
                                         SBQQ__RenewalTerm__c = 12,
                                         Auto_Renewal_Status_Core__c = '',
                                         RMA_Detected__c = FALSE,
                                         SBQQ__Evergreen__c = FALSE,
                                         EndDate = Date.today());
                                        
    insert new List<Contract>{testContract1, testContract2};

    TriggerHandler.clearAllBypasses();  
  }

  /**
   * Scenario 1: Should update one contract and other contract should remain unchanged
   */
  @isTest
  private static void test_ShouldUpdateContracts(){

    Test.startTest();

      //Get Account
      Account custAccount = [SELECT Id from Account Limit 1];
      //Update Account
      custAccount.Auto_Renewal_Status_Core__c = 'Included - Automatically';
      custAccount.Auto_Renewal_Status_Reason_Core__c = 'Included - based on Account Flag';
      custAccount.Terr_Theater__c = 'AMERICAS';
      update custAccount;

    Test.stopTest();
    //Get Contracts and assert
    for(Contract updatedContract: [SELECT Status,SBQQ__ActiveContract__c,SBQQ__Evergreen__c,EndDate,Has_SaaS_Products__c,
                                          Auto_Renewal_Status_Core__c,
                                          Auto_Renewal_Status_Reason_Core__c 
                                   FROM Contract 
                                   WHERE AccountId = :custAccount.Id]){

      if(!updatedContract.Has_SaaS_Products__c){
        System.assertEquals('Included - Automatically', updatedContract.Auto_Renewal_Status_Core__c);
        System.assertEquals('Included - based on Account Flag', updatedContract.Auto_Renewal_Status_Reason_Core__c);
      }
    }
  }
}