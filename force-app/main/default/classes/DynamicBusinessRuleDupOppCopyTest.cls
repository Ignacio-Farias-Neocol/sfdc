/****
 * Class Name: DynamicBusinessRuleDuplicateOppCopy
 * Description:
 *  Test Class for the class, DynamicBusinessRuleDuplicateOppCopy
 * 
 * @author Dilowar Hussain
 * @createdDate 15-11-2022
 *  
 *  Jira ticket: SFDC-17211
 */
@isTest
public with sharing class DynamicBusinessRuleDupOppCopyTest {
    
    /**
     * CreateDate method
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
        opportunities[0].Reseller__c = newAccount2[0].id;
        opportunities[0].Reseller_Contact__c = reselCon[0].id;
        opportunities[0].Distributor__c = newAccount3[0].id;
        opportunities[0].Distributor_Contact__c = distCon[0].id;
        update opportunities;
    }
    /**
     * TestMethod
     */
    public testMethod static void testDuplicateCopy(){
        try{
            Test.startTest();
            createData();
            Map<id, Opportunity> oldMap = new Map<Id, Opportunity>();
            List<User> lstLoggedInUser = [select id from User where id = :UserInfo.getUserId()];
            List<Opportunity> duplicateOppList = new List<Opportunity>();
            Opportunity duplicateOpp = new Opportunity();
            duplicateOpp.Name = 'Test Duplicate Opp';
           	duplicateOpp.AccountID = newAccount[0].id;
            duplicateOpp.Bill_To_Account__c = newAccount2[0].id;
            duplicateOpp.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
            duplicateOpp.Model_Series__c = 'API';
            duplicateOpp.StageName = 'Validation';
            duplicateOpp.Amount = 3000;
            duplicateOpp.CloseDate = System.today();
            duplicateOpp.Primary_Contact__c = cusCon[0].id;
            duplicateOpp.LeadSource = 'Renewal';
            duplicateOpp.PurchaseOrderID__c = '2020';
            duplicateOpp.Reseller__c = newAccount2[0].id;
            duplicateOpp.Reseller_Contact__c = reselCon[0].id;
            duplicateOpp.Distributor__c = newAccount3[0].id;
            duplicateOpp.Distributor_Contact__c = distCon[0].id;
            duplicateOpp.stageName = 'Accepted';
            duplicateOpp.SE_Notes__c = '';
            duplicateOppList.add(duplicateOpp);
            insert duplicateOppList;
            
            List<Opportunity> lstOppUpdate = new List<Opportunity>();
            List<Opportunity> lstOpp = [select id, stageName, Closed_Lost_Reason__c, Duplicate_Opportunity__c,POC_Stage__c, POC_Summary__c, POC_Deployment_Type__c, Primary_SE__c, Secondary_SE__c, POC_Start_Date__c, POC_End_Date__c, Date_SE_Notes_Last_Updated__c, SE_Notes__c, Technical_Success_Criteria__c from Opportunity where id  = :opportunities[0].id];
            for(Opportunity op : lstOpp){
                op.stageName = 'Accepted';
                op.Closed_Lost_Reason__c = 'Other';
                //op.Duplicate_Opportunity__c = duplicateOpp02[0].id;
                oldMap.put(op.id, op);
            }
            System.debug('oldMap is:' +oldMap);
            for(Opportunity opp : lstOpp){
                opp.stageName = 'Closed Lost';
                opp.Closed_Lost_Reason__c = 'Duplicate';
                opp.Duplicate_Opportunity__c = duplicateOppList[0].id;
                opp.POC_Stage__c = 'POC';
                opp.POC_Summary__c = 'Active';
                opp.POC_Deployment_Type__c = 'Development';
                opp.Primary_SE__c = lstLoggedInUser[0].id;
                opp.Secondary_SE__c = lstLoggedInUser[0].id;
                opp.POC_Start_Date__c = Date.valueOf(System.today());
                opp.POC_End_Date__c = Date.valueOf(System.today()).addDays(30);
                opp.Date_SE_Notes_Last_Updated__c = Date.valueOf(System.today());
                opp.SE_Notes__c = 'Test SE Notes';
                opp.Technical_Success_Criteria__c = 'Test Tech Success';
                lstOppUpdate.add(opp);
            }
            if(!lstOppUpdate.isEmpty()){
                update lstOppUpdate;
            }
            Test.stopTest();
        }Catch(Exception e){
            system.debug('Exception'+e.getMessage()+'occurred at' +e.getStackTraceString());
        }
    }

}