/****
 * Class Name: DynamicBusinessRuleResDistValOnOpTest
 * Description:
 *  Test class of the main class DynamicBusinessRuleReselDistValidateOnOp
 * 
 * @author Dilowar Hussain
 * @createdDate 19-10-2022
 *  
 *  Jira ticket: SFDC-18052
 */
@isTest
public with sharing class DynamicBusinessRuleResDistValOnOpTest {
    /**
     * TestMethod
     */
    public static List<Account> newAccount = new List<Account>();
    public static List<Account> newAccount2 = new List<Account>();
    public static List<Account> newAccount3 = new List<Account>();
    public static List<Contact> cusCon = new List<Contact>();
    public static List<Contact> distCon = new List<Contact>();
    public static List<Contact> reselCon = new List<Contact>();
    public static List <Opportunity> opportunities = new List<Opportunity>();
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
        update opportunities;
    }
    public testMethod static void testValidateReseller(){
        try{
            Test.startTest();
            createData();
            List<Opportunity> lstOppUpdate = new List<Opportunity>();
            List<Opportunity> lstOpp = [select id, AccountID, Reseller__c, Reseller_Contact__c from Opportunity where id  = :opportunities[0].id];
            for(Opportunity opp : lstOpp){
                opp.Reseller__c = newAccount3[0].id;
                opp.Reseller_Contact__c = distCon[0].id;
                opp.StageName = 'Discovery';
                lstOppUpdate.add(opp);
            }if(!lstOppUpdate.isEmpty()){
                 DynamicBusinessRuleReselDistValidateOnOp.avoidRecurr = FALSE;
                DynamicBusinessRuleReselDistValidateOnOp op = new DynamicBusinessRuleReselDistValidateOnOp();
                 op.processRecords(NULL, NULL, lstOppUpdate, NULL, NULL, 'Update');
            }
            Test.stopTest();
        }Catch(Exception e){
            system.debug('Exception'+e.getMessage()+'occurred at' +e.getStackTraceString());
        }
    }
    public testMethod static void testValidateDist(){
        try{
            Test.startTest();
            createData();
            List<Opportunity> lstOppUpdate = new List<Opportunity>();
            List<Opportunity> lstOpp = [select id, AccountID, Distributor__c, Distributor_Contact__c from Opportunity where id  = :opportunities[0].id];
            for(Opportunity opp : lstOpp){
                opp.Distributor__c = newAccount2[0].id;
                opp.Distributor_Contact__c = reselCon[0].id;
                opp.StageName = 'Discovery';
                lstOppUpdate.add(opp);
            }if(!lstOppUpdate.isEmpty()){
                 DynamicBusinessRuleReselDistValidateOnOp.avoidRecurr = FALSE;
                DynamicBusinessRuleReselDistValidateOnOp op = new DynamicBusinessRuleReselDistValidateOnOp();
                 op.processRecords(NULL, NULL, lstOppUpdate, NULL, NULL, 'Update');
            }
            Test.stopTest();
        }Catch(Exception e){
            system.debug('Exception'+e.getMessage()+'occurred at' +e.getStackTraceString());
        }
    }
    public testMethod static void testValidateEmptyCon(){
        try{
            Test.startTest();
            createData();
            List<Opportunity> lstOppUpdate = new List<Opportunity>();
            List<Opportunity> lstOpp = [select id, AccountID, Distributor__c, Distributor_Contact__c from Opportunity where id  = :opportunities[0].id];
            for(Opportunity opp : lstOpp){
                opp.Distributor__c = newAccount2[0].id;
                opp.Reseller__c = newAccount3[0].id;
                opp.Distributor_Contact__c = NULL;
                opp.Reseller_Contact__c = NULL;
                opp.StageName = 'Discovery';
                lstOppUpdate.add(opp);
            }if(!lstOppUpdate.isEmpty()){
                 DynamicBusinessRuleReselDistValidateOnOp.avoidRecurr = FALSE;
                DynamicBusinessRuleReselDistValidateOnOp op = new DynamicBusinessRuleReselDistValidateOnOp();
                 op.processRecords(NULL, NULL, lstOppUpdate, NULL, NULL, 'Update');
            }
            Test.stopTest();
        }Catch(Exception e){
            system.debug('Exception'+e.getMessage()+'occurred at' +e.getStackTraceString());
        }
    }
    public testMethod static void testValidateEmptyAccount(){
        try{
            Test.startTest();
            createData();
            List<Opportunity> lstOppUpdate = new List<Opportunity>();
            List<Opportunity> lstOpp = [select id, AccountID, Distributor__c, Distributor_Contact__c from Opportunity where id  = :opportunities[0].id];
            for(Opportunity opp : lstOpp){
                opp.Distributor__c = NULL;
                opp.Reseller__c = NULL;
                opp.Distributor_Contact__c =distCon[0].id;
                opp.Reseller_Contact__c = reselCon[0].id;
                opp.StageName = 'Discovery';
                lstOppUpdate.add(opp);
            }if(!lstOppUpdate.isEmpty()){
                 DynamicBusinessRuleReselDistValidateOnOp.avoidRecurr = FALSE;
                 DynamicBusinessRuleReselDistValidateOnOp op = new DynamicBusinessRuleReselDistValidateOnOp();
                 op.processRecords(NULL, NULL, lstOppUpdate, NULL, NULL, 'Update');
            }
            Test.stopTest();
        }Catch(Exception e){
            system.debug('Exception'+e.getMessage()+'occurred at' +e.getStackTraceString());
        }
    }
}