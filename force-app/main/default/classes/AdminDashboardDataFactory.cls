/**
 *  @author Jade Global
 *  @date 2021-12-15
 *  @description  Test Data factory to create test data for Admin dashboard and Skout Merge trigger.
 */
@isTest
public class AdminDashboardDataFactory {
    
    public static Account getAccount(){
        Account partner = new Account();
        partner.Name = 'Admin Dashboard Account';
        partner.Type = 'Partner - MSP';
        partner.BillingStreet = 'Teston Road';
        partner.BillingCity = 'Vaughan';
        partner.BillingState = 'Ontario';
        partner.BillingCountry = 'Canada';
        partner.BillingCountryCode = 'CA';
        partner.BillingPostalCode = 'L4H0L7';
        partner.Terr_Theater__c = 'AMERICAS';
        partner.Is_Unit_Test__c = true;
        partner.Territory_ID__c = '1234';
        partner.Territory__c = 'ONTARIO - TERRITORY';
        partner.Terr_Region__c = 'CANADA - REGION';
        partner.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();
        Insert partner;
        return partner;
    }
    
    public static Contact getContact(){
        //Create Contact
        Contact rec = new Contact();
        rec.LastName = 'Doe';
        rec.FirstName = 'Mary';
        rec.Email = 'Mary.Doe@test.com.partner';
        rec.Contact_Status__c = 'Active';
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';
        return rec;
    }
    
    public static Opportunity getOppty(String accountId, String contactId){
        //Id pricebookId = Test.isRunningTest() ? null : [Select Id from Pricebook2 where isStandard = true limit 1].Id;
        Opportunity oppt = new Opportunity();
        oppt.Name = 'Test Admin Dashboard';
        oppt.AccountId = accountId;
        oppt.Primary_Contact__c = contactId;
        oppt.Service_Contact__c = contactId;
        oppt.StageName = 'Accepted';
        oppt.Amount = 3000;
        oppt.Pricebook2Id = Test.getStandardPricebookId();
        oppt.CloseDate = System.today()+10;
        oppt.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        oppt.LeadSource = 'Renewal';
        oppt.Bypass_Validation__c = true;
        oppt.Is_Unit_Test__c = true;
        oppt.BypassBusinessGroupValidation__c = True;
        return oppt;
    }
    
    public static SBQQ__Quote__c getQuote(Opportunity oppt){
        //Create quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = oppt.Id;
        quote.SBQQ__Account__c = oppt.AccountId;
        quote.SBQQ__Primary__c = true;
        quote.Skout_Quote__c = true;
        quote.SBQQ__StartDate__c = system.today();
        quote.SBQQ__SubscriptionTerm__c = 12; 
        Insert quote;
        return quote;
    }
    
    public static SBQQ__QuoteLineGroup__c getQuoteGroup(Id quoteId){
        SBQQ__QuoteLineGroup__c grp = new SBQQ__QuoteLineGroup__c();
        grp.Name = 'Group 1';
        grp.SBQQ__Quote__c = quoteId;
        Insert grp;
        return grp; 
    }
    
    public static List<Product2> addProducts(){
        List<Product2> skoutProducts = new List<Product2>();
        Product2 skoutprod = new Product2();
        skoutprod.Name = 'Barracuda SKOUT Email Protection';
        skoutprod.Family = 'Skout';
        skoutprod.ProductCode = 'XDR-Test';
        skoutprod.IsActive = true;
        skoutprod.CPQ_Product_Family__c = 'Skout';
        skoutProducts.add(skoutprod);
        
        Product2 skoutsensor = new Product2();
        skoutsensor.Name = 'SKOUT Small Physical Sensor';
        skoutsensor.Family = 'Skout';
        skoutsensor.ProductCode = 'XDR-Test2';
        skoutsensor.IsActive = true;
        skoutsensor.CPQ_Product_Family__c = 'Skout';
        skoutProducts.add(skoutsensor);
        Insert skoutProducts; 
        return skoutProducts;
    }
    
    public static PricebookEntry getPricebook(Id productId){
        // insert pricebook entry for the product
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = Test.getStandardPricebookId();
        standardPrice.Product2Id = productId;
        standardPrice.UnitPrice = 100;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
        return standardPrice;
    }
    
    public static OpportunityLineItem getOpportunityProd(Id productId){
        OpportunityLineItem oppLineItem = new OpportunityLineItem();
        oppLineItem.PricebookEntryId = getPricebook(productId).Id;
        oppLineItem.UnitPrice = 700;
        oppLineItem.Quantity = 5;
        return oppLineItem; 
    }
    
    public static User createUser(){
        String profile = 'System Administrator';
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = :profile].Id,
            LastName = 'last',
            Email = 'puser000@barracuda.com', // required domain for user barracuda.com, barracudamsp.com
            Username = 'puser000@barracuda.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        
        if(Test.isRunningTest()) {
            DML.save(u);
        }
        return u;
    }
    
    public static Lead createLead(){
        Lead lead = new Lead();
        lead.FirstName = 'Test';
        lead.LastName = 'Lead';
        lead.Company = 'Test Inc';
        lead.Email = 'test.lead@gmail.com';
        Insert lead;
        return lead;
    }
}