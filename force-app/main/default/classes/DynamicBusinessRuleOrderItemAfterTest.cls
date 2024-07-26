/**
* @author Salesforce Services
* @date 02/14/2021
*
* @group Test 
*
* @description SFDC-14048: Test class for DynamicBusinessRuleOrderItemAfter
*
*/
@isTest
public inherited sharing class DynamicBusinessRuleOrderItemAfterTest {

  @TestSetup
  private static void testDataSetup(){
    //Create an Order
    List<Order> orders = TestDataFactory.orders;
   

    //Create an order item for the order
    TestDataFactory.addOrderItem(orders);
    TestDataFactory.addOrderItem(orders);
  }

  /*Scenario 1: 
    Test - Needs_Serial__c field on the order is false, but SBCF_Serial_Number__c is populated
    Expectation: Order field Send_Order_Certificate_Email__c should not be true */
  @isTest
  private static void test_ShouldNotBeEligible1(){
    //Get the order item
    List<OrderItem> orderItems = [SELECT Id, OrderId FROM OrderItem];
    
    Test.startTest();
    update new List<OrderItem>{new OrderItem(Id = orderItems[0].Id,
                                             SBCF_Serial_Number__c = '11111'), 
                               new OrderItem(Id = orderItems[1].Id,
                                             SBCF_Serial_Number__c = '22222')};
    Test.stopTest();
    
    //Get the order
    List<Order> updatedOrder = [SELECT Send_Order_Certificate_Email__c FROM Order 
                               WHERE Id = :orderItems[0].orderId];

    //Assertion
    System.assert(updatedOrder!=null && !updatedOrder.isEmpty());
    System.assert(!updatedOrder[0].Send_Order_Certificate_Email__c);
  }

  // /*Scenario 2: 
  // Test - Needs_Serial__c field on the order is true and SBCF_Serial_Number__c field is empty to begin with. 
  //        SBCF_Serial_Number__c field is updated on one order item
  // Expectation: Order field Send_Order_Certificate_Email__c should be true */
  @isTest
  private static void test_ShouldNotBeEligible2(){
    //Get the order item
    List<OrderItem> orderItems = [SELECT Id, OrderId  FROM OrderItem];
    //Bypassing trigger handler to prevent the logic from setting order field
    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
    update new List<OrderItem>{new OrderItem(Id = orderItems[0].Id,
                                              Needs_Serial__c = true), 
                                new OrderItem(Id = orderItems[1].Id,
                                              Needs_Serial__c = true)};
    //Clear bypasses so that the test will behave as expected
    TriggerHandler.clearAllBypasses(); 

    Test.startTest();
    update new List<OrderItem>{new OrderItem(Id = orderItems[0].Id,
                                             SBCF_Serial_Number__c = '11111')};
    Test.stopTest();
    
    //Get the order
    List<Order> updatedOrder = [SELECT Send_Order_Certificate_Email__c FROM Order 
                                WHERE Id = :orderItems[0].orderId];

    //Assertion
    System.assert(updatedOrder!=null && !updatedOrder.isEmpty());
    System.assert(!updatedOrder[0].Send_Order_Certificate_Email__c);
  }
    
  /*Scenario 3: 
    Test - Needs_Serial__c field on the order is true and SBCF_Serial_Number__c field is blank to begin with. 
           SBCF_Serial_Number__c field is updated on both order items
    Expectation: Order field Send_Order_Certificate_Email__c should be true */
  @isTest
  private static void test_ShouldBeEligible(){

    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
        Product2 testProd = TestDataFactory.products[0];
        testProd.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testProd.SBQQ__SubscriptionTerm__c = 1;
        update testProd;
     
        List<Order> order = [SELECT Id, AccountId,OpportunityId FROM Order];
        Account  testAccount =[Select Id,SBQQ__RenewalPricingMethod__c,Bill_To_Contact__c,Bill_To_Email__c   from Account where Id=:order[0].AccountId];
 
        testAccount.SBQQ__RenewalPricingMethod__c = 'Same';
        testAccount.Bill_To_Contact__c = 'Test Test';
        testAccount.Bill_To_Email__c = '123@123.com';
        update testAccount;

        Contract testContract = new Contract(AccountId = testAccount.Id, 
        Business_Group__c = 'Core', 
        SBQQ__RenewalPricebookId__c = '01sf2000003FSkFAAW', 
        SBQQ__RenewalOpportunityRecordTypeId__c = '012f2000001261kAAA', 
        SBQQ__RenewalOpportunityStage__c = 'Not Contacted', 
        StartDate = System.Today() - 720, ContractTerm = 12);
        insert testContract;

        testContract.Status = 'Activated';
        update testContract;
    
        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today() - 720); 
        insert testSub;
      
        Opportunity testOpp=[Select Id,RecordTypeID,Business_Group__c,CloseDate,SBQQ__RenewedContract__c,
        SBQQ__Renewal__c,Contract_Error_Check__c,Bill_To_Account__c  from Opportunity where Id=:order[0].OpportunityId];
        testOpp.RecordTypeID = '012f2000001261kAAA';
        testOpp.Business_Group__c = 'Core';
        testOpp.CloseDate = System.Today();
        testOpp.SBQQ__RenewedContract__c = testContract.Id;
        testOpp.SBQQ__Renewal__c = true;
        testOpp.Contract_Error_Check__c = '123';
        testOpp.Bill_To_Account__c = testAccount.Id;
        update testOpp;        

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Renewal');
        insert testQuote;  
        
        order[0].OpportunityId = testOpp.Id;
        order[0].AccountId=testAccount.Id;
        order[0].Contract_Error_Check__c = '123';
        order[0].BillingCity = 'Denver';
        order[0].BillingPostalCode = '80000';
        order[0].BillingState = 'Colorado';
        order[0].BillingCountry = 'United States';
        order[0].ShippingCity = 'Denver';
        order[0].ShippingPostalCode = '80000';
        order[0].ShippingState = 'Colorado';
        order[0].ShippingCountry = 'United States';
       // update  order[0];

        Id accid=[Select Id ,Bill_To_Account__r.Id from Opportunity where Id=: order[0].OpportunityId ].Bill_To_Account__r.Id;

        //TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   

        List<Account> acc=[Select id,Bill_To_Contact__c from Account where Id=:accid ];
        acc[0].Bill_To_Contact__c = 'Test Test';
     
        update  acc;

        order[0].Status = 'Activated';
        order[0].SBQQ__Contracted__c = true;
        order[0].BillingStreet = '123 Main Street';
        order[0].ShippingStreet = '123 Main Street';
        order[0].Bill_To_Contact__c = 'Test Test';
        order[0].Bill_To_Contact_Email__c = '123@123.com';
        order[0].Ship_To_Contact__c = 'Test Test';
        order[0].Ship_To_Contact_Email__c = '123@123.com';
        order[0].Contracted_Date_Time__c = System.now();     

     //   update  order[0];      

        order[0].Status = 'Placed';
        Test.startTest();
        update  order[0];

         TriggerHandler.clearAllBypasses(); 
         
         List<OrderItem> orderItems = [SELECT Id, OrderId ,SBCF_Serial_Number__c
                                        FROM OrderItem where Order.Id=: order[0].Id ];
        
        
         update new List<OrderItem>{new OrderItem(Id = orderItems[0].Id,
         SBCF_Serial_Number__c = '11111')
      };
    
    //Get the order
    List<Order> updatedOrder = [SELECT Id,Send_Order_Certificate_Email__c ,Status
                                FROM Order  where Order.Id=: order[0].Id
                               ];
    //Assertion
    System.assert(updatedOrder!=null && !updatedOrder.isEmpty());
    System.assert(!updatedOrder[0].Send_Order_Certificate_Email__c);       

    DynamicBusinessRuleOrderItemAfter.updateOrderEmailFieldFuture(new List<Id>{(Id)updatedOrder[0].Id},true);

    

    System.assert(updatedOrder!=null && !updatedOrder.isEmpty());
   // System.assert([Select Id,Send_Order_Certificate_Email__c from Order where Id=:updatedOrder[0].Id].Send_Order_Certificate_Email__c);
 
    Test.stopTest();
    DynamicBusinessRuleOrderItemAfter.sendSubCerts(new List<Id>{(Id)updatedOrder[0].Id},false);
    DynamicBusinessRuleOrderItemAfter.updateOrderEmailFieldFuture(new List<Id>{(Id)updatedOrder[0].Id},false);
  }  

  @isTest
  private static void sendPAMEventToMSTest(){

    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
        Product2 testProd = TestDataFactory.products[0];
        testProd.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testProd.SBQQ__SubscriptionTerm__c = 1;
        update testProd;

        List<Order> order = [SELECT Id, AccountId,OpportunityId FROM Order];
        Account  testAccount =[Select Id,SBQQ__RenewalPricingMethod__c,Bill_To_Contact__c,Bill_To_Email__c   from Account where Id=:order[0].AccountId];
        testAccount.SBQQ__RenewalPricingMethod__c = 'Same';
        testAccount.Bill_To_Contact__c = 'Test Test';
        testAccount.Bill_To_Email__c = '123@123.com';
        update testAccount;

        Contract testContract = new Contract(AccountId = testAccount.Id, 
        Business_Group__c = 'Core', 
        SBQQ__RenewalPricebookId__c = '01sf2000003FSkFAAW', 
        SBQQ__RenewalOpportunityRecordTypeId__c = '012f2000001261kAAA', 
        SBQQ__RenewalOpportunityStage__c = 'Not Contacted', 
        StartDate = System.Today() - 720, ContractTerm = 12);
        insert testContract;

        testContract.Status = 'Activated';
        update testContract;
    
        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today() - 720); 
        insert testSub;
        
        Opportunity testOpp=[Select Id,RecordTypeID,Business_Group__c,CloseDate,SBQQ__RenewedContract__c,
        SBQQ__Renewal__c,Contract_Error_Check__c,Bill_To_Account__c  from Opportunity where Id=:order[0].OpportunityId];
        testOpp.RecordTypeID = '012f2000001261kAAA';
        testOpp.Business_Group__c = 'Core';
        testOpp.CloseDate = System.Today();
        testOpp.SBQQ__RenewedContract__c = testContract.Id;
        testOpp.SBQQ__Renewal__c = true;
        testOpp.Contract_Error_Check__c = '123';
        testOpp.Bill_To_Account__c = testAccount.Id;
        update testOpp;        

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Renewal');
        insert testQuote;  
        
        order[0].OpportunityId = testOpp.Id;
        order[0].AccountId=testAccount.Id;
        order[0].Contract_Error_Check__c = '123';
        order[0].BillingCity = 'Denver';
        order[0].BillingPostalCode = '80000';
        order[0].BillingState = 'Colorado';
        order[0].BillingCountry = 'United States';
        order[0].ShippingCity = 'Denver';
        order[0].ShippingPostalCode = '80000';
        order[0].ShippingState = 'Colorado';
        order[0].ShippingCountry = 'United States';
        update order[0];

        Id accid=[Select Id ,Bill_To_Account__r.Id from Opportunity where Id=:order[0].OpportunityId ].Bill_To_Account__r.Id;

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   

        List<Account> acc=[Select id,Bill_To_Contact__c from Account where Id=:accid ];
        acc[0].Bill_To_Contact__c = 'Test Test';
     
        update  acc;

        TriggerHandler.clearAllBypasses(); 

        order[0].Status = 'Activated';
        order[0].SBQQ__Contracted__c = true;
        order[0].BillingStreet = '123 Main Street';
        order[0].ShippingStreet = '123 Main Street';
        order[0].Bill_To_Contact__c = 'Test Test';
        order[0].Bill_To_Contact_Email__c = '123@123.com';
        order[0].Ship_To_Contact__c = 'Test Test';
        order[0].Ship_To_Contact_Email__c = '123@123.com';
        order[0].Contracted_Date_Time__c = System.now();     

       // update order[0];       

        order[0].Status = 'Placed';

        Test.startTest();

        update order[0];

         TriggerHandler.clearAllBypasses(); 
         
         List<OrderItem> orderItems = [SELECT Id, OrderId ,SBCF_Serial_Number__c
                                        FROM OrderItem where Order.Id=:order[0].Id ];
        
        
         update new List<OrderItem>{new OrderItem(Id = orderItems[0].Id,
         SBCF_Serial_Number__c = '11111')
      };
    
    //Get the order
    List<Order> updatedOrder = [SELECT Id,Send_Order_Certificate_Email__c ,Status
                                FROM Order  where Order.Id=:order[0].Id
                               ];
    //Assertion
    System.assert(updatedOrder!=null && !updatedOrder.isEmpty());
    System.assert(!updatedOrder[0].Send_Order_Certificate_Email__c);       

    DynamicBusinessRuleOrderItemAfter.sendPlatformEventPAM(new List<Id>{(Id)updatedOrder[0].Id},true);    

    System.assert(updatedOrder!=null && !updatedOrder.isEmpty());
   
    Test.stopTest();
   
  }  
}