@isTest
public with sharing class OrderCancelResponseEventHelperTest {
    public static testMethod void testCreateLogsForOrderSuccess(){
        try{
            List <Account> customers = TestDataFactory.customers;
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

            Asset testAsset = TestDataFactory.assets[0];
            testAsset.Appliance_Line_Type__c = 'Hardware only (pool)';
            update testAsset;             
            
            Order order = new Order();
            order.AccountId = customers[0].Id;
            order.Status = 'Draft';
            order.EffectiveDate = system.today();
            order.Pricebook2Id =  pricebookId ;
            insert order;
            
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.id;
            orderItem.Quantity = 24;
            orderItem.UnitPrice = 240;
            orderItem.Product2id = product.id;
            orderItem.PricebookEntryId = standardPrice.id;
            insert orderItem; 
            Test.StartTest();
            if(Test.isRunningTest()){
                Order_Cancellation_Response__e iEvent = new Order_Cancellation_Response__e();
                //iEvent.UUID__c = PlatformEventHelper.GUIDGenerator();
                //iEvent.Object_Name__c = 'Order';
                iEvent.OrderId__c = order.id;
                iEvent.Transaction_Id__c = '12345';
                iEvent.BOS_Cancellation_Status__c = 'TRUE';
                iEvent.NETSUITE_Cancellation_Status__c = 'TRUE';
                iEvent.BOS_Cancellation_message__c = 'Cancelled the Order in BOS';
                iEvent.NETSUITE_Cancellation_message__c = 'Cancelled the Order in NTS';
                //iEvent.Object_Payload__c = JSON.serialize(order);
                //iEvent.Event_Type__c = 'UPDATE';
                EventBus.publish(iEvent);
            }
            Test.StopTest();
        }Catch(Exception e){
            System.debug('Exception occurred at:' +e.getMessage());
        }
    }
    public static testMethod void testCreateLogsForOrderFailure(){
        try{
            List <Account> customers = TestDataFactory.customers;
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

            Asset testAsset = TestDataFactory.assets[0];
            testAsset.Appliance_Line_Type__c = 'Hardware only (pool)';
            update testAsset;             
            
            Order order = new Order();
            order.AccountId = customers[0].Id;
            order.Status = 'Draft';
            order.EffectiveDate = system.today();
            order.Pricebook2Id =  pricebookId ;
            insert order;
            
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.id;
            orderItem.Quantity = 24;
            orderItem.UnitPrice = 240;
            orderItem.Product2id = product.id;
            orderItem.PricebookEntryId = standardPrice.id;
            insert orderItem; 
            Test.StartTest();
            if(Test.isRunningTest()){
                Order_Cancellation_Response__e iEvent = new Order_Cancellation_Response__e();
                //iEvent.UUID__c = PlatformEventHelper.GUIDGenerator();
                //iEvent.Object_Name__c = 'Order';
                iEvent.OrderId__c = order.id;
                iEvent.Transaction_Id__c = '12345';
                iEvent.BOS_Cancellation_Status__c = 'FALSE';
                iEvent.NETSUITE_Cancellation_Status__c = 'FALSE';
                iEvent.BOS_Cancellation_message__c = '';
                iEvent.NETSUITE_Cancellation_message__c = '';
                //iEvent.Object_Payload__c = JSON.serialize(order);
                //iEvent.Event_Type__c = 'UPDATE';
                EventBus.publish(iEvent);
            }
            Test.StopTest();
        }Catch(Exception e){
            System.debug('Exception occurred at:' +e.getMessage());
        }
    }
}