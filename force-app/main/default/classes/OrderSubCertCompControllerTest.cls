/**
* @author Salesforce Services
* @date 02/14/2021
*
* @group Test
*
* @description SFDC-14048: Test class for OrderSubCertCompController
*
*/
@IsTest
public inherited sharing class OrderSubCertCompControllerTest {
  @TestSetup
    private static void testDataSetup(){
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
        
        //Create Parent Product
        Product2 testProduct1                  = new Product2();
        testProduct1.Name                      = 'Product1';
        testProduct1.is_pst_enterprise__c      = true;
        testProduct1.Base_SKU__c               = 'TEST_SKU';
        testProduct1.ProductCode               = 'TEST_SKU';
        //testProduct1.Product_Sales_Grouping__c = 'Cloud Email Services';   
        testProduct1.Product_Sales_Grouping__c = 'ESS'; 
        
        Product2 testProduct2                  = new Product2();
        testProduct2.Name                      = 'Product2';
        testProduct2.is_pst_enterprise__c      = true;
        testProduct2.Base_SKU__c               = 'TEST_SKU_2';
        testProduct2.ProductCode               = 'TEST_SKU_2';
        //testProduct2.Product_Sales_Grouping__c = 'Cloud Email Services'; 
        testProduct2.Product_Sales_Grouping__c = 'ESS';    
        
        insert new List<Product2>{testProduct1, testProduct2};
          //Create product bundle
    	SBQQ__ProductOption__c testPO = new SBQQ__ProductOption__c( SBQQ__Number__c = 10,
                                                                SBQQ__ConfiguredSKU__c = testProduct1.Id,
                                                                SBQQ__OptionalSKU__c = testProduct2.Id,
                                                                SBQQ__Type__c = 'Component',
                                                                SBQQ__QuoteLineVisibility__c = 'Never');

    	insert testPO;
  
            //Update Account Information
            Account acct = TestDataFactory.customers[0];
        
        //Opportunity
        Opportunity testOpp = TestDataFactory.opportunities[0];
        
        //Quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, 
                                                      SBQQ__Primary__c      = true);
        insert testQuote;
        
        //Contract
        Contract testContract = new Contract(AccountId            = acct.Id, 
                                             Business_Group__c    = 'Core', 
                                             SBQQ__Quote__c       = testQuote.Id, 
                                             StartDate            = System.today(),
                                             Reseller__c          = acct.Id,
                                             SBQQ__RenewalTerm__c = 12,
                                             ContractTerm = 3);
        
        Contract testTargetContract = new Contract(AccountId            = acct.Id, 
                                                   Business_Group__c    = 'MSP', 
                                                   SBQQ__Quote__c       = testQuote.Id, 
                                                   StartDate            = System.today(),
                                                   Reseller__c          = acct.Id,
                                                   SBQQ__RenewalTerm__c = 12,
                                                   ContractTerm = 3);                                         
        insert new List<Contract>{testContract, testTargetContract};
            
            //Order
            Order testOrder              = new Order();
        testOrder.AccountId          = TestDataFactory.customers[0].Id;
        testOrder.EffectiveDate      = Date.today();
        testOrder.Pricebook2Id       = TestDataFactory.priceBookId;
        testOrder.description        = 'Test Order';
        testOrder.Status             = 'Draft';
        testOrder.Type               = 'New'; // new order
        testOrder.Active_Contract__c = testContract.Id;
        testOrder.OpportunityId      = testOpp.Id;
        
        insert testOrder;
        
        //Add order item
        TestDataFactory.addOrderItem(new List<Order>{testOrder});
        
        //Get order line Id
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        //Subscription
        
        SBQQ__Subscription__c testSub1 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                                   SBQQ__Contract__c              = testContract.Id, 
                                                                   SBQQ__SubscriptionStartDate__c = System.today(),
                                                                   SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                                   SBQQ__Product__c               = testProduct1.Id,
                                                                   SBQQ__Account__c               = acct.Id,
                                                                   SBQQ__OrderProduct__c = oi.Id); 
        
        SBQQ__Subscription__c testSub2 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                                   SBQQ__Contract__c              = testTargetContract.Id, 
                                                                   SBQQ__SubscriptionStartDate__c = System.today(),
                                                                   SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                                   SBQQ__Product__c               = testProduct2.Id,
                                                                   SBQQ__Account__c               = acct.Id);
        
        List<SBQQ__Subscription__c> parentsubs = new List<SBQQ__Subscription__c>{testSub1, testSub2}; 
            
            insert parentsubs;
        
        //Serial
        Serial__c testSerial = new Serial__c(Serial_Number__c    = '1234567',
                                             Status__c           = 'Active',
                                             Capacity__c         = 1,
                                             Order__c            = testOrder.Id,
                                             Base_Product_SKU__c = 'TEST_SKU',
                                             Fulfillment_Date__c = System.Today() 
                                            );
        insert testSerial;
        
        //Assigned Serial
        Assigned_Serial__c testAssigned1 = new Assigned_Serial__c(Serial__c        = testSerial.Id, 
                                                                  Subscription__c = parentsubs[0].Id);
        
        Assigned_Serial__c testAssigned2 = new Assigned_Serial__c(Serial__c        = testSerial.Id, 
                                                                  Subscription__c = parentsubs[1].Id); 
        
        List<Assigned_Serial__c> assignedSerials = new List<Assigned_Serial__c>{testAssigned1, testAssigned2};                                                                                                                      
            insert assignedSerials;   
        
        TriggerHandler.clearAllBypasses();  
    }

  //Should return serials for the given order 
  @IsTest
  private static void test_shouldReturnSerials(){

    //Get Order record
    Order o = [SELECT Id FROM Order LIMIT 1];

    Test.startTest();
      //Create an instance of the component controller 
          OrderSubCertCompController cc = new OrderSubCertCompController();
      
      //Set the Cert Order field
      cc.certOrder = o;
      List<OrderSubCertCompController.SerialWrapper> serials = cc.serialList;   
      Assigned_Serial__c asignSerials = [SELECT Id FROM Assigned_Serial__c LIMIT 1];
      
      List<OrderSubCertCompController.SubscriptionWrapper> subList = new List<OrderSubCertCompController.SubscriptionWrapper>();
      
    Test.stopTest();
    
    //Assertion
    System.assert(serials!=null && !serials.isEmpty());
    System.assertEquals(1, serials[0].subList.size());

  }
}