@isTest
public with sharing class SubscriptionProcessBuilderClassTest {
    public testMethod static void testMethod01(){
       // try{
            Product2 product = new Product2();
            product.Name = ' Test Product ';
            product.Description='Test Product Entry 1';
            product.productCode = 'ABC';
            product.isActive = true;
            insert product;
            
            Id pricebookId = Test.getStandardPricebookId();
            
            PricebookEntry standardPrice = new PricebookEntry();
            standardPrice.Pricebook2Id = pricebookId;
            standardPrice.Product2Id = product.Id;
            standardPrice.UnitPrice = 1;
            standardPrice.IsActive = true;
            standardPrice.UseStandardPrice = false;
            insert standardPrice ;


            List <Contact> contacts = TestDataFactory.customerContacts;
            List <Account> customers = TestDataFactory.customers;
            List <Account> partners = TestDataFactory.partners;
            List <Product2> products = TestDataFactory.products;
            List <Opportunity> opportunities = TestDataFactory.opportunities;
            List <SBQQ__Quote__c> quotes = TestDataFactory.quotes;
            TriggerHandler.clearAllBypasses();
            // to do : properly create a subscription, for now just need to invoke trigger
            quotes[0].SBQQ__Type__c = 'Renewal';
            update quotes;
            
            Test.startTest();
            Order order = new Order();
            order.AccountId = customers[0].Id;
            order.Status = 'Draft';
            order.EffectiveDate = system.today();
            order.Pricebook2Id =  pricebookId ;
            order.Quote_Business_Group__c = 'Barracuda MSP';
            order.PoNumber = '12345';
            insert order;
            
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.id;
            orderItem.Quantity = 24;
            orderItem.UnitPrice = 240;
            orderItem.Product2id = product.id;
            orderItem.PricebookEntryId = standardPrice.id;
            insert orderItem; 

            Contract contract = new Contract();
            contract.AccountId = opportunities[0].accountId;
            contract.SBQQ__Opportunity__c = opportunities[0].Id;
            contract.SBQQ__Quote__c = quotes[0].id;
            insert contract;

            
            List<SBQQ__Subscription__c> listsubs = new List<SBQQ__Subscription__c>();
            
            SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
            sub.SBQQ__Account__c  = opportunities[0].accountId;
            sub.SBQQ__Contract__c = contract.Id;
            sub.SBQQ__Quantity__c = 1;
            sub.SBQQ__OrderProduct__c = orderItem.id;
            // sub.SBQQ__OrderProduct__c = productss[0].Id;
            
            //listsubs.add(sub);
            insert sub;

            SBQQ__Subscription__c sub02 = new SBQQ__Subscription__c();
            sub02.SBQQ__Account__c  = opportunities[0].accountId;
            sub02.SBQQ__Contract__c = contract.Id;
            sub02.SBQQ__Quantity__c = 1;
            sub02.RBM_Price__c = 100.00;
            // sub.SBQQ__OrderProduct__c = productss[0].Id;
            //listsubs.add(sub);
            insert sub02;
            
            //insert listsubs;
            Test.stopTest();
        /*}Catch(Exception e){
            System.debug('Exception'+ e.getMessage()+'occurred at:' +e.getStackTraceString());
        }*/
    }
}