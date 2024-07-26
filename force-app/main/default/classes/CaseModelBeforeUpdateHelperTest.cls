@isTest
public class CaseModelBeforeUpdateHelperTest {
    @testSetup
    static void dataSetup(){
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
        insert rec;
        
        Case caseRecord = new Case();
        caseRecord.RecordTypeId = CaseModel.WEB_MESSAGE_RECORD_TYPE_ID;
        caseRecord.Origin = 'Web';
        caseRecord.ContactId = rec.Id;
        insert caseRecord;
        
    }
    
    @isTest
    static void unitTest01(){
		Account acc = [Select Id from Account limit 1];
        
        Contact rec = new Contact();
        rec.LastName = 'Sample' + ' ' + 'abc';
        rec.FirstName = 'John';
        //rec.FirstName__c = 'John';
        //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
        rec.Email = 'sample.Doe@test.com';
        rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        rec.AccountId = acc.Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';   
        insert rec;
        
        Case caseRecord = [Select Id, RecordTypeId, ContactId from Case limit 1];
        
        caseRecord.ContactId = rec.Id;
        update caseRecord;
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
        insert prod;
        
        Serial__c serial = new Serial__c();
        serial.Activation_Date__c = Date.today();
        serial.Serial_Number__c = String.valueOf(Math.random() * 10000000).left(6);
        serial.Status__c = 'Active';
        serial.Base_Product_SKU__c = '1234';
        insert serial;
        
        Test.startTest();
        Case caseRecord = [Select Id from Case limit 1];
        caseRecord.Serial__c = serial.Id;
        update caseRecord;
		Test.stopTest();    
    }
    
    @isTest
    static void unitTest03(){
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active  
        List<Account> lAccounts = TestDataFactory.customers;
        
        Product2 prod = new Product2();
        prod.Name = 'PremSup Instant Replacement Support Product';
        prod.ProductCode = '1234';
        prod.is_pst_enterprise__c = true;
        prod.CPQ_Product_Family__c = 'C2C-PST';
        insert prod;
        
        Serial__c serial = new Serial__c();
        serial.Activation_Date__c = Date.today();
        serial.Serial_Number__c = String.valueOf(Math.random() * 10000000).left(6);
        serial.Status__c = 'Active';
        serial.Base_Product_SKU__c = '1234';
        insert serial;
        
        Test.startTest();
        Case caseRecord = [Select Id from Case limit 1];
        caseRecord.Serial__c = serial.Id;
        update caseRecord;  
        Test.stopTest();
    }    
    
    @isTest
    static void unitTest04(){
        Profile prfile = [select Id,name from Profile where  name='System Administrator' limit 1];
        UserRole roleRecord = [Select Id, Name from UserRole where Name = 'Technical Support - China'];
        System.debug('###roleRecord:: ' + JSON.serialize(roleRecord));
        
        User newUser1 = new User(
            profileId = prfile.id,
            UserRoleId = roleRecord.Id,
            username = 'newUsertestt@yahoo.com' + System.currentTimeMillis(),
            email = 'pb@f.com',
            emailencodingkey = 'UTF-8',
            localesidkey = 'en_US',
            languagelocalekey = 'en_US',
            timezonesidkey = 'America/Los_Angeles',
            alias='nuser',
            lastname='lastname'
        );
        insert newUser1; 
        
        System.debug('###newUser1:: ' + JSON.serialize(newUser1));
        
        System.runAs(newUser1) {
            Test.startTest();
            Case caseRecord = [Select Id, Owner.Name from Case limit 1];
            System.debug('###caseRecord:: ' + JSON.serialize(caseRecord));
            caseRecord.OwnerId = newUser1.Id;
            try {
                update caseRecord;        
            } catch (Exception e) {
                
            }
            Test.stopTest();
        }
        
    }   
    
    @isTest
    static void unitTest05(){
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active  
        List<Account> lAccounts = TestDataFactory.customers;
        
        Product2 prod = new Product2();
        prod.Name = 'PremSup Instant Replacement Support Product';
        prod.ProductCode = '1234';
        prod.is_pst_enterprise__c = true;
        prod.CPQ_Product_Family__c = 'Essentials';
        insert prod;
        
        Serial__c serial = new Serial__c();
        serial.Activation_Date__c = Date.today();
        serial.Serial_Number__c = String.valueOf(Math.random() * 10000000).left(6);
        serial.Status__c = 'Active';
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
        
        
        Test.startTest();
        Case caseRecord = [Select Id from Case limit 1];
        caseRecord.Serial__c = serial.Id;
        update caseRecord;  
        Test.stopTest();
    } 
    
    @isTest
    static void unitTest06(){
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active              
        Case caseRecord = [Select Id from Case limit 1];
        caseRecord.OwnerId = [Select Id, Name, Type, DeveloperName from Group where Type = 'Queue' and DeveloperName = 'Internal_Ticket_Communities' limit 1].Id;
        update caseRecord; 
    }   
    
    @isTest
    static void unitTest07(){
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active              
        Case caseRecord = [Select Id from Case limit 1];
        
        caseRecord.OwnerId = [Select Id, Name, Type, DeveloperName from Group where Type = 'Queue' and DeveloperName = 'Internal_Ticket_Customer_Services' limit 1].Id;
        update caseRecord;
    }      
    
}