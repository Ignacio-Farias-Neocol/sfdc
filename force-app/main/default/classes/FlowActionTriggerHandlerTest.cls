//@isTest(SeeAllData=true)
@isTest
public class FlowActionTriggerHandlerTest {
    
    // Define test data setup method
    public static void createTestData() {
        // Create test records for the objects involved in your code
        // Ensure you have required data such as Record Types, Business Flows, Groups, etc.
        // Insert the test records into the database
    }
    
    @isTest
    static void testFlowActionTriggerHandler() {
        // Call the test data setup method to create necessary data
        createTestData();
        
        // Now, you can simulate the trigger context and call the process method
        Test.startTest();
        
        // Simulate a Trigger.new context with the relevant records
        List<sObject> testRecords = new List<sObject>();
        String webRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();
        String techRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
        
        Case cs=new Case(web_region__c='Americas',status='New',recordtypeid=webRecordTypeID);
        insert cs;
        
        cs.Origin='Web';
        
        update cs;
        
        cs.Community_Request_Close_Reason__c='Resolved own issue';
        cs.Close_Reason_Comments__c ='Other';
        update cs; 
        // Add test records to the testRecords list
        
        // Call the process method with appropriate parameters
        //  FlowActionTriggerHandler.process('ObjectName', 'Context', testRecords);
        
        Test.stopTest();
        
        // After Test.stopTest(), you can perform assertions to verify the expected behavior
        // Query and assert the results based on the expected actions in your code
    }
    
    
    @isTest
    public static void testFlowActionTriggerHandler1(){
        Test.startTest();
        
        // Simulate a Trigger.new context with the relevant records
        List<sObject> testRecords = new List<sObject>();
        String webRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();
        String techRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
        
        Case techCs=new Case(web_region__c='Japan',status='New',recordtypeid=techRecordTypeID,Product_Family_List__c='XDR');
        insert techCs;
        techCs.status='In Progress';
        techCs.IsEscalated=true;
        update techCs;
        FlowActionTriggerHandler.ExtractFieldValues(techCs,techCs ,'RecordTypeId');
        
    }
    
    @isTest
    public static void testFlowActionTriggerHandler3(){
        Test.startTest();
        List<Group> grp=new List<Group>();
        grp.add(new Group(name='SKOUT Enablement'));
        grp.add(new Group(name='TAC Customer Services'));
        insert grp;
        
        
        // Simulate a Trigger.new context with the relevant records
        List<sObject> testRecords = new List<sObject>();
        String webRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();
        String techRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
        
        Case techCs=new Case(web_region__c='Japan',status='New',recordtypeid=techRecordTypeID,Product_Family_List__c='XDR');
        insert techCs;
        techCs.status='In Progress';
        techCs.Platform__c='Salesforce';
        techCs.IsEscalated=true;
        update techCs;
        FlowActionTriggerHandler.ExtractFieldValues([select id,recordType.Name From Case where Id=:techCs.Id limit 1],techCs ,'RecordType.Name');
        
    }
    
    @isTest
    public static void Notification(){
        Test.startTest();
        List<Group> grp=new List<Group>([select id from group where name='SKOUT Enablement' limit 1]);
        
        String techRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();
        Case cs=new Case(recordtypeId=techRecordTypeID,status='New',ownerId=grp[0].Id,subject='new case created test 1');
        insert cs;
        Test.stopTest();
    }
    
    @isTest
    public static void emailAlert(){
        Test.startTest();
        
        String techRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();
        Case cs=new Case(recordtypeId=techRecordTypeID,status='New',subject='new case created test 1');
        insert cs;
        cs.L2_Approval_Status__c='Approved';
        update cs;
        Test.stopTest();
    }
    
    /*@isTest
    public static void testFlowActionTriggerHandler4(){
        Test.startTest();         
        String techRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
        Case cs=new Case(recordtypeId=techRecordTypeID, status='New', subject='new case created test 1', Missing_Serial_Number__c='34578', Product_Family_List__c='C2C-PST');
        insert cs;
        List<Group> grp=new List<Group>([select id from group where name='TAC Global Premium Support' limit 1]);
        cs.ownerId=grp[0].Id;
        update cs;
        Test.stopTest();
    }*/
    
    @isTest
    public static void testRMA_Approval_Status_Changed(){
        //Business Flow Metadata: RMA Approval Status Changed
        Test.startTest();
        //FlowActionTriggerHandler.TestBusinessFlowApiName = 'RMA_Approval_Status_Changed';
        String techRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Case_Internal_Ticket_Record_Type').getRecordTypeId();
        Case cs=new Case(RecordTypeId=techRecordTypeID, Status='New', Subject='Test Case 1', RMA_Approval_1__c=UserInfo.getUserId(), RMA_Approval_2__c=UserInfo.getUserId(), Escalation_Approver__c=UserInfo.getUserId(), OwnerId=UserInfo.getUserId());
        insert cs;
        Case ncs = [SELECT Id, Subject, L2_Approval_Status__c, Engg_Approval_Status__c  FROM Case WHERE Id=:cs.Id];
        cs.L2_Approval_Status__c = 'Approved';
        update cs;
        Test.stopTest();
    }
    
    @isTest
    public static void testAdd_Case_Team_IsNew_Internal(){
        //Business Flow Metadata: Add Case Team - IsNew - Internal
        Test.startTest();
        //FlowActionTriggerHandler.TestBusinessFlowApiName = 'Add_Case_Team_IsNew_Internal';
        String techRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Case_Internal_Ticket_Record_Type').getRecordTypeId();
        Case cs=new Case(RecordTypeId=techRecordTypeID, Status='New', Subject='Test Case 1');
        insert cs;
        Test.stopTest();
    }
    
    @isTest
    public static void testCase_Escalated_Approved(){
        //Business Flow Metadata: Case Escalated Approved
        Test.startTest();
        //FlowActionTriggerHandler.TestBusinessFlowApiName = 'Case_Escalated_Approved';
        String techRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Case_Internal_Ticket_Record_Type').getRecordTypeId();
        Case cs=new Case(RecordTypeId=techRecordTypeID, Status='New', Subject='Test Case 1');
        insert cs;
        cs.Escalation_Approved_status__c = 'Approved';
        update cs;
        Test.stopTest();
    }
    
    @isTest
    public static void test_getFieldDataType(){
        //Test for getFieldDataType method in class FlowActionTriggerHandler
        System.assertEquals('STRING', FlowActionTriggerHandler.getFieldDataType('Account', 'Name'), 'Assert Success!');
    }
    
}