@isTest
public with sharing class DynamicBusinessRuleOppPickAssTest {
    
    public testMethod static void test_Method (){
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        Product2 product = new Product2();
        product.Name = 'CR-ADJ-Other';
        product.Description='CR-ADJ-Other';
        product.productCode = 'CR-ADJ-Other';
        product.isActive = true;
        insert product;
                    
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = product.Id;
        standardPrice.UnitPrice = 1;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
        
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
        INSERT customer;
        
        Contact rec = new Contact();
        rec.LastName = 'Test';
        rec.FirstName = 'TEst';
        rec.Email = 'test.test@test.com';
        rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        rec.AccountId = customer.Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';
        INSERT rec;
        TriggerHandler.clearAllBypasses();

        //Opportunity
        List<Opportunity> lstOpp = new List<Opportunity>();
        Opportunity oppt = new Opportunity();
        oppt.Name ='Oppty 001';
        oppt.AccountID = customer.Id;
        oppt.Bill_To_Account__c = customer.Id;
        oppt.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt.Model_Series__c = 'API';
        oppt.StageName = 'Accepted';
        oppt.Amount = 3000;
        oppt.CloseDate = System.today();
        oppt.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        oppt.Bypass_Validation__c = true;
        oppt.Is_Unit_Test__c = true;
        oppt.LeadSource = 'Renewal';
        oppt.BypassBusinessGroupValidation__c = True;
        oppt.Business_Group__c = 'Core';
        oppt.Primary_Product_Family_2__c = 'Test Value';
        lstOpp.add(oppt);
        //INSERT oppt;
        Test.startTest();
        DynamicBusinessRuleOpptyPickListAssign.processRecords(NULL, NULL, lstOpp, NULL, NULL, 'Insert');
        Test.stopTest();
    }
}