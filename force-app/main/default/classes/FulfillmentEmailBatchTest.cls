@isTest
public class FulfillmentEmailBatchTest {
    @testSetup
    static void setup() {
      TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
  
      //Create Parent Product
      Product2 testParentProduct                  = new Product2();
      testParentProduct.Name                      = 'Parent Product';
      testParentProduct.is_pst_enterprise__c      = true;
      testParentProduct.Base_SKU__c               = 'TEST_SKU';
      testParentProduct.ProductCode               = 'TEST_SKU';
      //testParentProduct.Product_Sales_Grouping__c = 'Cloud Email Services';  
      testParentProduct.Product_Sales_Grouping__c = 'ESS'; 

      //Create a child product
      Product2 testChildProduct             = new Product2();
      testChildProduct.Name                 = 'Child Product';
      testChildProduct.is_pst_enterprise__c = true;
      testChildProduct.Base_SKU__c          = 'TEST_SKU_CHILD';
      testChildProduct.ProductCode          = 'TEST_SKU_CHILD';
      testChildProduct.SBQQ__Component__c   = true;
  
      insert new List<Product2>{testParentProduct, testChildProduct};
  
      //Update Account Information
      Account partnerAccount = TestDataFactory.partners[0];
      
      //Opportunity
      Opportunity testOpp = TestDataFactory.opportunities[0];
  
      //Quote
      SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, 
                                                    SBQQ__Primary__c      = true);
      insert testQuote;
  
      //Contract
      Contract testContract = new Contract(AccountId            = partnerAccount.Id, 
                                           Business_Group__c    = 'MSP', 
                                           SBQQ__Quote__c       = testQuote.Id, 
                                           StartDate            = System.today(),
                                           Reseller__c          = partnerAccount.Id,
                                           SBQQ__RenewalTerm__c = 12);
                                     
      insert new List<Contract>{testContract};
  
      //Order
      Order testOrder              = new Order();
      testOrder.AccountId          = TestDataFactory.customers[0].Id;
      testOrder.EffectiveDate      = Date.today();
      testOrder.Pricebook2Id       = TestDataFactory.priceBookId;
      testOrder.description        = 'Test Order';
      testOrder.Status             = 'Draft';
      testOrder.Type               = 'New'; // new order
      testOrder.Active_Contract__c = testContract.Id;
      testOrder.OpportunityId        = testOpp.Id;
      
      insert testOrder;
  
      //Add order item
      TestDataFactory.addOrderItem(new List<Order>{testOrder});

      //Subscription
  
      SBQQ__Subscription__c testSub1 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                                 SBQQ__Contract__c              = testContract.Id, 
                                                                 SBQQ__SubscriptionStartDate__c = System.today(),
                                                                 SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                                 SBQQ__Product__c               = testParentProduct.Id,
                                                                 SBQQ__Account__c               = partnerAccount.Id); 

      List<SBQQ__Subscription__c> parentsubs = new List<SBQQ__Subscription__c>{testSub1}; 
      
      insert parentsubs;

      SBQQ__Subscription__c testSub2 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                                 SBQQ__Contract__c              = testContract.Id, 
                                                                 SBQQ__SubscriptionStartDate__c = System.today(),
                                                                 SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                                 SBQQ__Product__c               = testChildProduct.Id,
                                                                 SBQQ__Account__c               = partnerAccount.Id,
                                                                 SBQQ__RootId__c                = parentsubs[0].Id);                                                                
  
      List<SBQQ__Subscription__c> childsubs = new List<SBQQ__Subscription__c>{testSub2};
  
      insert childsubs;  
      
      //Serial
      Serial__c testSerial = new Serial__c(Serial_Number__c    = '1234567',
                                           Status__c           = 'Active',
                                           Capacity__c         = 1,
                                           Order__c            = testOrder.Id,
                                           Base_Product_SKU__c = 'TEST_SKU', 
                                           Business_Group__c   = 'MSP');
      insert testSerial;
  
      //Assigned Serial
      Assigned_Serial__c testAssigned1 = new Assigned_Serial__c(Serial__c        = testSerial.Id, 
                                                                Subscription__c = parentsubs[0].Id,
                                                                Parent_Subscription__c = parentsubs[0].Id);
  
      Assigned_Serial__c testAssigned2 = new Assigned_Serial__c(Serial__c        = testSerial.Id, 
                                                                Subscription__c = childsubs[0].Id,
                                                                Parent_Subscription__c = parentsubs[0].Id); 
  
      List<Assigned_Serial__c> assignedSerials = new List<Assigned_Serial__c>{testAssigned1, testAssigned2};                                                                                                                      
      insert assignedSerials;   
  
      TriggerHandler.clearAllBypasses();  
    }

    /** Scenario1 : Batch finds records that meet the criteria and executes the logic
     */
    @isTest static void test_shouldFindSerials() {

        //Get the serial and update license and tracking information
        List<Serial__c> serials = [SELECT Id, 
                                          License_Token_Information__c,
                                          Tracking_Number__c
                                   FROM Serial__c];

        //Update license token and tracking number
        serials[0].License_Token_Information__c = 'TEST_LICENSE';
        serials[0].Tracking_Number__c = 'TEST_TRACKING';

        update serials;

        //Start test
        Test.startTest();
            //Get serial and check that the Send_Fulfillment_Email__c field is true
            List<Serial__c> updatedSerials = [SELECT Id, 
                                                     License_Token_Information__c,
                                                     Tracking_Number__c,
                                                     Send_Fulfillment_Email__c
                                             FROM Serial__c 
                                             WHERE Id = :serials[0].Id];

            System.assert(updatedSerials[0].Send_Fulfillment_Email__c);
            Database.executeBatch(new FulfillmentEmailBatch());

        Test.stopTest();

        //Fetch the serial again and assert that send fulfillment email has been set to false
        List<Serial__c> batchUpdatedSerials = [SELECT Send_Fulfillment_Email__c
                                          FROM Serial__c 
                                          WHERE Id = :serials[0].Id];

        //Assert
        System.assert(!batchUpdatedSerials[0].Send_Fulfillment_Email__c);
    }
}