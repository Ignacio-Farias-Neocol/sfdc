@isTest
public with sharing class MoveContractRelatedRecordsTest {

    static Product2 testProd;
    static Account testAccount1;
    static Account testAccount2;   
    static Contract testsourceContact;
    static Contract testcurrContact;
    static Asset testAsset;

    static void setup() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');        

        List<Opportunity> testOpp1 = TestDataFactory.opportunities;
        Product2 testProd1                  = new Product2();
        testProd1.Name                      = 'Parent Product';       
        testProd1.Base_SKU__c               = 'Test';
        testProd1.ProductCode               = 'Test';
        insert new List<Product2>{testProd1};

        testsourceContact = new Contract();
        testsourceContact.AccountId = testOpp1[0].accountId;
        testsourceContact.SBQQ__Opportunity__c = testOpp1[0].Id;
        insert testsourceContact;       

        SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c();
        subscription1.SBQQ__Account__c  = testOpp1[0].accountId;
        subscription1.SBQQ__Contract__c = testsourceContact.Id;
        subscription1.SBCF_Serial_Number__c = null;
        subscription1.SBQQ__Quantity__c = 1;
        subscription1.SBQQ__Product__c=testProd1.Id;
        insert subscription1;      
       
        List<Opportunity> testOpp2 = TestDataFactory.opportunities;     
      
        Account customer = new Account();
        customer.Is_Unit_Test__c  = true;
        customer.Name = 'Customer 001';
        customer.billingStreet = '415 Mission Street';
        customer.billingCity = 'San Francisco';
        customer.BillingCountryCode = 'US';
        customer.billingStateCode = 'CA';
        customer.billingPostalCode = '94105'; 
        customer.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        customer.Status__c = 'Active';
        customer.Territory_ID__c = '123';
        customer.AccountSource = 'Renewal';
        customer.Terr_Theater__c = 'APAC';
        insert customer;

        Product2 testProd2                  = new Product2();
        testProd2.Name                      = 'Parent Product';       
        testProd2.Base_SKU__c               = 'Test';
        testProd2.ProductCode               = 'Test';
        insert new List<Product2>{testProd2};

        testcurrContact = new Contract();
        testcurrContact.AccountId = customer.Id;
        testcurrContact.SBQQ__Opportunity__c = testOpp2[0].Id;
        insert testcurrContact;        

        TriggerHandler.clearAllBypasses();
    }

    @isTest
    static  void unitTest1() {

       
        Test.startTest();
        setup();

        List<Contract> sourceCon = [SELECT Id, ContractNumber FROM Contract where Id=:testsourceContact.Id];
        List<Contract> currCon = [SELECT Id FROM Contract where Id=:testcurrContact.Id];

        MoveContractRelatedRecords.initiateMoveProcess(sourceCon[0].ContractNumber, currCon[0].Id);

        Test.stopTest();
    }

    @isTest
    static  void unitTest2() {

      
        Test.startTest();

        Account customer = new Account();
        customer.Is_Unit_Test__c  = true;
        customer.Name = 'Customer 001';
        customer.billingStreet = '415 Mission Street';
        customer.billingCity = 'San Francisco';
        customer.BillingCountryCode = 'US';
        customer.billingStateCode = 'CA';
        customer.billingPostalCode = '94105'; 
        customer.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        customer.Status__c = 'Active';
        customer.Territory_ID__c = '123';
        customer.AccountSource = 'Renewal';
        customer.Terr_Theater__c = 'APAC';
        insert customer;

        List<Opportunity> testOpp = TestDataFactory.opportunities;      

        testsourceContact = new Contract();
        testsourceContact.AccountId = testOpp[0].accountId;
        testsourceContact.SBQQ__Opportunity__c = testOpp[0].Id;
        insert testsourceContact;     

        testcurrContact = new Contract();
        testcurrContact.AccountId = customer.Id;
        testcurrContact.SBQQ__Opportunity__c = testOpp[0].Id;
        insert testcurrContact;        

        List<Contract> sourceCon = [SELECT Id, ContractNumber FROM Contract where Id=:testsourceContact.Id];
        List<Contract> currCon = [SELECT Id FROM Contract where Id=:testcurrContact.Id];

        MoveContractRelatedRecords.initiateMoveProcess(sourceCon[0].ContractNumber, currCon[0].Id);

        Test.stopTest();
    }
   
}