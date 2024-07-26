@isTest
public class DynamicValidationDistiPurchaseOrderTest {

    @isTest
    public static void createDuplicatePONumberOppty(){
        String loggedInUserProfileName = [Select Id from Profile where Name ='Apollo: Custom- Customer Services'].Id;
        List<user> userForTesting = [SELECT Id FROM User WHERE ProfileId =: loggedInUserProfileName AND IsActive = True LIMIT 1];
        List<PermissionSet> permissionSetList = [SELECT ID,Name FROM PermissionSet WHERE Name LIKE 'BYPASS_ALL_VALIDATIONS_ON_OPPTY'];
        List<PermissionSet> permissionSetList2 = [SELECT ID,Name FROM PermissionSet WHERE Name LIKE 'Bypass_Process_Builders'];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = userForTesting[0].Id;
        psa.PermissionSetId = permissionSetList[0].Id;
        insert psa;
        PermissionSetAssignment psa2 = new PermissionSetAssignment();
        psa2.AssigneeId = userForTesting[0].Id;
        psa2.PermissionSetId = permissionSetList2[0].Id;
        insert psa2;
        system.runAs(userForTesting[0]){
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        // Account newAccount = TestDataFactory.customers[0]; // TestDataFactory.createAccount();

        Account newAccount = new Account();
        newAccount.Is_Unit_Test__c = true;
        newAccount.Type = 'Customer';
        newAccount.Bill_To_Contact__c = 'John Doe';
        newAccount.Status__c = 'Active';
        newAccount.name = 'Test';
        // newAccount.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        insert newAccount;
        
        Contact rec = new Contact();
        rec.LastName = 'Doe' ;
        rec.FirstName = 'JohnT';
        rec.MailingCountry = 'United States';
        //rec.FirstName__c = 'John';
        //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
        rec.Email = 'John.Doe@test.com';
        rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        rec.AccountId = newAccount.Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';
        insert rec; 
        
            
        //Opportunity opp1 = TestDataFactory.createOpportunity(newAccount);
        Opportunity oppt = new Opportunity();
        oppt.Name ='Oppty 1' ;
        oppt.AccountID = newAccount.Id;
        //oppt.SBQQ__PrimaryQuote__c = quoteList[0].id;
        /*oppt.Distributor__c = partnercontacts[0].accountId;
        oppt.Distributor_Contact__c = partnercontacts[0].id;
         oppt.Reseller__c =  partnercontacts[0].accountId;
        oppt.Reseller_Contact__c = partnercontacts[0].id;*/
        oppt.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt.Model_Series__c = 'API';
        oppt.Business_Group__c = 'Core' ;
        oppt.StageName = 'Closed Won';
        oppt.Amount = 3000;
        oppt.CloseDate = System.today();
        oppt.Primary_Contact__c = rec.id;
        // new business opportunities
         oppt.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
         oppt.Bypass_Validation__c = true;
        oppt.Is_Unit_Test__c = true;
        oppt.LeadSource = 'Renewal';
        oppt.PurchaseOrderID__c = '2020';
        insert oppt; 
            
        /*SBQQ__Quote__c newquote = new SBQQ__Quote__c();
        newquote.SBQQ__Account__c = newAccount.Id;
        newquote.SBQQ__Opportunity2__c = oppt.id;
        newquote.SBQQ__Status__c = 'Approved';
        newquote.ApprovalStatus__c = 'Approved';
        newquote.SBQQ__Primary__c = true;        
        insert newquote;*/
            
            
        //Opportunity opp2 = TestDataFactory.createOpportunity(newAccount);
        Opportunity oppt1 = new Opportunity();
        oppt1.Name ='Oppty 2' ;
        oppt1.AccountID = newAccount.Id;
        //oppt1.SBQQ__PrimaryQuote__c = quoteList[0].id;
        /*oppt.Distributor__c = partnercontacts[0].accountId;
        oppt.Distributor_Contact__c = partnercontacts[0].id;
         oppt.Reseller__c =  partnercontacts[0].accountId;
        oppt.Reseller_Contact__c = partnercontacts[0].id;*/
        oppt1.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt1.Model_Series__c = 'API';
        oppt.Business_Group__c = 'Core' ;
        oppt1.StageName = 'Closed Won';
        oppt1.Amount = 3000;
        oppt1.CloseDate = System.today();
        oppt1.Primary_Contact__c = rec.id;
        // new business opportunities
         oppt1.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
         oppt1.Bypass_Validation__c = true;
        oppt1.Is_Unit_Test__c = true;
        oppt1.LeadSource = 'Renewal';
        oppt1.PurchaseOrderID__c = '2020';
        //Opportunity[] opps = new Opportunity[]{oppt, oppt1};
        try{
            insert oppt1;
        }
        catch(Exception ex){
            system.debug('Error Caught');
        }
    }
    }
}