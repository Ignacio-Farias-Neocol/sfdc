/****
 * Class Name: DynamicValChurnTypeReasonOpptyTest
 * Description:
 * Test class of the below main classes 
 *      DynamicValChurnTypeOpptyCheck
 *      DynamicValChurnReasonOpptyCheck
 * 
 * @author Dilowar Hussain
 * @createdDate 26-06-2023
 *  
 *  Jira ticket: SFDC-19089
 */
@isTest (seeAllData = false)
public with sharing class DynamicValChurnTypeReasonOpptyTest {
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
        cusCon = TestDataFactory.customerContacts;
        cusCon[0].accountId = newAccount[0].id;
        update cusCon;
        // Create a unique UserName
        String uniqueUserName = 'user' + DateTime.now().getTime() + '@test.com';

        String profileName = 'Apollo: Custom- Renewals Profile';
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName];

        String roleName = 'MSP - PSM - Growth - AMERICAS';
        UserRole r = [SELECT Id FROM UserRole WHERE Name = :roleName];
        // Create a User object that uses that Profile
        User u = new User(
            UserName = uniqueUserName,
            ProfileId = p.Id,
            UserRoleId = r.id,
            Alias = 'standt',
            Email = 'user@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        System.debug('User is: ' +u);

        opportunities = TestDataFactory.opportunities;
        //opportunities[0].Bill_To_Account__c = newAccount2[0].id;
        //opportunities[0].Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        //opportunities[0].Model_Series__c = 'API';
        
        update opportunities;
    }
   
    public testMethod static void testChurnReasonOppty(){
        try{
            Test.startTest();
            createData();
            List<Opportunity> lstOppUpdate = new List<Opportunity>();
            List<Opportunity> lstOpp = [select id, AccountID, Business_Group__c, Churn_Type__c, StageName from Opportunity where id  = :opportunities[0].id];
            for(Opportunity opp : lstOpp){
                opp.AccountID = newAccount[0].id;
                opp.StageName = 'Order in Process';
                opp.Amount = 3000;
                opp.CloseDate = System.today();
                opp.Primary_Contact__c = cusCon[0].id;
                opp.LeadSource = 'Renewal';
                opp.PurchaseOrderID__c = '2020';
                opp.Business_Group__c = 'MSP';
                opp.Churn_Type__c = 'Downgrade';
                opp.Churn_Reason__c = NULL;
                lstOppUpdate.add(opp);
            }if(!lstOppUpdate.isEmpty()){
                update lstOppUpdate;
            }
            Test.stopTest();
        }Catch(Exception e){
            system.debug('Exception'+e.getMessage()+'occurred at' +e.getStackTraceString());
        }
    }
    public testMethod static void testChurnTypeOppty(){
        try{
            Test.startTest();
            createData();
            List<Opportunity> lstOppUpdate = new List<Opportunity>();
            List<Opportunity> lstOpp = [select id, AccountID, Business_Group__c, Churn_Type__c, StageName from Opportunity where id  = :opportunities[0].id];
            for(Opportunity opp : lstOpp){
                opp.AccountID = newAccount[0].id;
                opp.StageName = 'Order in Process';
                opp.Amount = 3000;
                opp.CloseDate = System.today();
                opp.Primary_Contact__c = cusCon[0].id;
                opp.LeadSource = 'Renewal';
                opp.PurchaseOrderID__c = '2020';
                opp.Business_Group__c = 'MSP';
                opp.Churn_Type__c = NULL;
                //opp.Churn_Reason__c = NULL;
                lstOppUpdate.add(opp);
            }if(!lstOppUpdate.isEmpty()){
                update lstOppUpdate;
            }
            Test.stopTest();
        }Catch(Exception e){
            system.debug('Exception'+e.getMessage()+'occurred at' +e.getStackTraceString());
        }
    }
}