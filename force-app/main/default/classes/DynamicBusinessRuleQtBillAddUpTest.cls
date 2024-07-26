/**
* Test Class for DynamicBusinessRuleQtBillAddressUpdate
* 
* @author Dilowar
*/
@isTest
public with sharing class DynamicBusinessRuleQtBillAddUpTest {
    /**
* Setup Method
*/
    @testSetup static void setup() {
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        List <Account> customers = TestDataFactory.customers;
        List <Account> newAccount2= TestDataFactory.partnersDistributor;
        newAccount2[0].Type = 'Partner - Reseller';
        update newAccount2;
        List<Contact> reselCon = TestDataFactory.partnerContacts;
        reselCon[0].accountId = newAccount2[0].id;
        update reselCon;
        List <Opportunity> opportunities = TestDataFactory.opportunities;
        TriggerHandler.clearAllBypasses();
        
        opportunities[0].Bill_To_Account__c = customers[0].Id;
        update opportunities[0];
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opportunities[0].Id, SBQQ__Primary__c = false);
        testQuote.SBCF_Bill_To_Account__c = customers[0].Id;
        testQuote.SBCF_Reseller__c = newAccount2[0].id;
        testQuote.SBCF_Reseller_Contact__c = reselCon[0].id;
        insert testQuote;
    }
    /**
* Test Method
*/
    @IsTest
    static  void testPopBillAddPostAccChange() {
        List<Opportunity> testOpps = [Select ID From Opportunity];
        List<SBQQ__Quote__c> testQuotes = [Select ID, SBQQ__PaymentTerms__c, ApprovalStatus__c, SBQQ__Status__c, SBQQ__Opportunity2__c From SBQQ__Quote__c];
        List<Account> newAccount3 = [Select Id From Account where type!='Partner - Reseller'];
        newAccount3[0].Type = 'Distributor - Core';
        update newAccount3;
        Contact rec = new Contact();
        rec.LastName = 'Sonal Test';
        rec.FirstName = 'Mary';
        rec.Email = 'Sonaltest@test.com.Distributor';
        rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';
        rec.accountId = newAccount3[0].id;
        insert rec;
        
        Test.startTest();
        testQuotes[0].SBQQ__PaymentTerms__c = 'Net 90';
        testQuotes[0].SBQQ__Distributor__c =  newAccount3[0].id;
        testQuotes[0].SBCF_Distributor_Contact__c = rec.id;
        testQuotes[0].SBCF_Bill_To_Account__c = newAccount3[0].id;
        update testQuotes[0];
        
        testQuotes[0].ApprovalStatus__c = 'Approved';
        update testQuotes[0];
        Test.stopTest();
    }
}