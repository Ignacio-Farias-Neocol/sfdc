/**
* @author        Dilowar
* @date          2023-08-31
* @description   Test class for DynamicBusRuleOnIntegrationSnap.
*                This has been added as a part of SFDC-20480
* @group         Test
*
*/
@isTest
public with sharing class DynamicBusRuleOnIntegSnapTest {
    @testsetup
    static void setupDate(){
        
        //List <Account> customers = TestDataFactory.customers;
        Account newAccount = new Account();
        newAccount.Is_Unit_Test__c = true;
        newAccount.name = 'Test';
        newAccount.Bill_To_Contact__c = 'orderytdbtest';
        newAccount.Partner_Number__c = 1011;
        newAccount.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        insert newAccount;
        
        Account newAccount2 = new Account();
        newAccount2.Is_Unit_Test__c = true;
        newAccount2.name = 'Test2';
        newAccount2.Type = 'Partner - Reseller';
        newAccount2.Partner_Number__c = 2011;
        newAccount2.Bill_To_Contact__c = 'orderytdbtest2';
        newAccount2.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        insert newAccount2;
        
        Account newAccount3 = new Account();
        newAccount3.Is_Unit_Test__c = true;
        newAccount3.name = 'Test3';
        newAccount3.Type = 'Distributor - Core';
        newAccount3.Partner_Number__c = 3011;
        newAccount3.Bill_To_Contact__c = 'orderytdbtest3';
        newAccount3.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        insert newAccount3;
        
        Contact rec = new Contact();
        rec.LastName = 'Doe' ;
        rec.FirstName = 'JohnTest';
        rec.MailingCountry = 'United States';
        //rec.FirstName__c = 'John';
        //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
        rec.Email = 'John.Doe@test.com';
        rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        rec.AccountId = newAccount.Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';
        insert rec; 
        
        newAccount.Bill_To_Contact__c = rec.id;
        update newAccount;
        
        Opportunity oppt = new Opportunity();
        oppt.Name ='Oppty 1' ;
        oppt.AccountID = newAccount.Id;
        oppt.Bill_To_Account__c = newAccount.id;
        oppt.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt.Model_Series__c = 'API';
        oppt.StageName = 'Accepted';
        oppt.Amount = 3000;
        oppt.CloseDate = System.today();
        oppt.Primary_Contact__c = rec.id;
        // new business opportunities
        oppt.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        oppt.Bypass_Validation__c = true;
        oppt.Reseller__c = newAccount2.Id;
        oppt.Distributor__c = newAccount3.Id;
        oppt.Is_Unit_Test__c = true;
        oppt.LeadSource = 'Renewal';
        oppt.PurchaseOrderID__c = '2020';
        insert oppt; 

        Product2 product = new Product2();
        product.Name = ' Test Product ';
        product.Description='Test Product Entry 1';
        product.productCode = 'ABC';
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

        Order newOrder = new Order();
        newOrder.AccountId = newAccount.id;
        newOrder.Name = 'test order';
        //newOrder.TotalAmount = 100;
        newOrder.Status = 'Draft';
        newOrder.Quote_Business_Group__c = 'MSP';
        newOrder.SBCF_Order_Type__c = 'Renewal';
        newOrder.EffectiveDate = System.today();
        newOrder.OpportunityId = oppt.id;
        newOrder.Has_RMA_Replace__c = false; 
        newOrder.Status = 'Draft';
        newOrder.Pricebook2Id = pricebookId;
        newOrder.Bill_To_Account__c = newAccount.id;
        newOrder.Bill_To_Contact__c = rec.id;
        insert newOrder;
        //Create Case record
        Case cs = new Case();
        cs.accountId = newAccount.id;
        cs.contactId = rec.id;
        cs.recordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Web_Case').getRecordTypeId();
        cs.status = 'New';
        cs.Web_Region__c = 'APAC';
        cs.subject = 'Test Tech Support Case';
        cs.Origin = 'Phone';
        cs.Product_Family_List__c = 'Backup Server/Service';
        insert cs;
        

    }
    @isTest
    static void testMethodOrder(){
        try{
            Order order = [Select Id, Status From Order limit 1];
            Test.startTest();
            Integration_Snapshot__c snapshot = new Integration_Snapshot__c();
            snapshot.External_ID__c = 'Order' + '_' + 'SF' + '_' + 'Platform' + order.id;
            snapshot.Integration_App__c = 'Platform Event Trigger ORDER';          
            snapshot.System_Name__c = 'Salesforce';
            snapshot.Sync_Status__c = 'Success';
            snapshot.Record_ID__c =  order.id;
            snapshot.System_Record_ID__c = order.id;
            snapshot.Object_Name__c = 'Order';
            snapshot.Message_Payload__c = 'Test payload';
            insert snapshot;
            Test.stopTest();
        }Catch(Exception e){
            system.debug('Exception occurred' +e.getStackTraceString());
        }
    }
    @isTest
    static void testMethodAccount(){
        try{
            Account acc = [select id, name from Account limit 1];
            Test.startTest();
            Integration_Snapshot__c snapshot02 = new Integration_Snapshot__c();
            snapshot02.External_ID__c = 'Account' + '_' + 'SF' + '_' + 'Platform' + acc.id;
            snapshot02.Integration_App__c = 'Platform Event Trigger ACCOUNT';          
            snapshot02.System_Name__c = 'Salesforce';
            snapshot02.Sync_Status__c = 'Success';
            snapshot02.Record_ID__c =  acc.id;
            snapshot02.System_Record_ID__c = acc.id;
            snapshot02.Object_Name__c = 'Account';
            snapshot02.Message_Payload__c = 'Test payload';
            insert snapshot02;
            Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception occurred at' +e.getStackTraceString());
        }
    }
    @isTest
    static void testMethodContact(){
        try{
            Contact con = [select id, AccountID from Contact limit 1];
            Test.startTest();
            Integration_Snapshot__c snapshot03 = new Integration_Snapshot__c();
            snapshot03.External_ID__c = 'Contact' + '_' + 'SF' + '_' + 'Platform' + con.id;
            snapshot03.Integration_App__c = 'Platform Event Trigger Contact';          
            snapshot03.System_Name__c = 'Salesforce';
            snapshot03.Sync_Status__c = 'Success';
            snapshot03.Record_ID__c =  con.id;
            snapshot03.System_Record_ID__c = con.id;
            snapshot03.Object_Name__c = 'Contact';
            snapshot03.Message_Payload__c = 'Test payload';
            insert snapshot03;
            Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception occurred at' +e.getStackTraceString());
        }
    }
    @isTest
    static void testMethodOpp(){
        try{
            Opportunity opp = [select id, AccountID from Opportunity limit 1];
            Test.startTest();
            Integration_Snapshot__c snapshot04 = new Integration_Snapshot__c();
            snapshot04.External_ID__c = 'Opportunity' + '_' + 'SF' + '_' + 'Platform' + opp.id;
            snapshot04.Integration_App__c = 'Platform Event Trigger Opportunity';          
            snapshot04.System_Name__c = 'Salesforce';
            snapshot04.Sync_Status__c = 'Success';
            snapshot04.Record_ID__c =  opp.id;
            snapshot04.System_Record_ID__c = opp.id;
            snapshot04.Object_Name__c = 'Opportunity';
            snapshot04.Message_Payload__c = 'Test payload';
            insert snapshot04;
            Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception occurred at' +e.getStackTraceString());
        }
    }
    @isTest
    static void testMethodCase(){
        try{
            Case cs = [select id, AccountID from Case limit 1];
            Test.startTest();
            Integration_Snapshot__c snapshot05 = new Integration_Snapshot__c();
            snapshot05.External_ID__c = 'Case' + '_' + 'SF' + '_' + 'Platform' + cs.id;
            snapshot05.Integration_App__c = 'Platform Event Trigger CASE';          
            snapshot05.System_Name__c = 'Salesforce';
            snapshot05.Sync_Status__c = 'Success';
            snapshot05.Record_ID__c =  cs.id;
            snapshot05.System_Record_ID__c = cs.id;
            snapshot05.Object_Name__c = 'Case';
            snapshot05.Message_Payload__c = 'Test payload';
            insert snapshot05;
            Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception occurred at' +e.getStackTraceString());
        }
    }
}