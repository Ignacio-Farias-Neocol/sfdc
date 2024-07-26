@IsTest
private class DynamicBusinessRuleOpptyMSPAfterTest {
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
        testOpp.Business_Group__c = 'MSP';

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
                                        new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id)};
    }

    
    @IsTest
    static  void test_shippingaddrss() {
      Test.startTest();
        List<Opportunity> testOpps = [Select ID,AccountID From Opportunity];
        
        Address__c addr = new Address__c();
            addr.Country__c = TestDataFactory.countries.get('US').Id;
            addr.State__c = TestDataFactory.states.get('US').get('CA').Id;
            addr.Street__c = 'test Street';
            addr.City__c = 'test';
            addr.Zip_Postal_Code__c = '94105';
            addr.Type__c = 'Shipping';
            addr.Account__c = testOpps[0].AccountId;
            addr.Primary__c = true; // required to ensure that opportunity default address works
         insert addr;
        
        testOpps[0].Shipping_Address__c = addr.ID;
        update testOpps[0];
      
      //Get updated quotes
      for(SBQQ__Quote__c quote: [SELECT Shipping_Address__c,SBQQ__Opportunity2__r.Shipping_Address__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c = :testOpps[0].Id]){
        System.assertEquals(quote.SBQQ__Opportunity2__r.Shipping_Address__c, addr.ID);
        
      }
        
        Test.stopTest();
    }
    
}