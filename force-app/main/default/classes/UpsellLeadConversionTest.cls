@isTest
public class UpsellLeadConversionTest {
    @isTest
    static void testfetchContracts(){
        Lead postMQLLead = new Lead();
        postMQLLead.Company = 'TEST CO';
        postMQLLead.FirstName = 'Larry';
        postMQLLead.LastName = 'Smith';
        postMQLLead.Email = 'larry.smith@test.com';
        postMQLLead.LeadSource = 'Unknown';
        //postMQLLead.status = 'MQL'; do not set directly here - will use default value
        postMQLLead.Business_Group__c = 'Core';
        insert postMQLLead;
        
        Account partner = new Account();
        Partner.Is_Unit_Test__c = true;
        partner.Name = 'Partner';
        partner.Partner_Number__c = 12345;
        partner.Partner_Level__c = 'Premier';
        partner.Type = 'Partner - Reseller';
        partner.BillingCountryCode = 'US';
        partner.BillingStateCode = 'CA';
        partner.Master_Agreement_Number__c = '1122334455';
        partner.AccountSource = 'Renewal';
        insert partner;
        
        Opportunity oppt = new Opportunity();
        oppt.Name ='Oppty';
        oppt.AccountID = partner.Id;
        oppt.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt.Model_Series__c = 'API';
        oppt.StageName = 'Accepted';
        oppt.Amount = 3000;
        oppt.CloseDate = System.today();
        insert oppt;
        
        Hot_List__c testHotList=new Hot_List__c();
        testHotList.Account__c = partner.id;
        testHotList.Converted_Opportunity__c = oppt.id;
        testHotList.Lead__c = postMQLLead.id;
        insert testHotList;
        
        
        List<Id> leadIdList = New List<Id>();
        leadIdList.add(postMQLLead.id);
        UpsellLeadConversion.fetchContracts(leadIdList);
    }
}