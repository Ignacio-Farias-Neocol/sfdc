@isTest
public with sharing class ModificationRequestModalHelperTest {
    
    static Account customer;
    static Account partner;
    static Opportunity oppty;
    
    static {
        partner = new Account();
        Partner.Is_Unit_Test__c = true;
        partner.Name = 'Partner';
        partner.Type = 'Partner - Reseller';
        partner.Partner_Number__c = 12345;
        partner.Partner_Level__c = 'Premier';
        partner.BillingCountryCode = 'US';
        partner.BillingStateCode = 'CA';
        partner.Master_Agreement_Number__c = '1122334455';
        partner.AccountSource = 'Renewal';

        partner.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();

        insert partner;

        customer = new Account();
        customer.Is_Unit_Test__c  = true;
        customer.Name = 'Customer';
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

        oppty = new Opportunity();
        oppty.Name ='opptyy';
        oppty.AccountID = customer.Id;
       
        oppty.Reseller__c =  partner.Id;
        
        oppty.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppty.Model_Series__c = 'API';
        oppty.StageName = 'Accepted';
        oppty.Amount = 3000;
        oppty.CloseDate = System.today();
        // new business opportunities
        oppty.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        oppty.Bypass_Validation__c = true;
        oppty.Is_Unit_Test__c = true;
        oppty.LeadSource = 'Renewal';
        oppty.BypassBusinessGroupValidation__c = True;

        insert oppty;
        System.debug(oppty);
    }

    @isTest
    public static void itShouldCreateACommunityQuoteCase(){
        Map<String, String> fields = new Map<String, String>();
        System.debug(oppty);
        fields.put('isCommunityUser',String.valueOf(false));
        fields.put('Opportunity_for_SE_Cases__c', String.valueOf(oppty.Id));
        fields.put('AccountId', String.valueOf(partner.Id));
        fields.put('Related_Account__c', String.valueOf(customer.Id));
        fields.put('Subject', 'Test Subject');
        fields.put('g_Change_User_Count__c', String.valueOf(true));
        fields.put('g_Change_User_Count_Details__c', String.valueOf(25));
        fields.put('g_Modify_Subscriptions__c', String.valueOf(true));
        fields.put('g_Modify_Subscriptions_Details__c', 'Test Modify Subscriptions');

        Test.startTest();
        ModificationRequestModalHelper.createRequest(fields);
        Test.stopTest();

        List<Case> cases = [SELECT Id, Opportunity_for_SE_Cases__c, AccountId, Related_Account__c, Subject, g_Change_User_Count__c, g_Change_User_Count_Details__c, g_Co_Term_Modify_End_Date__c, g_Co_Term_Modify_End_Date_Details__c FROM Case];
        
        System.assert(cases.size() > 0, 'A Case record should have been created');
        System.assertEquals(oppty.Id, cases[0].Opportunity_for_SE_Cases__c, 'Opportunity should have been set');
        System.assertEquals(partner.Id, cases[0].AccountId, 'Account should have been set');
        System.assertEquals(customer.Id, cases[0].Related_Account__c, 'Related Account should have been set');
        System.assertEquals('Test Subject', cases[0].Subject, 'Subject should have been set');
        System.assertEquals(true, cases[0].g_Change_User_Count__c, 'Change User Count should have been set to true');
        System.assertEquals(25, cases[0].g_Change_User_Count_Details__c, 'Change User Count Detail should have been set to true');
        System.assertEquals(false, cases[0].g_Co_Term_Modify_End_Date__c, 'Co Term Modify End Date should have been set to false');
        System.assertEquals(null, cases[0].g_Co_Term_Modify_End_Date_Details__c, 'Co Term Modify End Date Details should have been set to false');
    }
}