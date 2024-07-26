@isTest
public class CaseModelBeforeInsertHelperTest {
	
    @isTest
    static void unitTest01(){
        Account customer = new Account();
        customer.Is_Unit_Test__c  = true;
        customer.Name = 'Customer' + ' ' + 'abc';
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
        
        Contact rec = new Contact();
        rec.LastName = 'Doe' + ' ' + 'abc';
        rec.FirstName = 'John';
        //rec.FirstName__c = 'John';
        //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
        rec.Email = 'John.Doe@test.com';
        rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        rec.AccountId = customer.Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';  
        rec.Use_Alt_Email_for_Case__c = true;
        rec.Alternative_Email__c = 'abc@test.com';
        insert rec;
        
        Case caseRecord = new Case();
        caseRecord.RecordTypeId = CaseModel.WEB_MESSAGE_RECORD_TYPE_ID;
        caseRecord.Origin = 'Web';
        caseRecord.ContactId = rec.Id;
        insert caseRecord;
        
    }
    
    @isTest
    static void unitTest02(){
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active  
        List<Account> lAccounts = TestDataFactory.customers;
        
        Product2 prod = new Product2();
        prod.Name = 'PremSup Instant Replacement Support Product';
        prod.ProductCode = '1234';
        prod.is_pst_enterprise__c = true;
        prod.CPQ_Product_Family__c = 'Essentials';
        prod.Base_SKU__c = 'abc';
        insert prod;
        
        Serial__c serial = new Serial__c();
        serial.Activation_Date__c = Date.today();
        serial.Serial_Number__c = String.valueOf(Math.random() * 10000000).left(6);
        serial.Status__c = 'Active';
        serial.Base_Product_SKU__c = '1234';
        serial.Product__c = prod.Id;
        insert serial;
        
        SBQQ__Subscription__c subs = new SBQQ__Subscription__c();
        subs.SBQQ__RootId__c = String.valueOf(serial.Id);
        subs.SBQQ__Account__c = lAccounts[0].Id;
        subs.SBQQ__SubscriptionStartDate__c = Date.Today().addDays(-7); 
        subs.SBQQ__SubscriptionEndDate__c = Date.Today().addDays(7);
        subs.SBQQ__Quantity__c = 8;
        subs.SBQQ__Product__c = prod.Id; 
        insert subs;
        
        Asset asset = new Asset();
        asset.Name = 'test_Instant Replacement_Support_Product';
        asset.AccountId = lAccounts[0].Id;
        asset.Product2Id = prod.Id;
        asset.SerialNumber = serial.Serial_Number__c;
        asset.BNCPQ_Serial__c = serial.Id;
        insert asset;
        
        Assigned_Serial__c assignedSerial = new Assigned_Serial__c();
        //assignedSerial.Asset__c = asset.id;
        assignedSerial.Serial__c = serial.Id;
        assignedSerial.Status__c = 'Active';
        insert assignedSerial;
        
        Contact con = new Contact();
        con.LastName = 'Doe' + ' ' + '1234';
        con.FirstName = 'John';
        con.Email = 'John.Doe@test.com';
        con.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        con.AccountId = lAccounts[0].Id;
        con.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        con.LeadSource = 'Renewal';
        insert con;
        
        Case cse = new Case();
        cse.RecordTypeId = CaseModel.TECH_SUPPORT_RECORD_TYPE_ID;
        cse.Description = 'Web Case 1234';
        cse.Status = 'New';
        cse.Web_First_Name__c = con.FirstName;
        cse.Web_Last_Name__c = con.LastName;
        cse.SuppliedEmail = con.Email;
        cse.Subject = 'Unit Test 1234';
        cse.Origin = 'Web';
        cse.Web_Language_of_correspondence__c = 'English';
        cse.Web_Region__c = 'Americas';
        cse.Offline_Support_Type__c = 'Sales'; 
        cse.New_Case_Notification_Sent__c = false; 
        cse.Web_Serial__c = serial.Serial_Number__c;
        cse.Callback_Date_Time__c = system.now();
        cse.Serial__c = serial.Id;        
        insert cse;        
    }
    
