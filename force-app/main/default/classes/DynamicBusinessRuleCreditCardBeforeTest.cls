@isTest
public class DynamicBusinessRuleCreditCardBeforeTest {
    @testSetup static void insertTestData(){
        Id custRecTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        Account customer = new Account();
        customer.Is_Unit_Test__c  = true;
        customer.Name = 'Customer Test';
        customer.billingStreet = '415 Mission Street';
        customer.billingCity = 'San Francisco';
        customer.BillingCountryCode = 'US';
        customer.billingStateCode = 'CA';
        customer.billingPostalCode = '94105'; 
        customer.recordTypeId = custRecTypeId;
        customer.Status__c = 'Active';
        customer.Territory_ID__c = '123';
        customer.AccountSource = 'Renewal';
        customer.Terr_Theater__c = 'APAC';
        customer.CurrencyIsoCode = 'USD';
        insert customer;

    }
    
    @isTest static void updateCurrencyOnCreditCardInsertTest(){
        Account acc = [SELECT Id,CurrencyIsoCode FROM Account LIMIT 1];
        Credit_Card__c cc = new Credit_Card__c();
        cc.Account__c = acc.Id;
        cc.Card_Type__c = 'Visa';
        cc.Expiration__c = '05/25';
        cc.Last_4_of_CC__c = '1234';
        cc.CurrencyIsoCode = 'GBP';
        insert cc;
        Credit_Card__c ccard = [SELECT Id,CurrencyIsoCode FROM Credit_Card__c WHERE Id =: cc.Id];
        system.assertEquals(acc.CurrencyIsoCode, ccard.CurrencyIsoCode);
    }
    @isTest static void updateCurrencyOnCreditCardUpdateTest(){
        Account acc = [SELECT Id,CurrencyIsoCode FROM Account LIMIT 1];
        Credit_Card__c cc = new Credit_Card__c();
        cc.Account__c = acc.Id;
        cc.Card_Type__c = 'Visa';
        cc.Expiration__c = '05/25';
        cc.Last_4_of_CC__c = '1234';
        cc.CurrencyIsoCode = 'USD';
        insert cc;
        
        cc.CurrencyIsoCode = 'GBP';
        cc.Sync_to_Netsuite__c = true;
        update cc;
        
        Credit_Card__c ccard = [SELECT Id,CurrencyIsoCode FROM Credit_Card__c WHERE Id =: cc.Id];
        system.assertEquals(acc.CurrencyIsoCode, ccard.CurrencyIsoCode);
    }
}