/**
 * Added as part of #SFDC-20369.
 * 
 * Class Name: CreateOppContactRolesRenewContTest
 * Description: Test Class for the main class, CreateOppContactRolesRenewCont
 * 
 * @Author:
 * @CreateDate: 22-12-2023
 */
@isTest
public with sharing class CreateOppContactRolesRenewContTest {
    static void createData() {
        Product2 testProd = TestDataFactory.products[0];
        testProd.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testProd.SBQQ__SubscriptionTerm__c = 1;
        update testProd;
        
        Id pricebookId = Test.getStandardPricebookId();
        ID oppRecordTypeID = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = testProd.Id;
        standardPrice.UnitPrice = 1;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;   

        Account testAccount = TestDataFactory.customers[0];
        testAccount.SBQQ__RenewalPricingMethod__c = 'Same';
        testAccount.Bill_To_Contact__c = 'Test Test';
        testAccount.Bill_To_Email__c = '123@123.com';
        update testAccount;
        
        Contact rec = new Contact();
        rec.LastName = 'Doe' ;
        rec.FirstName = 'JohnTest';
        rec.MailingCountry = 'United States';
        //rec.FirstName__c = 'John';
        //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
        rec.Email = 'John.Doe@test.com';
        rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        rec.AccountId = testAccount.Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';
        insert rec; 
        
        testAccount.Bill_To_Contact__c = rec.id;
        update testAccount;
        
        Opportunity oppt = new Opportunity();
        oppt.Name ='Oppty 1' ;
        oppt.AccountID = testAccount.Id;
        oppt.Bill_To_Account__c = testAccount.id;
        oppt.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt.Model_Series__c = 'API';
        oppt.StageName = 'Accepted';
        oppt.Amount = 3000;
        oppt.CloseDate = System.today();
        oppt.Primary_Contact__c = rec.id;
        // new business opportunities
        oppt.recordTypeId = oppRecordTypeID;
        oppt.Bypass_Validation__c = true;
        //oppt.Reseller__c = newAccount2.Id;
        //oppt.Distributor__c = newAccount3.Id;
        oppt.Is_Unit_Test__c = true;
        oppt.LeadSource = 'Renewal';
        oppt.PurchaseOrderID__c = '2020';
        insert oppt; 
        
        OpportunityContactRole oppConRol02 = new OpportunityContactRole();
        oppConRol02.OpportunityId = oppt.Id;
        oppConRol02.ContactId = rec.id;
        oppConRol02.Role = 'Company Contact';
        insert oppConRol02;
        
        Opportunity testOpp = new Opportunity();
        testOpp.Name ='Oppty 2' ;
        testOpp.AccountID = testAccount.Id;
        testOpp.Bill_To_Account__c = testAccount.id;
        testOpp.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        testOpp.Model_Series__c = 'API';
        testOpp.StageName = 'Accepted';
        testOpp.Amount = 3000;
        testOpp.CloseDate = System.today();
        testOpp.Primary_Contact__c = rec.id;
        // new business opportunities
        testOpp.recordTypeId = oppRecordTypeID;
        testOpp.Bypass_Validation__c = true;
        //oppt.Reseller__c = newAccount2.Id;
        //oppt.Distributor__c = newAccount3.Id;
        testOpp.Is_Unit_Test__c = true;
        testOpp.LeadSource = 'Renewal';
        testOpp.PurchaseOrderID__c = '2020';
        insert testOpp; 
        //update testOpp;  
        
        System.debug('##testAccount:: ' + JSON.serialize(testAccount));

        Contract testContract = new Contract(AccountId = testAccount.Id, 
            Business_Group__c = 'MSP', 
            SBQQ__RenewalPricebookId__c = pricebookId, 
            SBQQ__RenewalOpportunityRecordTypeId__c = oppRecordTypeID, 
            SBQQ__RenewalOpportunityStage__c = 'Not Contacted', 
            StartDate = System.Today() - 20, ContractTerm = 12);
        insert testContract;
        testContract.Status = 'Activated';
        testContract.SBQQ__Opportunity__c = oppt.id;
        testContract.SBQQ__RenewalOpportunity__c = testOpp.id;
        //testContract.SBQQ__RenewalForecast__c = true;
        update testContract;
        
    }
    @isTest static void test_CreateOppContactRoleBatch() {
        createData();
        Test.startTest();
        CreateOppContactRolesRenewContSch s = new CreateOppContactRolesRenewContSch();
            String sch ='0 0 * * * ?'; 
            System.schedule('TestCreateOppContactRolesRenewContSched', sch, s);

            CreateOppContactRolesRenewCont b = new CreateOppContactRolesRenewCont();
            Database.executeBatch(b, 1);
        Test.stopTest();
    }
}