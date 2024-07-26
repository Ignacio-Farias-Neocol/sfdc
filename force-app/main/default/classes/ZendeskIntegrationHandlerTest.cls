@isTest
public class ZendeskIntegrationHandlerTest {

  @testSetup
    public static void createQueue(){

        Group xdrGroup = new Group(Name='XDR_Escalations', type='Queue');
			insert xdrGroup;       
          	QueuesObject testQueue = new QueueSObject(QueueID = xdrGroup.id, SobjectType = 'Case');
    		insert testQueue;
    }
 @isTest
    static void test_processLiveChatSupportCases(){
             // by pass business action
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
 			        Id xDR_Escalations_QueueId=[SELECT id From group where type='Queue' AND DeveloperName='XDR_Escalations' Limit 1].Id;
            List <Case> l = TestDataFactory.offlineCases;
            l[0].Offline_Support_Type__c = 'Support';
        	l[0].ownerId = xDR_Escalations_QueueId;
        	update l[0];
        	TriggerHandler.clearAllBypasses();
         }
    @isTest static void testChangeEventTriggerWithStopTest() {
    // Enable all Change Data Capture entities for notifications.
    Test.enableChangeDataCapture();
    
    Test.startTest();
    List <Case> l = TestDataFactory.offlineCases;
        l[0].subject='tesss';
        l[0].XDR_Ticket_Number__c='24423432';
        l[0].Escalation_Reason__c='tesss';
        update l[0];
                Test.getEventBus().deliver();

    // ...
    Test.stopTest();
        
    // The stopTest() call delivers the test change events and fires the trigger
    
    // Verify the change event trigger’s execution
    // ...
}
    @isTest
    public static void addComment(){
        List <Case> l = TestDataFactory.offlineCases;
        FeedItem fItem=new FeedItem();
        fItem.Body='test @Zendesk';
        fItem.ParentId=l[0].Id;
        insert fItem;
    }

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

        Test.startTest();
        Account customer1 = [select Id From Account limit 1];
        Contact rec1 = [SELECT Id FROM Contact Limit 1];
        
        Case caseRecord = new Case();
        caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
        caseRecord.Origin = 'Email';
        caseRecord.ContactId = rec1.Id;
        caseRecord.AccountId = customer1.id;
        caseRecord.Product_Family_List__c = 'XDR';
        caseRecord.Missing_Serial_Number__c ='55234';
        caseRecord.Pick_Product_only_if_Essentials__c = 'XDR';
        caseRecord.subject = '123';
        insert caseRecord;
        
        Group grp = [Select Id, Name, Type from Group where Name = 'XDR Escalations' and Type = 'Queue' limit 1];
        caseRecord.OwnerId = grp.Id;
        caseRecord.Engineering_Escalated_By__c=UserInfo.getUserId();
        caseRecord.XDR_Escalation_Team__c ='SOC';
        caseRecord.Escalation_Description__c ='Testing';
        caseRecord.Escalation_Reason__c = 'Testing';
        update caseRecord;
        Test.stopTest();
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
        insert rec;

        Test.startTest();
        Account customer1 = [select Id From Account limit 1];
        Contact rec1 = [SELECT Id FROM Contact Limit 1];
        
        Case caseRecord = new Case();
        caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
        caseRecord.Origin = 'Email';
        caseRecord.ContactId = rec1.Id;
        caseRecord.AccountId = customer1.id;
        caseRecord.Product_Family_List__c = 'XDR';
        caseRecord.Missing_Serial_Number__c ='55234';
        caseRecord.Pick_Product_only_if_Essentials__c = 'XDR';
        caseRecord.subject = '123';
        insert caseRecord;
        
        Group grp = [Select Id, Name, Type from Group where Name = 'XDR Escalations' and Type = 'Queue' limit 1];
        caseRecord.OwnerId = grp.Id;
        caseRecord.Engineering_Escalated_By__c=UserInfo.getUserId();
        caseRecord.XDR_Escalation_Team__c ='SOC';
		caseRecord.XDR_Ticket_Number__c ='111111';
        caseRecord.Escalation_Description__c ='Testing';
        caseRecord.Escalation_Reason__c = 'Testing';
        update caseRecord;
        Test.stopTest();
    }

    }