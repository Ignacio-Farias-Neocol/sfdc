/****
 * Class Name: DynamicBusinessRuleResDistValOnOpTest
 * Description:
 *  Test class of the main class DynamicBusinessRuleReselDistValidateOnQt
 * 
 * @author Dilowar Hussain
 * @createdDate 19-10-2022
 *  
 *  Jira ticket: SFDC-18052
 */
@isTest
public with sharing class DynamicBusinessRuleResDistValOnQtTest {
    /**
     * TestMethod
     */
    public static List<Account> newAccount = new List<Account>();
    public static List<Account> newAccount2 = new List<Account>();
    public static List<Account> newAccount3 = new List<Account>();
    public static List<Contact> cusCon = new List<Contact>();
    public static List<Contact> distCon = new List<Contact>();
    public static List<Contact> reselCon = new List<Contact>();
    public static List<Opportunity> opportunities = new List<Opportunity>();
    public static List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
    
    public static void createData(){
        //Create Accounts, Reseller, Distributors
        newAccount = TestDataFactory.customers;
        newAccount2 = TestDataFactory.partnersDistributor;
        newAccount3 = TestDataFactory.partners;
        newAccount2[0].Type = 'Partner - Reseller';
        update newAccount2;
        newAccount3[0].Type = 'Distributor - Core';
        update newAccount3;
        //Create Contacts, Reseller contact, Distributor contacts
        cusCon = TestDataFactory.customerContacts;
        distCon = TestDataFactory.partnercontactsDistributor;
        reselCon = TestDataFactory.partnerContacts;
        cusCon[0].accountId = newAccount[0].id;
        update cusCon;
        distCon[0].accountId = newAccount3[0].id;
        update distCon;
        reselCon[0].accountId = newAccount2[0].id;
        update reselCon;
        //Create opportunities
        opportunities = TestDataFactory.opportunities;
        opportunities[0].AccountID = newAccount[0].id;
        opportunities[0].Bill_To_Account__c = newAccount2[0].id;
        opportunities[0].Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        opportunities[0].Model_Series__c = 'API';
        opportunities[0].StageName = 'Validation';
        opportunities[0].Amount = 3000;
        opportunities[0].CloseDate = System.today();
        opportunities[0].Primary_Contact__c = cusCon[0].id;
        opportunities[0].LeadSource = 'Renewal';
        opportunities[0].PurchaseOrderID__c = '2020';
        opportunities[0].Distributor__c = newAccount3[0].id;
        opportunities[0].Reseller__c = newAccount2[0].id;
        opportunities[0].Reseller_Contact__c = reselCon[0].id;
        opportunities[0].Reseller_Contact__c = reselCon[0].id;
        update opportunities;

        //Create quotes
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = opportunities[0].id;
        quote.SBQQ__Distributor__c =  newAccount3[0].id;
        quote.SBCF_Reseller__c = newAccount2[0].id;
        quote.SBCF_Distributor_Contact__c = distCon[0].id;
        quote.SBCF_Reseller_Contact__c = reselCon[0].id;
        quotes.add(quote);
        system.debug('quotes before insert is:' +quotes);
        insert quotes;
        system.debug('quotes after insert is:' +quotes);
    }
    public testMethod static void testValidateQtEmptyCon(){
        try{
            Test.startTest();
            createData();
            List<SBQQ__Quote__c> lstQuoteUpdate = new List<SBQQ__Quote__c>();
            //List<SBQQ__Quote__c> lstQuote = [select id, SBQQ__Distributor__c, SBCF_Distributor_Contact__c, SBCF_Reseller__c, SBCF_Reseller_Contact__c from SBQQ__Quote__c where id = :quotes[0].id];
            for(SBQQ__Quote__c qt : quotes){
                qt.SBQQ__Distributor__c = newAccount3[0].id;
                qt.SBCF_Reseller__c = newAccount2[0].id;
                qt.SBCF_Distributor_Contact__c = NULL;
                qt.SBCF_Reseller_Contact__c = NULL;
                lstQuoteUpdate.add(qt);
            }
            system.debug('lstQuoteUpdate is:' +lstQuoteUpdate);
            if(!lstQuoteUpdate.isEmpty()){
                 DynamicBusinessRuleReselDistValidateOnQt qt = new DynamicBusinessRuleReselDistValidateOnQt();
                 DynamicBusinessRuleReselDistValidateOnQt.avoidRecurr = FALSE;
                 qt.processRecords(NULL, NULL, lstQuoteUpdate, NULL, NULL, 'Update');
            }
            Test.stopTest();
        }Catch(Exception e){
            system.debug('Exception'+e.getMessage()+'occurred at' +e.getStackTraceString());
        }
    }
    public testMethod static void testValidateQtEmptyAccount(){
        try{
            Test.startTest();
            createData();
            List<SBQQ__Quote__c> lstQuoteUpdate = new List<SBQQ__Quote__c>();
            //List<SBQQ__Quote__c> lstQuote = [select id, SBQQ__Distributor__c, SBCF_Distributor_Contact__c, SBCF_Reseller__c, SBCF_Reseller_Contact__c from SBQQ__Quote__c where id = :quotes[0].id];
            for(SBQQ__Quote__c qt : quotes){
                qt.SBQQ__Distributor__c = NULL;
                qt.SBCF_Reseller__c = NULL;
                qt.SBCF_Distributor_Contact__c = distCon[0].id;
                qt.SBCF_Reseller_Contact__c = reselCon[0].id;
                lstQuoteUpdate.add(qt);
            }
            system.debug('lstQuoteUpdate is:' +lstQuoteUpdate);
            if(!lstQuoteUpdate.isEmpty()){
                 DynamicBusinessRuleReselDistValidateOnQt qt = new DynamicBusinessRuleReselDistValidateOnQt();
                 DynamicBusinessRuleReselDistValidateOnQt.avoidRecurr = FALSE;
                 qt.processRecords(NULL, NULL, lstQuoteUpdate, NULL, NULL, 'Update');
            }
            Test.stopTest();
        }Catch(Exception e){
            system.debug('Exception'+e.getMessage()+'occurred at' +e.getStackTraceString());
        }
    }
    public testMethod static void testValidateQtMisMatch(){
        try{
            Test.startTest();
            createData();
            List<SBQQ__Quote__c> lstQuoteUpdate = new List<SBQQ__Quote__c>();
            //List<SBQQ__Quote__c> lstQuote = [select id, SBQQ__Distributor__c, SBCF_Distributor_Contact__c, SBCF_Reseller__c, SBCF_Reseller_Contact__c from SBQQ__Quote__c where id = :quotes[0].id];
            for(SBQQ__Quote__c qt : quotes){
                qt.SBQQ__Distributor__c = newAccount3[0].id;
                qt.SBCF_Reseller__c =  newAccount2[0].id;
                qt.SBCF_Distributor_Contact__c = reselCon[0].id;
                qt.SBCF_Reseller_Contact__c = distCon[0].id;
                lstQuoteUpdate.add(qt);
            }
            system.debug('lstQuoteUpdate is:' +lstQuoteUpdate);
            if(!lstQuoteUpdate.isEmpty()){
                DynamicBusinessRuleReselDistValidateOnQt.avoidRecurr = FALSE; 
                DynamicBusinessRuleReselDistValidateOnQt qt = new DynamicBusinessRuleReselDistValidateOnQt();
                 qt.processRecords(NULL, NULL, lstQuoteUpdate, NULL, NULL, 'Update');
            }
            Test.stopTest();
        }Catch(Exception e){
            system.debug('Exception'+e.getMessage()+'occurred at' +e.getStackTraceString());
        }
    }
}