    @isTest
    static void unitTest03(){
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active  
        List<Account> lAccounts = TestDataFactory.customers;
        
        Product2 prod = new Product2();
        prod.Name = 'PremSup Instant Replacement Support Product';
        prod.ProductCode = '1234';
        prod.is_pst_enterprise__c = true;
        prod.CPQ_Product_Family__c = 'Essentials';
        prod.Base_SKU__c = 'abc';
        insert prod;
        
        Serial__c serial = new Serial__c();
        serial.Activation_Date__c = Date.today();
        serial.Serial_Number__c = String.valueOf(Math.random() * 10000000).left(6);
        serial.Status__c = 'Active';
        serial.Product__c = prod.Id;
        insert serial;
        
        SBQQ__Subscription__c subs = new SBQQ__Subscription__c();
        subs.SBQQ__RootId__c = String.valueOf(serial.Id);
        subs.SBQQ__Account__c = lAccounts[0].Id;
        subs.SBQQ__SubscriptionStartDate__c = Date.Today().addDays(-7); 
        subs.SBQQ__SubscriptionEndDate__c = Date.Today().addDays(7);
        subs.SBQQ__Quantity__c = 8;
        subs.SBQQ__Product__c = prod.Id; 
        insert subs;
        
        Asset asset = new Asset();
        asset.Name = 'test_Instant Replacement_Support_Product';
        asset.AccountId = lAccounts[0].Id;
        asset.Product2Id = prod.Id;
        asset.SerialNumber = serial.Serial_Number__c;
        asset.BNCPQ_Serial__c = serial.Id;
        insert asset;
        
        Assigned_Serial__c assignedSerial = new Assigned_Serial__c();
        //assignedSerial.Asset__c = asset.id;
        assignedSerial.Serial__c = serial.Id;
        assignedSerial.Status__c = 'Active';
        insert assignedSerial;
        
        Contact con = new Contact();
        con.LastName = 'Doe' + ' ' + '1234';
        con.FirstName = 'John';
        con.Email = 'John.Doe@test.com';
        con.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        con.AccountId = lAccounts[0].Id;
        con.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        con.LeadSource = 'Renewal';
        insert con;
        
        Case cse = new Case();
        cse.RecordTypeId = CaseModel.TECH_SUPPORT_RECORD_TYPE_ID;
        cse.Description = 'Web Case 1234';
        cse.Status = 'New';
        cse.Web_First_Name__c = con.FirstName;
        cse.Web_Last_Name__c = con.LastName;
        cse.SuppliedEmail = con.Email;
        cse.Subject = 'Unit Test 1234';
        cse.Origin = 'Web';
        cse.Web_Language_of_correspondence__c = 'English';
        cse.Web_Region__c = 'Americas';
        cse.Offline_Support_Type__c = 'Sales'; 
        cse.New_Case_Notification_Sent__c = false; 
        cse.Web_Serial__c = serial.Serial_Number__c;
        cse.Callback_Date_Time__c = system.now();
        cse.Serial__c = serial.Id;        
        insert cse;        
    }      
    
     @isTest
    static void unitTest04(){
        Account customer = new Account();
        customer.Is_Unit_Test__c  = true;
        customer.Name = 'Customer' + ' ' + 'abc';
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

        Opportunity oppty = TestDataFactory.createEmptyOpportunity(customer);
        Insert oppty;
        
        Test.startTest();
            Case caseRecord2 = new Case();
            caseRecord2.RecordTypeId = CaseModel.REQUEST_QUOTE_RECORD_TYPE_ID;
            caseRecord2.Opportunity_for_SE_Cases__c = oppty.Id;
            Insert caseRecord2;
        Test.stopTest();
    }
}