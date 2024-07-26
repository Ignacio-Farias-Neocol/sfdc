/**
* @author        Ivan Yeung/salesforce services
* @date          2019-02-15
* @description   Unit Test class for EmailMessageModel
* @group         Test
*
*/
@isTest
public with sharing class EmailMessageModelTest {
    
    @isTest static void unitTest1() {
        
        TriggerContextVariables.RUN_ACCOUNT_TRIGGER = false;
        TriggerContextVariables.RUN_CASE_TRIGGER = false; 
        EmailMessage e = new EmailMessage();
        e.FromAddress = 'mary.doe@test.com';
        e.FromName = 'Mary Doe';
        e.Status = '2';
        e.ParentId = TestDataFactory.closedSupportCases[0].id;
        e.TextBody = 'This is a test email';
        insert e;
        EmailMessageModel.ProcessEmailRequest r = new EmailMessageModel.ProcessEmailRequest();
        r.emailMessage = e;
        
        Test.startTest();
        List<EmailMessageModel.ProcessEmailRequest> requests = new  List<EmailMessageModel.ProcessEmailRequest> {r};
            List<EmailMessageModel.ProcessEmailReply> results = EmailMessageModel.handleEmailClosedCase(requests);
        Test.stopTest();
        
    }
    
    @isTest static void unitTest2() {
        
        TriggerContextVariables.RUN_ACCOUNT_TRIGGER = false;
        TriggerContextVariables.RUN_CASE_TRIGGER = false; 
        Case cse = TestDataFactory.closedSupportCases[0];
        cse.RecordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Community_Help').getRecordTypeId();
        update cse;
        
        EmailMessage e = new EmailMessage();
        e.FromAddress = 'mary.doe2@test.com';
        e.FromName = 'Mary Doe2';
        e.ParentId = cse.id;
        e.Status = '2';
        
        EmailMessageModel.ProcessEmailRequest r = new EmailMessageModel.ProcessEmailRequest();
        r.emailMessage = e;
        
        Test.startTest();
        List<EmailMessageModel.ProcessEmailRequest> requests = new  List<EmailMessageModel.ProcessEmailRequest> {r};
            List<EmailMessageModel.ProcessEmailReply> results = EmailMessageModel.handleEmailClosedCase(requests);
        Test.stopTest();
    }
    
    @isTest static void unitTest3() {
        try {
            //Test.startTest();
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
            Contact c = TestDataFactory.customerContacts[0];
            Asset asset = TestDataFactory.assets[0];
            Case cse = TestDataFactory.closedSupportCases[0];
            TriggerHandler.clearAllBypasses();                
            
            Test.setCreatedDate(cse.Id, System.now().addDays(-5));
            cse.recordTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Community_Help').getRecordTypeId();
            cse.Status = 'New';            
            update cse;
            
            
            
            EmailMessage e = new EmailMessage();
            e.FromAddress = 'mary.doe@test.com';
            e.FromName = 'Mary Doe';
            e.ParentId = cse.id;
            
            EmailMessageModel.ProcessEmailRequest r = new EmailMessageModel.ProcessEmailRequest();
            r.emailMessage = e;
            
            List<EmailMessageModel.ProcessEmailRequest> requests = new  List<EmailMessageModel.ProcessEmailRequest> {r};
                List<EmailMessageModel.ProcessEmailReply> results = EmailMessageModel.handleEmailClosedCase(requests);
            
            cse.recordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Professional_Services').getRecordTypeId();
            
            update cse; 
            List<EmailMessageModel.ProcessEmailReply> results1 = EmailMessageModel.handleEmailClosedCase(requests);
            //Test.stopTest(); 
        }Catch(Exception err) {
            System.debug('@@Error at EmailMessageModel.UnitTest3:'+err.getMessage());
        }    
    }
    
    @isTest static void testCreateCase() {
        try {
            List<String> CLONE_CASE_FIELDS = new List<String>{'ParentId', 'Status', 'Origin', 'Priority', 'Web_Region__c', 'Web_Language_of_correspondence__c','RecordTypeId',
            'Alert__c', 'Reason__c', 'preferred_Contact_Method__c', 'Serial__c', 'Client__c',
            'Computer_ID__c', 'Computer_Name__c', 'Username__c', 'Is_Asset_Verified__c', 'Is_Premium_Support__c', 'From_Address_New__c', 'First_Queue_Id__c',
            'Is_Enterprise_Account__c', 'Pick_Product_only_if_Essentials__c', 'ClosedDate', 'Case_Re_Opened__c', 'Closed_By_Process__c',
            'Product_Family_List__c', 'AccountId', 'ContactId', 'Is_Contact_Verified__c', 'Alternate_Email__c', 'Web_Serial__c',
            'Related_Contact__c', 'URL__c', 'Web_Last_Name__c', 'Web_First_Name__c', 'SuppliedPhone', 'SuppliedEmail', 'SuppliedName',
            'Related_Account__c', 'Subject', 'Description', 'Fix_Version__c', 'AssetId', 'EntitlementId', 'BusinesGroup__c', 'Source__c', 'OwnerId', 'owner.email',
            'contact.Name', 'caseNumber', 'Account.Name'};
                
            TriggerContextVariables.RUN_CASE_TRIGGER = false;    
            Case cs1 = TestDataFactory.closedSupportCases[0];
            EmailMessage em = new EmailMessage();
            em.FromAddress = 'mary.doe@test.com';
            em.FromName = 'Mary Doe';
            em.ParentId = cs1.id;
            em.TextBody = 'EmailMessageModelTest_testCreateCase';
            em.Subject = 'EmailMessageModelTest_testCreateCase';
            insert em;
            
            Map<Id,EmailMessage> mEm = new Map<Id,EmailMessage>();
            mEm.put(em.Id,em);
            
            cs1.recordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Community_Help').getRecordTypeId();
            Test.setCreatedDate(cs1.Id, System.now().addDays(-5));
            cs1.status = 'Closed';
            update cs1;
            // TriggerContextVariables.RUN_CASE_TRIGGER = true; 
            
            EmailMessageModel.ProcessEmailRequest r = new EmailMessageModel.ProcessEmailRequest();
            r.emailMessage = em;
            
            EmailMessageModel.handleEmailClosedCase(new  List<EmailMessageModel.ProcessEmailRequest> { r});
            
            
            String INTERNAL_COMMUNITY_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Community_Help').getRecordTypeId();
            Id INTERNAL_TICKET_QUEUE_ID  = [SELECT DeveloperName,Id,Name,Type FROM Group where DeveloperName='Internal_Ticket_Communities' AND Type='Queue' LIMIT 1].Id;
            
            List<Case> lCase = EmailMessageModel.createCase(CLONE_CASE_FIELDS,cs1,mEm,INTERNAL_COMMUNITY_RECORD_TYPE_ID,INTERNAL_TICKET_QUEUE_ID,true,cs1.Origin);
        }catch(Exception err) {
            System.debug('@@Error at EmailMessageModel.testCreateCase'+err.getMessage());
        }
    }
    
    @isTest static void testCreateCase02() {
        try {
            List<String> CLONE_CASE_FIELDS = new List<String>{'ParentId', 'Status', 'Origin', 'Priority', 'Web_Region__c', 'Web_Language_of_correspondence__c','RecordTypeId',
            'Alert__c', 'Reason__c', 'preferred_Contact_Method__c', 'Serial__c', 'Client__c',
            'Computer_ID__c', 'Computer_Name__c', 'Username__c', 'Is_Asset_Verified__c', 'Is_Premium_Support__c', 'From_Address_New__c', 'First_Queue_Id__c',
            'Is_Enterprise_Account__c', 'Pick_Product_only_if_Essentials__c', 'ClosedDate', 'Case_Re_Opened__c', 'Closed_By_Process__c',
            'Product_Family_List__c', 'AccountId', 'ContactId', 'Is_Contact_Verified__c', 'Alternate_Email__c', 'Web_Serial__c',
            'Related_Contact__c', 'URL__c', 'Web_Last_Name__c', 'Web_First_Name__c', 'SuppliedPhone', 'SuppliedEmail', 'SuppliedName',
            'Related_Account__c', 'Subject', 'Description', 'Fix_Version__c', 'AssetId', 'EntitlementId', 'BusinesGroup__c', 'Source__c', 'OwnerId', 'owner.email',
            'contact.Name', 'caseNumber', 'Account.Name'};
               			
            TriggerContextVariables.RUN_ACCOUNT_TRIGGER = false;
            TriggerContextVariables.RUN_CASE_TRIGGER = false;    
            Case cs1 = TestDataFactory.closedSupportCases[0];
            
            cs1.recordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();
            Test.setCreatedDate(cs1.Id, System.now().addDays(-5));
            cs1.status = 'Closed';
            cs1.Additional_Recipient_Email__c = 'tst@abc.com';
            update cs1;

            EmailMessage em = new EmailMessage();
            em.FromAddress = 'mary.doe@test.com';
            em.CcAddress = 'abc@test.com';
            em.FromName = 'Mary Doe';
            em.ParentId = cs1.id;
            em.TextBody = 'EmailMessageModelTest_testCreateCase';
            em.Subject = 'EmailMessageModelTest_testCreateCase';
            insert em;
            System.debug('####em:::: ' + JSON.serialize(em));
            Map<Id,EmailMessage> mEm = new Map<Id,EmailMessage>();
            mEm.put(em.Id,em);            
            
            EmailMessageModel.ProcessEmailRequest r = new EmailMessageModel.ProcessEmailRequest();
            r.emailMessage = em;
            
            EmailMessageModel.handleEmailClosedCase(new  List<EmailMessageModel.ProcessEmailRequest> { r});
            
            
            String INTERNAL_COMMUNITY_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();
            Id INTERNAL_TICKET_QUEUE_ID  = [SELECT DeveloperName,Id,Name,Type FROM Group where DeveloperName='Internal_Ticket_Communities' AND Type='Queue' LIMIT 1].Id;
            
            Test.startTest();
            List<Case> lCase = EmailMessageModel.createCase(CLONE_CASE_FIELDS,cs1,mEm,INTERNAL_COMMUNITY_RECORD_TYPE_ID,INTERNAL_TICKET_QUEUE_ID,true,cs1.Origin);
            List<Case> caseList = EmailMessageModel.createCaseForTS(CLONE_CASE_FIELDS, cs1, mEm, INTERNAL_COMMUNITY_RECORD_TYPE_ID);
       		Test.stopTest();
        }catch(Exception err) {
            System.debug('@@Error at EmailMessageModel.testCreateCase' + err.getMessage());
            System.debug('##cause' + err.getCause());
            System.debug('##cause' + err.getLineNumber());
            System.debug('##cause' + err.getStackTraceString()) ;
        }
    } 
    @isTest static void testCreateCase03() {
        try {
            List<String> CLONE_CASE_FIELDS = new List<String>{'ParentId', 'Status', 'Origin', 'Priority', 'Web_Region__c', 'Web_Language_of_correspondence__c','RecordTypeId',
            'Alert__c', 'Reason__c', 'preferred_Contact_Method__c', 'Serial__c', 'Client__c',
            'Computer_ID__c', 'Computer_Name__c', 'Username__c', 'Is_Asset_Verified__c', 'Is_Premium_Support__c', 'From_Address_New__c', 'First_Queue_Id__c',
            'Is_Enterprise_Account__c', 'Pick_Product_only_if_Essentials__c', 'ClosedDate', 'Case_Re_Opened__c', 'Closed_By_Process__c',
            'Product_Family_List__c', 'AccountId', 'ContactId', 'Is_Contact_Verified__c', 'Alternate_Email__c', 'Web_Serial__c',
            'Related_Contact__c', 'URL__c', 'Web_Last_Name__c', 'Web_First_Name__c', 'SuppliedPhone', 'SuppliedEmail', 'SuppliedName',
            'Related_Account__c', 'Subject', 'Description', 'Fix_Version__c', 'AssetId', 'EntitlementId', 'BusinesGroup__c', 'Source__c', 'OwnerId', 'owner.email',
            'contact.Name', 'caseNumber', 'Account.Name'};
                
                
            Case cs1 = TestDataFactory.closedSupportCases[0];
            EmailMessage em = new EmailMessage();
            em.FromAddress = 'mary.doe@test.com';
            em.FromName = 'Mary Doe';
            em.ParentId = cs1.id;
            em.TextBody = 'EmailMessageModelTest_testCreateCase';
            em.Subject = 'EmailMessageModelTest_testCreateCase';
            insert em;
            
            Test.startTest();
            EmailMessageModel.updateCaseEmail(new List<EmailMessage>{em});
            Test.stopTest();
            
        }catch(Exception err) {
            System.debug('@@Error at EmailMessageModel.testCreateCase'+err.getMessage());
        }
    }
    
    @isTest static void testCreateCase04() {
        try {
            List<String> CLONE_CASE_FIELDS = new List<String>{'ParentId', 'Status', 'Origin', 'Priority', 'Web_Region__c', 'Web_Language_of_correspondence__c','RecordTypeId',
            'Alert__c', 'Reason__c', 'preferred_Contact_Method__c', 'Serial__c', 'Client__c',
            'Computer_ID__c', 'Computer_Name__c', 'Username__c', 'Is_Asset_Verified__c', 'Is_Premium_Support__c', 'From_Address_New__c', 'First_Queue_Id__c',
            'Is_Enterprise_Account__c', 'Pick_Product_only_if_Essentials__c', 'ClosedDate', 'Case_Re_Opened__c', 'Closed_By_Process__c',
            'Product_Family_List__c', 'AccountId', 'ContactId', 'Is_Contact_Verified__c', 'Alternate_Email__c', 'Web_Serial__c',
            'Related_Contact__c', 'URL__c', 'Web_Last_Name__c', 'Web_First_Name__c', 'SuppliedPhone', 'SuppliedEmail', 'SuppliedName',
            'Related_Account__c', 'Subject', 'Description', 'Fix_Version__c', 'AssetId', 'EntitlementId', 'BusinesGroup__c', 'Source__c', 'OwnerId', 'owner.email',
            'contact.Name', 'caseNumber', 'Account.Name'};
               	
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active      
            TriggerContextVariables.RUN_ACCOUNT_TRIGGER = false;
            TriggerContextVariables.RUN_CASE_TRIGGER = false;    
            Case cs1 = TestDataFactory.closedSupportCases[0];
            
            cs1.recordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();
            Test.setCreatedDate(cs1.Id, System.now().addDays(-5));
            cs1.status = 'Closed';
            cs1.Additional_Recipient_Email__c = 'tst@abc.com';
            update cs1;

            EmailMessage em = new EmailMessage();
            em.FromAddress = 'mary.doe@test.com';
            em.CcAddress = 'abc@test.com;xyz@test.com';
            em.ToAddress = 'abc1@test.com;xyz1@test.com';
            em.FromName = 'Mary Doe';
            em.ParentId = cs1.id;
            em.TextBody = 'EmailMessageModelTest_testCreateCase';
            em.Subject = 'EmailMessageModelTest_testCreateCase';
            em.Incoming = true;
            insert em;
            System.debug('####em:::: ' + JSON.serialize(em));
            Map<Id,EmailMessage> mEm = new Map<Id,EmailMessage>();
            mEm.put(em.Id,em);            
            
            Test.startTest();
            EmailMessageModel.ProcessEmailRequest r = new EmailMessageModel.ProcessEmailRequest();
            r.emailMessage = em;
            
            EmailMessageModel.handleEmailClosedCase(new  List<EmailMessageModel.ProcessEmailRequest> { r});
            
            
            String INTERNAL_COMMUNITY_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();
            Id INTERNAL_TICKET_QUEUE_ID  = [SELECT DeveloperName,Id,Name,Type FROM Group where DeveloperName='Internal_Ticket_Communities' AND Type='Queue' LIMIT 1].Id;
            
            List<Case> lCase = EmailMessageModel.createCase(CLONE_CASE_FIELDS,cs1,mEm,INTERNAL_COMMUNITY_RECORD_TYPE_ID,INTERNAL_TICKET_QUEUE_ID,true,cs1.Origin);
            List<Case> caseList = EmailMessageModel.createCaseForTS(CLONE_CASE_FIELDS, cs1, mEm, INTERNAL_COMMUNITY_RECORD_TYPE_ID);
       		Test.stopTest();
        }catch(Exception err) {
            System.debug('@@Error at EmailMessageModel.testCreateCase' + err.getMessage());
            System.debug('##cause' + err.getCause());
            System.debug('##cause' + err.getLineNumber());
            System.debug('##cause' + err.getStackTraceString()) ;
        }
    } 
    
    
    @isTest static void unitTest01() {
        TriggerContextVariables.RUN_CASE_TRIGGER = false;   
        //Case cs1 = TestDataFactory.closedSupportCases[0];        
        EmailMessage em = new EmailMessage();
        em.FromAddress = 'mary.doe@test.com';
        em.ToAddress = 'mary.doe@test.com; abc.doe@test.com';
        em.FromName = 'Mary Doe';
        em.Incoming = true;
        em.TextBody = 'EmailMessageModelTest_testCreateCase';
        em.Subject = 'EmailMessageModelTest_testCreateCase';
        //em.ParentId = cs1.id;
        insert em;   
        
        em.TextBody = 'abc';
        update em;
    }    
}