@isTest
public class VoidOrderControllerTest {
    
    @testsetup
    static void setupDate(){
        
        //List <Account> customers = TestDataFactory.customers;
        Account newAccount = new Account();
        newAccount.Is_Unit_Test__c = true;
        newAccount.name = 'Test';
        newAccount.Bill_To_Contact__c = 'orderytdbtest';
        newAccount.Partner_Number__c = 1011;
        newAccount.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        insert newAccount;
        
        Account newAccount2 = new Account();
        newAccount2.Is_Unit_Test__c = true;
        newAccount2.name = 'Test2';
        newAccount2.Type = 'Partner - Reseller';
        newAccount2.Partner_Number__c = 2011;
        newAccount2.Bill_To_Contact__c = 'orderytdbtest2';
        newAccount2.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        insert newAccount2;
        
        Account newAccount3 = new Account();
        newAccount3.Is_Unit_Test__c = true;
        newAccount3.name = 'Test3';
        newAccount3.Type = 'Distributor - Core';
        newAccount3.Partner_Number__c = 3011;
        newAccount3.Bill_To_Contact__c = 'orderytdbtest3';
        newAccount3.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        insert newAccount3;
        
        Contact rec = new Contact();
        rec.LastName = 'Doe' ;
        rec.FirstName = 'JohnTest';
        rec.MailingCountry = 'United States';
        //rec.FirstName__c = 'John';
        //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
        rec.Email = 'John.Doe@test.com';
        rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        rec.AccountId = newAccount.Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';
        insert rec; 
        
        newAccount.Bill_To_Contact__c = rec.id;
        update newAccount;
        
        Opportunity oppt = new Opportunity();
        oppt.Name ='Oppty 1' ;
        oppt.AccountID = newAccount.Id;
        oppt.Bill_To_Account__c = newAccount.id;
        oppt.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt.Model_Series__c = 'API';
        oppt.StageName = 'Accepted';
        oppt.Amount = 3000;
        oppt.CloseDate = System.today();
        oppt.Primary_Contact__c = rec.id;
        // new business opportunities
        oppt.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        oppt.Bypass_Validation__c = true;
        oppt.Reseller__c = newAccount2.Id;
        oppt.Distributor__c = newAccount3.Id;
        oppt.Is_Unit_Test__c = true;
        oppt.LeadSource = 'Renewal';
        oppt.PurchaseOrderID__c = '2020';
        insert oppt; 

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

        Order newOrder = new Order();
        newOrder.AccountId = newAccount.id;
        newOrder.Name = 'test order';
        //newOrder.TotalAmount = 100;
        newOrder.Status = 'Draft';
        newOrder.Quote_Business_Group__c = 'MSP';
        newOrder.SBCF_Order_Type__c = 'Renewal';
        newOrder.EffectiveDate = System.today();
        newOrder.OpportunityId = oppt.id;
        newOrder.Has_RMA_Replace__c = false; 
        newOrder.Status = 'Draft';
        newOrder.Pricebook2Id = pricebookId;
        newOrder.Bill_To_Account__c = newAccount.id;
        newOrder.Bill_To_Contact__c = rec.id;
        insert newOrder;

        OrderItem newOrderProduct = new OrderItem();
        newOrderProduct.SBQQ__Status__c = 'Draft';
        newOrderProduct.UnitPrice= 100;
        newOrderProduct.Quantity = 10;
        newOrderProduct.Product2Id = product.id;
        newOrderProduct.OrderId = newOrder.id;
        newOrderProduct.PricebookEntryId = standardPrice.id;
        insert newOrderProduct;
        
        newOrder.Bill_To_Contact_Email__c = 'test@barracuda.com' ;
        newOrder.BillToContactId = rec.id;
        newOrder.Ship_To_Contact__c = rec.id;
        newOrder.Ship_To_Contact_Email__c = 'test@barracuda.com';
        newOrder.BillingStreet = 'Whitefield, Bengaluru';
        newOrder.BillingCity = 'Bengaluru';
        newOrder.BillingCountry = 'India';
        newOrder.BillingCountryCode = 'IN';
        newOrder.ShippingStreet = 'Whitefield, Bengaluru';
        newOrder.ShippingCity = 'Bengaluru';
        newOrder.ShippingCountry = 'India';
        newOrder.ShippingCountryCode = 'IN';
        //newOrder.BillingState = 'KA';
        //newOrder.ShippingState = 'KA';
        newOrder.BillingPostalCode = '560066';
        newOrder.ShippingPostalCode = '560066';
        newOrder.Status = 'Placed';
        update newOrder;

        Order newOrder_02 = new Order();
        newOrder_02.AccountId = newAccount.id;
        newOrder_02.Name = 'test order';
        newOrder_02.Status = 'Draft';
        newOrder_02.Quote_Business_Group__c = 'Barracuda';
        newOrder_02.SBCF_Order_Type__c = 'Renewal';
        newOrder_02.EffectiveDate = System.today();
        newOrder_02.OpportunityId = oppt.id;
        newOrder_02.Has_RMA_Replace__c = false; 
        newOrder_02.Status = 'Draft';
        newOrder_02.Pricebook2Id = pricebookId;
        newOrder_02.Bill_To_Account__c = newAccount.id;
        newOrder_02.Bill_To_Contact__c = rec.id;
        insert newOrder_02;

        OrderItem newOrderProduct_02 = new OrderItem();
        newOrderProduct_02.SBQQ__Status__c = 'Draft';
        newOrderProduct_02.UnitPrice= 100;
        newOrderProduct_02.Quantity = 10;
        newOrderProduct_02.Product2Id = product.id;
        newOrderProduct_02.OrderId = newOrder_02.id;
        newOrderProduct_02.PricebookEntryId = standardPrice.id;
        newOrderProduct_02.SBCF_Serial_Number__c = '5678';
        insert newOrderProduct_02;
        
        newOrder_02.Bill_To_Contact_Email__c = 'test@barracuda.com' ;
        newOrder_02.BillToContactId = rec.id;
        newOrder_02.Status = 'Placed';
        update newOrder_02;
    }
    @isTest
    static void uniTestBarracudaCore(){
        try{
            Order order = [Select Id, Status From Order Where Status = 'Placed' and Quote_Business_Group__c = 'MSP' limit 1];
            Test.startTest();
            VoidOrderController.checkVoidOrderCriteria(order.Id);
            //VoidOrderController.updateOrderStatus(order.Id);
            Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    } 
    @isTest
    static void uniTestWithSerials(){
        try{
            Order order = [Select Id, Status From Order Where Status = 'Placed' and Quote_Business_Group__c = 'MSP' limit 1];
            order.Quote_Business_Group__c = 'Barracuda';
            update order;
            OrderItem odit = [select id, OrderId from OrderItem where OrderId = :order.id];
            odit.SBCF_Serial_Number__c = '5678';
            update odit;
            Test.startTest();
            VoidOrderController.checkVoidOrderCriteria(order.Id);
            //VoidOrderController.updateOrderStatus(order.Id);
            Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    } 
    @isTest
    static void uniTestDraft(){
        try{
            Order order = [Select Id, Status From Order Where Status = 'Placed' limit 1];
            system.debug('Draft Orders:' +order);
            order.status = 'Draft';
            update order;
            Test.startTest();
            VoidOrderController.checkVoidOrderCriteria(order.Id);
            //VoidOrderController.updateOrderStatus(order.Id);
            Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    } 
    @isTest
    static void uniTestCancelled(){
        try{
            Order order = [Select Id, Status From Order Where Status = 'Placed' limit 1];
            system.debug('Draft Orders:' +order);
            //order.status = 'Cancelled';
            order.Is_Order_Cancelled__c = TRUE;
            order.Do_not_lock_Order_record__c = TRUE;
            update order;
            Test.startTest();
            VoidOrderController.checkVoidOrderCriteria(order.Id);
            //VoidOrderController.updateOrderStatus(order.Id);
            Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    }
    @isTest
    static void uniTestWithPlaced(){
        try{
            Order order = [Select Id, Status From Order Where Status = 'Placed' and Quote_Business_Group__c = 'MSP' limit 1];
            order.Quote_Business_Group__c = 'Barracuda';
            update order;
            OrderItem odit = [select id, OrderId from OrderItem where OrderId = :order.id];
            //odit.SBCF_Serial_Number__c = '5678';
            update odit;
            Test.startTest();
            VoidOrderController.checkVoidOrderCriteria(order.Id);
            VoidOrderController.updateOrderStatus(order.Id);
            Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    } 
    @isTest
    static void uniTestWithActivated(){
        try{
            Order order = [Select Id, Status, Bill_To_Contact__c, Bill_To_Contact_Email__c, Ship_To_Contact__c, Ship_To_Contact_Email__c, BillingStreet, BillingCity, BillingCountry, BillingCountryCode, BillingPostalCode, ShippingStreet, ShippingCity, ShippingCountry, ShippingCountryCode, ShippingPostalCode From Order Where Status = 'Placed' and Quote_Business_Group__c = 'MSP' limit 1];
            System.debug('Order is:' +order);
            order.Quote_Business_Group__c = 'Barracuda';
            order.Status = 'Activated';
            update order;
            OrderItem odit = [select id, OrderId from OrderItem where OrderId = :order.id];
            //odit.SBCF_Serial_Number__c = '5678';
            update odit;
            Test.startTest();
            VoidOrderController.checkVoidOrderCriteria(order.Id);
            VoidOrderController.updateOrderStatus(order.Id);
            Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    } 
}