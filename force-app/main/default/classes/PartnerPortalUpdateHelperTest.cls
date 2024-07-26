/**
 * Created by iyeung on 1/22/19.
 * Modified by pshetty on 11/21/2019 to add test scenario for https://bugs.cudaops.com/browse/SFDC-8683
 * Modified by pshetty on 12/09/2019 to update test scenario for https://bugs.cudaops.com/browse/SFDC-8118
 */

@isTest
public class PartnerPortalUpdateHelperTest
{
    @isTest
    static void testUpdateContact()
    {
        /*
        Account acc = new Account(Name='acme', Partner_Number__c=1234, Partner_Level__c='Certified', Type='Partner - Reseller', BillingCountry='US', BillingState='CA');
        insert acc;
        Contact ct = new Contact(FirstName='acme', LastName='acme', AccountId=acc.Id, Email='acme@test.com', MailingCountry='US', MailingState='CA');
        insert ct;
        ct.FirstName = 'test';
        update ct;
        */
        // TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        Contact ct = TestDataFactory.customerContacts[0];
        // TriggerHandler.clearAllBypasses();


        Test.setMock(HttpCalloutMock.class, new PartnerPortalUpdateHelperMock());

        PartnerPortalUpdateHelper.updateContact(ct.Id);
    }
    
    @isTest
    static void testUpdateAccount()
    {
        // Account acc = new Account(Name='acme', Partner_Number__c=1234, Partner_Level__c='Certified', Type='Partner - Reseller', BillingCountry='US', BillingState='CA');
        // insert acc;

        Test.setMock(HttpCalloutMock.class, new PartnerPortalUpdateHelperMock());

        Account acc = TestDataFactory.partners[0];
        List<Id> accountIds = new List<Id>{acc.Id};
        PartnerPortalUpdateHelper.updateAccount(accountIds);
    }

    @isTest
    static void testProcessAccounts()
    {
        Test.setMock(HttpCalloutMock.class, new PartnerPortalUpdateHelperMock());

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List <Account> accounts = TestDataFactory.partners;
        TriggerHandler.clearAllBypasses();

        Test.startTest();

        Map<Id,SObject> oldRecordMap = new Map<Id, SObject>();
        for (Account a: accounts){
            oldRecordMap.put(a.Id, a);
            // Boolean  eligibleOvderride =  PartnerPortalUpdateHelper.eligibleOvderride(a, a);
        }
        PartnerPortalUpdateHelper.processRecordChanges(oldRecordMap, accounts);

        Test.stopTest();
    }

    @isTest
    static void testProcessContacts()
    {

        Test.setMock(HttpCalloutMock.class, new PartnerPortalUpdateHelperMock());

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List <Contact> contacts = TestDataFactory.customerContacts; // to do: create partner contacts
        TriggerHandler.clearAllBypasses();



        Test.startTest();

        Map<Id,SObject> oldRecordMap = new Map<Id, SObject>();
        for (Contact a: contacts){
            oldRecordMap.put(a.Id, a);
        }
        PartnerPortalUpdateHelper.processRecordChanges(oldRecordMap, contacts);

        Test.stopTest();
    }

    @isTest
    static void testProcessOpportunties()
    {

        Test.setMock(HttpCalloutMock.class, new PartnerPortalUpdateHelperMock());
       
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        Opportunity opp = TestDataFactory.createOpportunity(TestDataFactory.customers[0]);
        opp.Primary_Contact__c = TestDataFactory.customerContacts[0].Id;
        opp.LeadSource = 'Account Mapping';
        opp.StageName = 'Discovery';
        Insert opp;
        TriggerHandler.clearAllBypasses();
        
        Test.startTest();

        // Map<Id,SObject> oldRecordMap = new Map<Id, SObject>{opp.Id => opp};

        //Change the Deal Registration status
        // Opportunity newOpp = [Select Id, 
        //                              Deal_Reg_Status__c, 
        //                              Deal_Reg_Tracking_No__c, 
        //                              Deal_Reg_Exp_Date__c,
        //                              Deal_Reg_Type__c,
        //                              StageName 
        //                       From Opportunity 
        //                       Where Id = :opp.Id Limit 1];
        opp.Deal_Reg_Status__c = 'Approved';
        update opp;

        //Add Deal Reg tracking number and change status to not approved
        opp.Deal_Reg_Tracking_No__c = '123456';
        opp.Deal_Reg_Status__c = 'Not Approved';
        update opp;

        //Change the Deal Reg Exp date
        opp.Deal_Reg_Exp_Date__c = Date.Today();
        update opp;

        //Change Deal Reg type
        opp.Deal_Reg_Type__c = 'Design In';
        update opp;

        Test.stopTest();

    }

