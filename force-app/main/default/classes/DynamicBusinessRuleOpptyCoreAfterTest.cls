/**
* @author Yuli Fintescu & Salesforce Services
* @date 2019-9-29
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description:
*   Updated test class to add scenarios for SFDC-13312
*/
@IsTest
private class DynamicBusinessRuleOpptyCoreAfterTest {
    
    @testSetup static void setup() {
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        List <Account> customers = TestDataFactory.customers;
        //Opportunity
        Opportunity testOpp = TestDataFactory.createOpportunity(customers[0]);
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
                              WHERE Account__c = :customers[0].Id ]){
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
        TriggerHandler.clearAllBypasses();
               
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true);
        insert new List<SBQQ__Quote__c>{new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true),
                                        new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id),
                                        new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id/*, SBCF_Reseller__c = newAccount2[0].Id, SBCF_Reseller_Contact__c = reselCon[0].id*/)};
    }

    /**
     * Scenario 1: Update Opportunity's payment terms to credit card and quote payment terms should change to credit card
     */
    @IsTest
    static  void test_QuotePaymentTermsCC() {
      Test.startTest();
        List<Opportunity> testOpps = [Select ID From Opportunity];
        testOpps[0].Payment_Terms__c = 'Credit Card';
        update testOpps[0];
      Test.stopTest();
      //Get updated quotes
      for(SBQQ__Quote__c quote: [SELECT SBQQ__PaymentTerms__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :testOpps[0].Id]){
        System.assertEquals('Credit Card', quote.SBQQ__PaymentTerms__c);
      }
    }

    /**
     * Scenario 2: Update Opportunity's payment terms to something other than credit card and 
     * quote payment terms should change to bill to account's payment terms
     */
    @IsTest
    static  void test_QuotePaymentTermsBillToAccount() {
      Test.startTest();
        List<Opportunity> testOpps = [Select ID From Opportunity];
        testOpps[0].Payment_Terms__c = 'Net 60';
        update testOpps[0];
      Test.stopTest();
      //Get updated quotes
      for(SBQQ__Quote__c quote: [SELECT SBQQ__PaymentTerms__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :testOpps[0].Id]){
        System.assertEquals('Net 30', quote.SBQQ__PaymentTerms__c); //default payment term of Account is Net 30
      }
    }
    @IsTest
    static  void unitTestAmendmentOpptyNaming() {
        List<Account> testAccounts = [Select ID From Account];

        Contract testContract = new Contract(AccountId = testAccounts[0].Id, StartDate = System.Today(), ContractTerm = 12);
        insert testContract;

        Test.startTest();
            try {
                Opportunity testOpp = new Opportunity(Name = 'Test Opp', AccountId = testAccounts[0].Id, SBQQ__AmendedContract__c = testContract.Id);
                insert testOpp;
            } catch (Exception e) {}
        Test.stopTest();
    }

    @IsTest
    static void test_ShouldUpdatePrimaryQuote() {
      //Get the Opportunity
      Opportunity opp = [SELECT Id FROM Opportunity limit 1 ];
      Account partner = [SELECT Id FROM Account WHERE Type = 'Distributor - Core' LIMIT 1];
      System.debug('partner is:' +partner);
      Contact distCon = [select id, accountId from contact limit 1];
      distCon.accountId = partner.id;
      update distCon;
      //List<Account> partner = TestDataFactory.partners;
      //partner[0].Type = '';
      //update partner;

      Test.startTest();
        if(opp!=null){
            opp.Distributor__c = partner.Id;
            opp.Distributor_Contact__c = distCon.Id;
        }
        update opp;
      Test.stopTest();
      //Get the updated quote
      SBQQ__Quote__c primaryQuote = [SELECT ID, 
                                            SBQQ__Distributor__c 
                                      FROM SBQQ__Quote__c 
                                      WHERE SBQQ__Opportunity2__c = :opp.Id 
                                      AND SBQQ__Primary__c = true ];
      System.assertEquals(partner.Id, primaryQuote.SBQQ__Distributor__c);
    }   
    
    @IsTest
    static void test_ShouldUpdateAllQuotes() {
      //Get the Opportunity
      Opportunity opp = [SELECT Id, AccountId FROM Opportunity limit 1 ];
      Id oldAccountId = opp.AccountId;
      Account newEnduserAcct = [SELECT Id FROM Account WHERE Type = 'Partner - Reseller' LIMIT 1];

      Test.startTest();
        opp.AccountId = newEnduserAcct.Id;
        update opp;
      Test.stopTest();

      //Get addresses for the new End User account
      
      //Loop through addresses and get billing and shipping address
      //Get the updated quote
      //compare end user account, billing and shipping address on quotes
      for(SBQQ__Quote__c quote: [SELECT Billing_Address__r.Account__c,
                                        Billing_Address__r.Account__r.Name,
                                        Shipping_Address__r.Account__c,
                                        Shipping_Address__r.Account__r.Name, 
                                        SBCF_Reseller__c,
                                        SBCF_Reseller__r.Name,
                                        SBQQ__Primary__c,
                                        Name
                                 FROM SBQQ__Quote__c 
                                 WHERE SBQQ__Opportunity2__c = :opp.Id]){
        if(String.isNotBlank(quote.SBCF_Reseller__c) && !quote.SBQQ__Primary__c){
          System.debug('Inside with reseller' + quote.Name + ' ' + quote.SBCF_Reseller__r.Name + ' ' + quote.SBQQ__Primary__c);
          System.assertEquals(oldAccountId, quote.Billing_Address__r.Account__c, 'Name: ' + quote.Billing_Address__r.Account__r.Name + quote.SBCF_Reseller__c );
          System.assertEquals(oldAccountId, quote.Shipping_Address__r.Account__c, quote.Shipping_Address__r.Account__r.Name);
        }
        else{
          System.debug('Inside without reseller' + quote.Name + ' ' + quote.SBQQ__Primary__c);
          System.assertEquals(newEnduserAcct.Id, quote.Billing_Address__r.Account__c, quote.Billing_Address__r.Account__r.Name);
          System.assertEquals(newEnduserAcct.Id, quote.Shipping_Address__r.Account__c, quote.Shipping_Address__r.Account__r.Name);
        }
        
      }
    }     
}