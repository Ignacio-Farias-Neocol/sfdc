@isTest(seeAllData = FALSE)
public with sharing class G_AutoCheckApprove_RenewalQuote_BtTest {

    @testSetup static void setup() {
        /*Renewal_Quote_For_Portal_Date__mdt RenewalQDate = new Renewal_Quote_For_Portal_Date__mdt();
        RenewalQDate.DeveloperName = 'Renewal_Quotes';
        RenewalQDate.MasterLabel = 'Renewal Quotes';
        RenewalQDate.Date_with_120_days_out__c = Date.valueOf('2/8/2022');
        insert RenewalQDate;*/
        List<Renewal_Quote_For_Portal_Date__mdt> lstMetadataDate = [select id,Date_with_120_days_out__c from Renewal_Quote_For_Portal_Date__mdt];
        system.debug('lstMetadataDate is:' +lstMetadataDate);
        //Create Account Data
        Account customer = new Account();
        customer.Is_Unit_Test__c  = true;
        customer.Name = 'Customer 001';
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
        INSERT customer;
        
        //Create Contact Data
        Contact rec = new Contact();
        rec.LastName = 'Test';
        rec.FirstName = 'TEst';
        rec.Email = 'test.test@test.com';
        rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        rec.AccountId = customer.Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';
        INSERT rec;
                
        //Opportunity Data
        Opportunity oppt = new Opportunity();
        oppt.Name ='Oppty 001';
        oppt.AccountID = customer.Id;
        oppt.Bill_To_Account__c = customer.Id;
        oppt.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt.Model_Series__c = 'API';
        oppt.StageName = 'Accepted';
        oppt.Amount = 3000;
        oppt.CloseDate = System.today();
        oppt.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        oppt.Bypass_Validation__c = true;
        oppt.Is_Unit_Test__c = true;
        oppt.LeadSource = 'Renewal';
        oppt.BypassBusinessGroupValidation__c = True;
        INSERT oppt;

        Contract testContract = new Contract(AccountId = customer.Id, 
            Business_Group__c = 'Core', 
            SBQQ__RenewalOpportunity__c = oppt.Id,
            StartDate = System.Today() - 720, ContractTerm = 12);
        insert testContract;

        oppt.SBQQ__RenewedContract__c = testContract.Id;
        update oppt;
        
        //Create Quote Record
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Opportunity2__c = oppt.Id; 
        testQuote.SBQQ__Primary__c = true;
        testQuote.Available_on_Portal__c = false;
        testQuote.SBQQ__Type__c ='Renewal';
        
        //testQuote.Original_Contract_End_Date__c=System.today()+3;
        //testQuote.Available_on_Portal__c = true;
        insert testQuote;
        List<SBQQ__Quote__c> lstQuote = [select id, Available_on_Portal__c,SBQQ__Status__c, ApprovalStatus__c, SBQQ__Type__c, Created_Date__c, CreatedDate from SBQQ__Quote__c where SBQQ__Type__c ='Renewal'];
        System.debug('lstQuote is:' +lstQuote);

        Auto_Approve_Contract__c aac = new Auto_Approve_Contract__c();
        aac.Quote_Approval_Status__c = 'Pending';
        aac.Contract_ID__c = testContract.Id;

        insert aac;
    }

    @isTest
    public static void itShouldApproveQuote(){
        Test.startTest();
        Id jobId = Database.executeBatch(new G_AutoCheck_Approve_RenewalQuote_Batch(), 200);
        System.assertNotEquals(jobId, NULL);
        Test.stopTest();

        SBQQ__Quote__c quoteRecord = [SELECT Id, ApprovalStatus__c, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];

        System.assertEquals('Approved', quoteRecord.ApprovalStatus__c, 'ApprovalStatus should be Approved');
        System.assertEquals('Approved', quoteRecord.SBQQ__Status__c, 'Status should be Approved');

        Auto_Approve_Contract__c aac = [SELECT Id, Quote_Approval_Status__c FROM Auto_Approve_Contract__c LIMIT 1];

        System.assertEquals('Success', aac.Quote_Approval_Status__c, 'Auto Approve Contract record status should be Success');
    }

    @isTest
    public static void itShouldSetAutoApproveContractRecordToFailedIfNoQuote(){
        SBQQ__Quote__c quoteRecord = [SELECT Id, ApprovalStatus__c, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];
        delete quoteRecord;
        
        Test.startTest();
        Id jobId = Database.executeBatch(new G_AutoCheck_Approve_RenewalQuote_Batch(), 200);
        System.assertNotEquals(jobId, NULL);
        Test.stopTest();

        Auto_Approve_Contract__c aac = [SELECT Id, Quote_Approval_Status__c FROM Auto_Approve_Contract__c LIMIT 1];

        System.assertEquals('Failed', aac.Quote_Approval_Status__c, 'Auto Approve Contract record status should be Failed');
    }
}