   /** SFDC 8683 - Adding a scenario to test that deal reg web call is made when deal reg status in hotlist changes */
    @isTest
    static void test_ShouldSendDealRegForHotList()
    {

        Test.setMock(HttpCalloutMock.class, new PartnerPortalUpdateHelperMock());
                
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List<Hot_List__c> hotlists = TestDataFactory.hotlists;
        TriggerHandler.clearAllBypasses();

        Test.startTest();

        //Get the first Hot List
        Hot_List__c hl = hotlists[0];
          
        //Update the Deal_Reg_Status to approved
        hl.Deal_Reg_Status__c = 'Approved';
        update hl;

        Test.stopTest();

    }

    /** SFDC 9016 - Adding a scenario to test that deal reg web call is not made when certain conditions are not met
        For this scenario we are creating an Opportunity with 'Closed Won' stage. 
        This should prevent the deal reg being called, but Account sync info should be called.
        SFDC-8118: Updating test class based on changes made for Reseller and Distributor Accounts
     */
    @isTest
    static void test_ShouldSendAccountSync()
    {

        Test.setMock(HttpCalloutMock.class, new BOSAccountUpdateCalloutMock());


        //Get a partner account and clone it to create a distributor account
        Account resellerAccount = TestDataFactory.partners[0];
        Account distributorAccount = resellerAccount.clone();
        distributorAccount.Type = 'Distributor - Core';
        insert distributorAccount;

        //Get partner contact and clone it to create a distributor contact
        Contact resellerContact = TestDataFactory.partnerContacts[0];
        Contact distributorContact = resellerContact.clone();
        distributorContact.AccountId = distributorAccount.Id;
        distributorContact.FirstName = 'Sync';
        distributorContact.LastName = 'Test';
        distributorContact.email = 'testaccountsync@test.tst';
        insert distributorContact;        
                
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        Account acct = TestDataFactory.customers[0];
        Opportunity opp = TestDataFactory.createOpportunity(acct);

        //Change the Distributor account
        opp.Distributor__c = distributorAccount.Id;
        opp.Distributor_Contact__c = distributorContact.Id;        
        Insert opp;
        TriggerHandler.clearAllBypasses();

        Test.startTest();
        //Add the opp to oldRecordMap
        Map<Id,SObject> oldRecordMap = new Map<Id, SObject>{opp.Id => opp};

        //Change the stage
        Opportunity newOpp = [Select Id, 
                                     Deal_Reg_Status__c, 
                                     Deal_Reg_Tracking_No__c, 
                                     Deal_Reg_Exp_Date__c,
                                     Deal_Reg_Type__c,
                                     StageName 
                              From Opportunity 
                              Where Id = :opp.Id Limit 1];
        newOpp.StageName = 'Closed Won';

        //Call the PartnerPortalUpdateHelper method to process records
        PartnerPortalUpdateHelper.processRecordChanges(oldRecordMap, new List<Opportunity>{newOpp});

        Test.stopTest();

       //Fetch the updated Accounts
        List<Account> updatedAccounts = [SELECT Id, 
                                                BOS_Account_Id__c, 
                                                Shared_Partner_Account__c 
                                         FROM Account 
                                         WHERE Id in (:opp.Reseller__c, :opp.Distributor__c)];

        //Assert
        System.assert(updatedAccounts!=null && !updatedAccounts.isEmpty());
        //Check updated Account Numbers
        for(Account updatedAccount: updatedAccounts){
            System.assertEquals('12345678', updatedAccount.BOS_Account_Id__c);
            System.assert(updatedAccount.Shared_Partner_Account__c);
        }


    }

}