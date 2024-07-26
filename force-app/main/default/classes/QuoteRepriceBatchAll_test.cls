/**
* @author Nandita 
* @date 01-06-2023
* @description 
* Test class for QuoteRepriceBatchAll
*/
@isTest
public class QuoteRepriceBatchAll_test {

        @testSetup static void setup() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        
        RepriceQuoteStart__c test = new RepriceQuoteStart__c(Name = 'EMEA');
        insert test;
        
        
        Product2 testProd = TestDataFactory.products[0];
        testProd.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testProd.SBQQ__SubscriptionTerm__c = 1;
        update testProd;
        
        Account customer = new Account();
        customer.Is_Unit_Test__c  = true;
        customer.Name = 'Customer 001';
        customer.billingStreet = '415 Mission Street';
        customer.billingCity = 'San Francisco';
        customer.BillingCountryCode = 'US';
        customer.billingStateCode = 'CA';
        customer.billingPostalCode = '94105'; 
        customer.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        customer.Status__c = 'Active';
        customer.Territory_ID__c = '123';
        customer.AccountSource = 'Renewal';
        customer.Terr_Theater__c = 'EMEA';
        customer.CurrencyIsoCode ='USD';
        INSERT customer;
        
        Contact rec = new Contact();
        rec.LastName = 'Test';
        rec.FirstName = 'TEst';
        rec.Email = 'test.test@test.com';
        rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        rec.AccountId = customer.Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';
        INSERT rec;
                
        //Opportunity
        Opportunity oppt = new Opportunity();
        oppt.Name ='Oppty 001';
        oppt.AccountID = customer.Id;
        oppt.Bill_To_Account__c = customer.Id;
        oppt.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt.Model_Series__c = 'API';
        oppt.StageName = 'Accepted';
        oppt.Amount = 3000;
        oppt.CloseDate = System.today();
        oppt.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        oppt.Bypass_Validation__c = true;
        oppt.Is_Unit_Test__c = true;
        oppt.LeadSource = 'Renewal';
        oppt.BypassBusinessGroupValidation__c = True;
        oppt.CurrencyIsoCode ='USD';
        INSERT oppt;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Opportunity2__c = oppt.Id; 
        testQuote.SBQQ__Primary__c = true;
        testQuote.SBQQ__Status__c = 'Approved';
        testQuote.SBQQ__Type__c ='Renewal';
        testQuote.Original_Contract_End_Date__c=System.today();
        testQuote.Available_on_Portal__c = true;
        insert testQuote;
        
        String accountProductCode;
        for(Upsell_Downsell_Settings__mdt setting: [SELECT DeveloperName, Setting_Value__c FROM Upsell_Downsell_Settings__mdt WHERE DeveloperName = 'Account_Products']){            //Populate product codes
            if(String.isNotBlank(setting.Setting_Value__c)){
                if(setting.DeveloperName == 'Account_Products'){
                        accountProductCode = setting.Setting_Value__c.split(',')[0];
                }   
            }
        }
        
        Product2 testAccountProduct = new Product2();
        testAccountProduct.Name = 'Account Product';
        testAccountProduct.Base_SKU__c = accountProductCode;
        testAccountProduct.ProductCode = accountProductCode; 
        insert testAccountProduct;
        System.debug('testAccountProduct...'+testAccountProduct.Id);
        
        SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c();
        qli.SBQQ__StartDate__c = System.today()-10;
        qli.SBQQ__EndDate__c = System.today()+10;
        qli.SBQQ__Quote__c = testQuote.Id;
        qli.SBCF_Serial_Number__c = 'SERIAL001';
        qli.SBQQ__Product__c = testProd.Id;
        SBQQ.TriggerControl.disable();
        insert qli;
        
        CPQ_List_Price__c cpqListPrice = new CPQ_List_Price__c();
        cpqListPrice.Product__c = testProd.Id;
        cpqListPrice.Valid_Start_Date__c = System.today();
        cpqListPrice.Valid_End_Date__c = System.today()+30;
        cpqListPrice.List_Price__c = 100;
        cpqListPrice.Region__c = 'EMEA';
        cpqListPrice.CurrencyIsoCode = 'USD';
        insert cpqListPrice;
        
        SBQQ.TriggerControl.enable();
        TriggerHandler.clearAllBypasses();      

    } 
    
    public static testMethod void testBatch() 
    {
        Test.startTest();
    
         Database.executeBatch(new QuoteRepriceAll_Batch('EMEA'));
        
        Test.stopTest();
    }
    
    public static testMethod void testSendEmail() 
    {

        Test.startTest();
    
        QuoteRepriceAll_Batch.sendEmail('Success',1);       
        
        Test.stopTest();
    }
    
    public static testMethod void testSendEmail2() 
    {

        Test.startTest();
    
        QuoteRepriceAll_Batch.sendEmail('Failure',1);       
        
        Test.stopTest();
    }
}