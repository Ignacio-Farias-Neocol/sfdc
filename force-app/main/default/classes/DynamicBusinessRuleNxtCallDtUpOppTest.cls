@IsTest
public with sharing class DynamicBusinessRuleNxtCallDtUpOppTest {
    public testMethod static void testNextCallDate(){
        Id renewOppRTID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal').getRecordTypeId();
        List<Account> newAccount = new List<Account>();
        List<Account> newAccount2 = new List<Account>();
        List<Account> newAccount3 = new List<Account>();
        List<Contact> cusCon = new List<Contact>();
        try{
            Product2 testProd = TestDataFactory.products[0];
            testProd.SBCF_Is_Shipped__c = TRUE;
            update testProd;
            //Opportunity testOpp = TestDataFactory.opportunities[0];
            newAccount = TestDataFactory.customers;
            cusCon = TestDataFactory.customerContacts;
            //distCon = TestDataFactory.partnercontactsDistributor;
            //reselCon = TestDataFactory.partnerContacts;
            cusCon[0].accountId = newAccount[0].id;
            update cusCon;
            Test.startTest();
            List<Opportunity> lstOpp = new List<Opportunity>();
            Opportunity opp = new Opportunity();
            opp.Name = 'Test Oppty';
            opp.CloseDate = Date.valueOf('2023-04-08');
            opp.Business_Group__c = 'Core';
            opp.recordTypeID = renewOppRTID;
            opp.AccountID = newAccount[0].id;
            //opp.Bill_To_Account__c = newAccount2[0].id;
            opp.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
            opp.Model_Series__c = 'API';
            opp.StageName = 'Validation';
            opp.Amount = 3000;
            //opp.CloseDate = System.today();
            opp.Primary_Contact__c = cusCon[0].id;
            opp.LeadSource = 'Renewal';
            opp.PurchaseOrderID__c = '2020';
            lstOpp.add(opp);
            insert lstOpp;
            Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception occurred at:' +e.getStackTraceString());
        }
    }
}