/**
* @author        Ivan Yeung/salesforce services       
* @date          2018-10-15
* @description   Unit Test class for Test Data Factory  
* @group         Test
*
*/
@isTest
public with sharing class TestDataFactoryTest {

 @isTest static void unitTest1() {

     TestDataFactory.createRealData = false; // don't create real data by default
     TestDataFactory.suffixNumber = 100;


     List <Account> partners = TestDataFactory.partners;
     System.debug('#### Partners Created:' + partners);
     System.assertNotEquals( 0, Partners.size(), 'There should be at least one record' );

     List <Account> customers = TestDataFactory.customers;
    System.debug('#### Customers Created:' + customers); 
    System.assertNotEquals( 0, customers.size(), 'There should be at least one record' );

    Opportunity opp = TestDataFactory.createEmptyOpportunity(customers[0]);

     List <Contact> customerContacts = TestDataFactory.customerContacts;
    System.debug('#### Customers Contact Created:' + customerContacts); 
    System.assertNotEquals( 0, customerContacts.size(), 'There should be at least one record' );

    System.debug('#### Standard pricebook id: ' + Test.getStandardPricebookId());
    System.debug('#### Pricebook in Test id: ' + TestDataFactory.priceBookId);
    
    List <Order> orders = TestDataFactory.orders;
    System.debug('#### Customers Orders Created:' + orders); 
    System.assertNotEquals( 0, orders.size(), 'There should be at least one record' );

     List<PricebookEntry> priceBookEntry  = TestDataFactory.priceBookEntry;
     List <Product2> products = TestDataFactory.products;


     // create test address
     Map<String, Map<String, State__c>> states = TestDataFactory.states;
     Map<String, Country__c> countries = TestDataFactory.countries;

     List<Lead> listleadmql = TestDataFactory.postMQLLeads;
     List<Asset> listasset = TestDataFactory.assets;
     List<SBQQ__Quote__c> pquotes = TestDataFactory.quotes;
     List<Entitlement> Entitlements = TestDataFactory.entitlements;
     
     Test.Starttest();
     
     List <Assigned_Serial__c> ptAssignedSerials = TestDataFactory.assignedSerials;
     Test.Stoptest();
    
     //List <Hot_List__c> listhotlist = TestDataFactory.hotlists;
     

     // test subscriptions
     // List <Contract> contracts = TestDataFactory.contracts;
     // List<SBQQ__Subscription__c> subscriptions = TestDataFactory.subscriptions;

 }
 
      @isTest static void unitTest2() {
          List <Serial__c> listserials = TestDataFactory.serials;
     }

    @isTest static void unitTest3() {
        Test.Starttest();
         List <Case> listcases = TestDataFactory.dpaasCases;
         Test.Stoptest();
         
     
    }
    
    @isTest static void unitTest4() {
        Test.Starttest();
     List <Hot_List__c> listhotlist = TestDataFactory.hotlists;
     Test.Stoptest();
    }


    @isTest static void unitTest5() {
     Test.Starttest();
     List <Case> listcases13 = TestDataFactory.webCases;
     Test.Stoptest();
    }
    
     @isTest static void unitTest6() {
     Test.Starttest();
     List <Case> listcases15 = TestDataFactory.offlineCases;
     Test.Stoptest();
    }
}