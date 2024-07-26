@isTest
public class DynamicBusinessRuleResetDistriOnQtTest {
	public static List<Account> newAccount = new List<Account>();
    public static List<Account> newAccount2 = new List<Account>();
    public static List<Account> newAccount3 = new List<Account>();
    public static List<Contact> cusCon = new List<Contact>();
    public static List<Contact> distCon = new List<Contact>();
    public static List<Contact> reselCon = new List<Contact>();
    public static List<Opportunity> opportunities = new List<Opportunity>();
    public static List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
    
    public testMethod static void testResetQuoteMethod(){
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
        Test.startTest();
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = opportunities[0].id;
        quote.SBQQ__Distributor__c =  newAccount3[0].id;
        quote.SBCF_Reseller__c = newAccount2[0].id;
        quote.SBCF_Distributor_Contact__c = distCon[0].id;
        quote.SBCF_Reseller_Contact__c = reselCon[0].id;
        quotes.add(quote);
        //system.debug('quotes before insert is:' +quotes);
        insert quotes;
        Test.stopTest();
        //system.debug('quotes after insert is:' +quotes);
    }
}