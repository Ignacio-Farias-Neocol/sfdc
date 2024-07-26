@isTest
public with sharing class DPLCheckHelperTest {

    @testSetup
    static void setup() {

    // to do: add setup on data
    }


    @isTest static void unitTest() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        List <Compliance_Log__c> logs = TestDataFactory.complianceLogs;
        TriggerHandler.clearAllBypasses();
        

        DynamicBusinessRuleDPLStatus s = new DynamicBusinessRuleDPLStatus();
        s.processRecords(null, null ,  logs, '', '', ''); // DPLCheckHelper.updateStatusSuspect(logs);
        

    }
    
     @isTest
    static void unitTest02(){
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
        rec.MailingCountryCode = 'US';
        insert rec;
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
        
        Test.startTest();
        Case caseRecord = new Case();
        
        caseRecord.Origin = 'Web';
        caseRecord.ContactId = rec.Id;
      //   Case caseRecord = new Case();
        caseRecord.RecordTypeId = CaseModel.TECH_SUPPORT_RECORD_TYPE_ID;
        caseRecord.Description = 'Web Case 1234';
        caseRecord.Status = 'New';
        caseRecord.Web_First_Name__c = rec.FirstName;
        caseRecord.Web_Last_Name__c = rec.LastName;
        caseRecord.SuppliedEmail = rec.Email;
        caseRecord.Subject = 'Unit Test 1234';
        caseRecord.Origin = 'Web';
        caseRecord.Web_Language_of_correspondence__c = 'English';
        caseRecord.Web_Region__c = 'Americas';
        caseRecord.Offline_Support_Type__c = 'Sales'; 
        caseRecord.New_Case_Notification_Sent__c = false; 
        caseRecord.Web_Serial__c = serial.Serial_Number__c;
        caseRecord.Callback_Date_Time__c = system.now();
        caseRecord.Serial__c = serial.Id;        
        insert caseRecord;
        
       
         Test.Stoptest();
        //caseRecord.RecordTypeId = CaseModel.TECH_SUPPORT_RECORD_TYPE_ID;
        caseRecord.RecordTypeId = CaseModel.WEB_MESSAGE_RECORD_TYPE_ID;
        update caseRecord;
       
        
    
    }
    
    
     @isTest
    static void unitTest03(){
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
        rec.MailingCountryCode = 'US';
        insert rec;
        
        Opportunity oppt = new Opportunity();
        oppt.Name ='Oppty 1';
        oppt.AccountID = customer.Id;
     //   oppt.Distributor__c = partnercontacts[0].accountId;
    //    oppt.Distributor_Contact__c = partnercontacts[0].id;
    
        oppt.Distributor__c = rec.accountId;
        oppt.Distributor_Contact__c = rec.id;
     
        
         //oppt.Reseller__c =  partnercontacts[0].accountId;
         //oppt.Reseller_Contact__c = partnercontacts[0].id;
     
        
        oppt.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt.Model_Series__c = 'API';
        oppt.StageName = 'Accepted';
        oppt.Amount = 3000;
        oppt.CloseDate = System.today();
        // new business opportunities
         oppt.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
         oppt.Bypass_Validation__c = true;
        oppt.Is_Unit_Test__c = true;
        oppt.LeadSource = 'Renewal';
        oppt.BypassBusinessGroupValidation__c = True;
        
        insert oppt;
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
        rec.MailingCountryCode = 'US';
        insert rec;
        /*Map<Id,Contact> newRecordMap = new  Map<Id,Contact>();
        newRecordMap.put(rec.Id,rec);
        Map<Id,Contact> oldRecordMap = new  Map<Id,Contact>();
        DPLCheckHelper oDPL = new DPLCheckHelper();
        
        Map <Id,DPLCheckHelper.DPLRequest> dplRecordsContact = new Map <Id, DPLCheckHelper.DPLRequest>();
        oDPL.prepDPL(dplRecordsContact, newRecordMap, null, 'Contact');
        oDPL.updatePending(dplRecordsContact,  'Contact', 'Contact_Status__c', 'Last_Success_DPL__c');
        */
                
        }
        
        
}