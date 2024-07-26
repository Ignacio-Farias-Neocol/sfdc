@isTest
public class LCC_CaseSerialDisplayTest {
    
    @testsetup
    static void dataSetup(){
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active  
        List<Account> lAccounts = TestDataFactory.customers;
        
        Product2 prod = new Product2();
        prod.Name = 'PremSup Instant Replacement Support Product';
        prod.ProductCode = '1234';
        prod.is_pst_enterprise__c = true;
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
        cse.recordTypeId =   Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Offline').getRecordTypeId();
        insert cse;        
    }
    
    @isTest
    static void testMethod01(){
        List<Case> caseList = [Select Id from Case];
        List<Serial__c> serialList = [Select Id from Serial__c];
        List<Assigned_Serial__c> asList = [Select Id from Assigned_Serial__c];
        LCC_CaseSerialDisplay.getCaseSubscriptions(caseList[0].Id);
        LCC_CaseSerialDisplay.getSerial(caseList[0].Id);
        LCC_CaseSerialDisplay.getActiveSubscriptions(serialList[0].Id);
        LCC_CaseSerialDisplay.saveSubscriptions(caseList[0].Id, new List<String>{asList[0].Id}, serialList[0].Id);
    }
}