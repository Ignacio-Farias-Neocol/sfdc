/**
* @author        Salesforce Services
* @date          2021-03-30
* @description   Unit Test class for SubscriptionQtyInUseCorrection
* @group         Test
*
*/
@isTest
private with sharing class SubscriptionQtyInUseCorrectionTest {
	@testSetup
  static void setup() {

    // by pass business action
    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); 
    List<Contact> contacts = TestDataFactory.customerContacts;
    List<Account> customers = TestDataFactory.customers;
    customers[0].Type = 'Partner - MSP';
    update customers;

    List<Account> partners = TestDataFactory.partners;
    List<Product2> products = TestDataFactory.products;
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

    Contract contract = new Contract();
    contract.AccountId = testOpp.accountId;
    contract.SBQQ__Opportunity__c = testOpp.Id;
    contract.Business_Group__c = 'MSP';
    insert contract;

    Serial__c serial1 = new Serial__c();
    serial1.Serial_Number__c = '9999';
    serial1.Status__c = 'Active';
    serial1.Contract__c = contract.Id;

    Serial__c serial2 = new Serial__c();
    serial2.Serial_Number__c = '0000';
    serial2.Status__c = 'Active';
    serial2.Contract__c = contract.Id;        
    insert new List<Serial__c>{serial1, serial2};

    //Insert 10 subscriptions
    List<SBQQ__Subscription__c> subs = new List<SBQQ__Subscription__c>();

    for(Integer i = 0; i< 10; i++){
      SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
      subscription.SBQQ__Account__c  = testOpp.accountId;
      subscription.SBQQ__Contract__c = contract.Id;
      subscription.SBCF_Serial_Number__c = null;
      subscription.SBQQ__Quantity__c = 1;
      subscription.Quantity_In_Use__c = 0;
      subscription.Status__c = 'Active';
      subs.add(subscription);
    }
    insert subs;         

    //Insert 10 Assigned Serial for the inserted subs
    List<Assigned_Serial__c> assignedSerials = new List<Assigned_Serial__c>();

    Integer counter = 0;
    for(SBQQ__Subscription__c sub: subs){
      Assigned_Serial__c aserial = new Assigned_Serial__c();
      aserial.Serial__c = serial1.Id;
      aserial.Subscription__c = sub.Id;
      aserial.Status__c = 'Active';
      aserial.Qty_in_Use__c = 10;
      aserial.External_Id__c = 'uniqueId' + counter;

      assignedSerials.add(aserial);
      counter++;
    }
    insert assignedSerials; 
    TriggerHandler.clearAllBypasses();    
  }


  @isTest 
  private static void test_ShouldUpdateSubs() {

    Test.startTest();
      SubscriptionQtyInUseCorrection subCorrection = new SubscriptionQtyInUseCorrection();
      Database.executeBatch(subCorrection);  
    Test.stopTest();

    //Assertion
    List<SBQQ__Subscription__c> subs = [SELECT Id, 
                                               Quantity_In_Use__c 
                                        FROM SBQQ__Subscription__c];
    for(SBQQ__Subscription__c sub: subs){
      //System.assertEquals(10, sub.Quantity_In_Use__c);
    }

	}  

  @isTest 
  private static void test_ConstructorWithQueryString() {

    Test.startTest();
      String queryString = 'SELECT Id, Quantity_In_Use__c,' +
                           '(SELECT Qty_In_Use__c FROM Assigned_Serials__r WHERE Status__c = \'Active\')' +
                           ' FROM SBQQ__Subscription__c' +
                           ' WHERE Business_Group__c = \'MSP\'';
      SubscriptionQtyInUseCorrection subCorrection = new SubscriptionQtyInUseCorrection(queryString);
      subCorrection.testErrorMessage = true;
      Database.executeBatch(subCorrection);  
    Test.stopTest();

    //Assertion
    List<SBQQ__Subscription__c> subs = [SELECT Id, 
                                               Quantity_In_Use__c 
                                        FROM SBQQ__Subscription__c];
    for(SBQQ__Subscription__c sub: subs){
      //System.assertEquals(10, sub.Quantity_In_Use__c);
    }

	}    
}