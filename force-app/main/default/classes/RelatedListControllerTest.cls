/* Test class for the below Classes
* SubscriptionRelatedListController
* OpportunityRelatedListController
* HotlistRelatedListController
*/
@isTest
public class RelatedListControllerTest {
    
    @isTest
    static void testRun(){
        SubscriptionRelatedListController.fetchRecs('50078000002HaKoAAK');
        OpportunityRelatedListController.fetchRecs('50078000002HaKoAAK');
        HotlistRelatedListController.fetchRecs('50078000002HaKoAAK');        
    }
    
    @isTest
    static void testfetchActiveRecs(){
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
        serial.Account__c = lAccounts[0].Id;
        insert serial;
        
        SBQQ__Subscription__c subs = new SBQQ__Subscription__c();
        subs.SBQQ__RootId__c = String.valueOf(serial.Id);
        subs.SBQQ__Account__c = lAccounts[0].Id;
        subs.SBCF_Serial_Number__c = serial.Serial_Number__c;
        subs.SBQQ__SubscriptionStartDate__c = Date.Today().addDays(-7); 
        subs.SBQQ__SubscriptionEndDate__c = Date.Today().addDays(7);
        subs.SBQQ__Quantity__c = 8;
        subs.SBQQ__Product__c = prod.Id; 
        insert subs;
        
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
        List<SBQQ__Subscription__c> listSub = SubscriptionRelatedListController.fetchActiveRecs(serial.Serial_Number__c,subs.SBQQ__Account__c );       
    }
}