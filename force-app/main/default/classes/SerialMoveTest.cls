/**
* @author        salesforce services
* @date          2020-07-08
* @description   Unit Test class for Serial Move related classes
                 - SerialFetchAPI
                 - SubscriptionFetchAPI
                 - SerialMoveHelper 
                 - SerialMoveAPI
* @group         Test
*
*/

@isTest
public with sharing class SerialMoveTest {
  //Serial Move JSON String
  // private static String jsonString = '';

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

    Product2 testUpgradeParentProduct                  = new Product2();
    testUpgradeParentProduct.Name                      = 'Upgrade Parent Product';
    testUpgradeParentProduct.is_pst_enterprise__c      = true;
    testUpgradeParentProduct.Base_SKU__c               = 'TEST_SKU_UPGRADE';
    testUpgradeParentProduct.ProductCode               = 'TEST_SKU_UPGRADE';
    //testUpgradeParentProduct.Product_Sales_Grouping__c = 'Cloud Email Services';
    testUpgradeParentProduct.Product_Sales_Grouping__c = 'ESS';        

    insert new List<Product2>{testParentProduct, testChildProduct, testUpgradeParentProduct};

    //Update Account Information
    Account partnerAccount = TestDataFactory.partners[0];
    partnerAccount.User_Na__c = 'testpartner';
    
    partnerAccount.Compliance_Status__c = 'Active';
    update partnerAccount;
    
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

    Contract testTargetContract = new Contract(AccountId            = partnerAccount.Id, 
                                               Business_Group__c    = 'MSP', 
                                               SBQQ__Quote__c       = testQuote.Id, 
                                               StartDate            = System.today(),
                                               Reseller__c          = partnerAccount.Id,
                                               SBQQ__RenewalTerm__c = 12);                                         
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
                                                               SBQQ__Product__c               = testParentProduct.Id,
                                                               SBQQ__Account__c               = partnerAccount.Id); 

    SBQQ__Subscription__c testSub2 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                               SBQQ__Contract__c              = testTargetContract.Id, 
                                                               SBQQ__SubscriptionStartDate__c = System.today(),
                                                               SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                               SBQQ__Product__c               = testUpgradeParentProduct.Id,
                                                               SBQQ__Account__c               = partnerAccount.Id);
                                                               
    List<SBQQ__Subscription__c> parentsubs = new List<SBQQ__Subscription__c>{testSub1, testSub2}; 
    
    insert parentsubs;

    SBQQ__Subscription__c testSub3 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                               SBQQ__Contract__c              = testContract.Id, 
                                                               SBQQ__SubscriptionStartDate__c = System.today(),
                                                               SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                               SBQQ__Product__c               = testChildProduct.Id,
                                                               SBQQ__Account__c               = partnerAccount.Id,
                                                               SBQQ__RootId__c                = parentsubs[0].Id);                                                                

    SBQQ__Subscription__c testSub4 = new SBQQ__Subscription__c(SBQQ__Quantity__c              = 1, 
                                                               SBQQ__Contract__c              = testTargetContract.Id, 
                                                               SBQQ__SubscriptionStartDate__c = System.today(),
                                                               SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
                                                               SBQQ__Product__c               = testChildProduct.Id,
                                                               SBQQ__Account__c               = partnerAccount.Id,
                                                               SBQQ__RootId__c                = parentsubs[1].Id);  

    List<SBQQ__Subscription__c> childsubs = new List<SBQQ__Subscription__c>{testSub3, testSub4};

    insert childsubs;  
    
    //Serial
    Serial__c testSerial = new Serial__c(Serial_Number__c    = '1234567',
                                         Status__c           = 'Active',
                                         Capacity__c         = 1,
                                         Order__c            = testOrder.Id,
                                         Base_Product_SKU__c = 'TEST_SKU');
    insert testSerial;

    //Assigned Serial
    Assigned_Serial__c testAssigned1 = new Assigned_Serial__c(Serial__c        = testSerial.Id, 
                                                              Subscription__c = parentsubs[0].Id);

    Assigned_Serial__c testAssigned2 = new Assigned_Serial__c(Serial__c        = testSerial.Id, 
                                                              Subscription__c = childsubs[0].Id,
                                                              Parent_Subscription__c = parentsubs[0].Id); 

    List<Assigned_Serial__c> assignedSerials = new List<Assigned_Serial__c>{testAssigned1, testAssigned2};                                                                                                                      
    insert assignedSerials;   

    TriggerHandler.clearAllBypasses();  
  }
  //SCENARIOS FOR SERIALFETCHAPI CLASS
  /** Scenario1 : Mock service should return a serial for the SMB username
   *              Returned serial exists in Salesforce
   *              Method returns serial information
   */
  @isTest static void test_shouldGetSerialDetails() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('mockSerialFetchAPISuccessResponse');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
      //Build request instance
      SerialFetchAPI.SerialFetchRequest apiRequest = new SerialFetchAPI.SerialFetchRequest();
      apiRequest.smbusername = 'TESTSMBUSER';
      apiRequest.moveType    = 'Uplevel';
      apiRequest.countryCode = 'US';

      // Call the method that performs the callout
      List<SerialFetchAPI.SMBAPIResult> result = SerialFetchAPI.fetchSerials(new List<SerialFetchAPI.SerialFetchRequest>{apiRequest});
             
    Test.stopTest();

    // Verify response received contains values returned by the mock response.
    System.assertEquals('Serial Numbers fetched Successfully', result[0].message);
    System.assert(result[0].result);
    System.assert(result[0].smbSerials!=null && result[0].smbSerials.size()==1);
    System.assert(result[0].smbSerials[0].Serial_Number__c == '1234567');
  }

  /** Scenario2 : Mock service should return a serial for the SMB username
   *              Returned serial does not exist in Salesforce
   *              Method does not return serial information
   */
  @isTest static void test_shouldNotGetSerialDetails() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('mockSerialFetchAPIWrongSerial');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
      //Build request instance
      SerialFetchAPI.SerialFetchRequest apiRequest = new SerialFetchAPI.SerialFetchRequest();
      apiRequest.smbusername = 'TESTSMBUSER';
      apiRequest.moveType    = 'Uplevel';
      apiRequest.countryCode = 'CA';

      // Call the method that performs the callout
      List<SerialFetchAPI.SMBAPIResult> result = SerialFetchAPI.fetchSerials(new List<SerialFetchAPI.SerialFetchRequest>{apiRequest});
             
    Test.stopTest();

    // Verify response received contains values returned by the mock response.
    System.assertEquals('Serials not available for the SMB username provided.', result[0].message);
    System.assert(!result[0].result);
    System.assert(result[0].smbSerials==null || result[0].smbSerials.isEmpty());
  }

  /** Scenario3 : Mock service should not return any serials for SMB username
   *              Method does not return serial information
   */
  @isTest static void test_SMBNoSerials() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('mockSerialFetchAPINoResponse');
    mock.setStatusCode(404);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
      //Build request instance
      SerialFetchAPI.SerialFetchRequest apiRequest = new SerialFetchAPI.SerialFetchRequest();
      apiRequest.smbusername = 'TESTSMBUSER';
      apiRequest.moveType    = 'Uplevel';
      apiRequest.countryCode = 'GB';

      // Call the method that performs the callout
      List<SerialFetchAPI.SMBAPIResult> result = SerialFetchAPI.fetchSerials(new List<SerialFetchAPI.SerialFetchRequest>{apiRequest});
             
    Test.stopTest();

    // Verify response received contains values returned by the mock response.
    System.assert(String.isNotBlank(result[0].message));
    System.assert(!result[0].result);
    System.assert(result[0].smbSerials==null || result[0].smbSerials.isEmpty());
  }

  /** Scenario4 : Serial Fetch callout exception
   *              Method does not return serial information
   */
  @isTest static void test_SerialFetchCallOutError() {

    Test.setMock(HttpCalloutMock.class, new MockCalloutError());

    Test.startTest();
      //Build request instance
      SerialFetchAPI.SerialFetchRequest apiRequest = new SerialFetchAPI.SerialFetchRequest();
      apiRequest.smbusername = 'TESTSMBUSER';
      apiRequest.moveType    = 'Uplevel';
      apiRequest.countryCode = 'US';

      // Call the method that performs the callout
      List<SerialFetchAPI.SMBAPIResult> result = SerialFetchAPI.fetchSerials(new List<SerialFetchAPI.SerialFetchRequest>{apiRequest});
             
    Test.stopTest();

    // Verify response received contains values returned by the mock response.
    System.assert(String.isNotBlank(result[0].message));
    System.assert(!result[0].result);
    System.assert(result[0].smbSerials==null || result[0].smbSerials.isEmpty());
  }
  //END OF SCENARIOS FOR SERIALFETCHAPI CLASS  

  //SCENARIOS FOR SUBSCRIPTIONFETCHAPI CLASS
  /** Scenario5 : Subscriptions should be returned for the given Account Id for Migration
   */
  @isTest static void test_ShouldGetSubscriptionsForMigration() {

    //Get Subscription record for test assertion
    List<SBQQ__Subscription__c> parentSubscription = [SELECT Id,
                                                             SBQQ__Account__c 
                                                      FROM SBQQ__Subscription__c 
                                                      WHERE SBQQ__Product__r.ProductCode = 'TEST_SKU'];
    Test.startTest();
      //Build request instance
      SubscriptionFetchAPI.SubFetchRequest apiRequest = new SubscriptionFetchAPI.SubFetchRequest();
      apiRequest.accountId       = parentSubscription[0].SBQQ__Account__c;
      apiRequest.moveType        = 'Migration';
      apiRequest.productCodeList = new List<String>{'TEST_SKU'};

      // Call the method that performs the callout
      List<SubscriptionFetchAPI.SubFetchResult> result = SubscriptionFetchAPI.fetchSubscriptions(new List<SubscriptionFetchAPI.SubFetchRequest>{apiRequest});
             
    Test.stopTest();

    // Verify response received contains values returned by the mock response.
    System.assertEquals('Subscriptions fetched Successfully',result[0].message);
    System.assert(result[0].result);
    System.assert(result[0].subscriptionList!=null && result[0].subscriptionList.size()==1);
    System.assertEquals(parentSubscription[0].Id,result[0].subscriptionList[0].Id);
  }

  /** Scenario6 : Subscriptions should be returned for the given Account Id for Uplevel
   */
  @isTest static void test_ShouldGetSubscriptionsForUplevel() {

    //Get Subscription record for test assertion
    List<SBQQ__Subscription__c> parentSubscription = [SELECT Id,
                                                             SBQQ__Account__c 
                                                      FROM SBQQ__Subscription__c 
                                                      WHERE SBQQ__Product__r.ProductCode = 'TEST_SKU'];
    Test.startTest();
      //Build request instance
      SubscriptionFetchAPI.SubFetchRequest apiRequest = new SubscriptionFetchAPI.SubFetchRequest();
      apiRequest.accountId       = parentSubscription[0].SBQQ__Account__c;
      apiRequest.moveType        = 'Uplevel';
      apiRequest.productCodeList = null;

      // Call the method that performs the callout
      List<SubscriptionFetchAPI.SubFetchResult> result = SubscriptionFetchAPI.fetchSubscriptions(new List<SubscriptionFetchAPI.SubFetchRequest>{apiRequest});
             
    Test.stopTest();

    // Verify response received contains values returned by the mock response.
    System.assertEquals('Subscriptions fetched Successfully',result[0].message);
    System.assert(result[0].result);
    System.assert(result[0].subscriptionList!=null);
    for(SBQQ__Subscription__c currentSub: result[0].subscriptionList){
      if(currentSub.Product_Code__c == 'TEST_SKU'){
        System.assertEquals(parentSubscription[0].Id, currentSub.Id);
      }
    }
  } 
  
  /** Scenario7 : Should not return subscription. We will pass incorrect account Id
   */
  @isTest static void test_ShouldNotGetSubscriptions() {
    List<SBQQ__Subscription__c> parentSubscription = [SELECT Id,
                                                            SBQQ__Account__c 
                                                     FROM SBQQ__Subscription__c 
                                                     WHERE SBQQ__Product__r.ProductCode = 'TEST_SKU'];
    Test.startTest();
      //Build request instance
      SubscriptionFetchAPI.SubFetchRequest apiRequest = new SubscriptionFetchAPI.SubFetchRequest();
      apiRequest.accountId       = parentSubscription[0].SBQQ__Account__c;
      apiRequest.moveType        = 'Migration';
      apiRequest.productCodeList = new List<String>{'NONEXISTENTCODE'};

      // Call the method that performs the callout
      List<SubscriptionFetchAPI.SubFetchResult> result = SubscriptionFetchAPI.fetchSubscriptions(new List<SubscriptionFetchAPI.SubFetchRequest>{apiRequest});
             
    Test.stopTest();

    // Verify response received contains values returned by the mock response.
    System.assertEquals('Subscriptions not available for the Account provided.',result[0].message);
    System.assert(!result[0].result);
    System.assert(result[0].subscriptionList==null || result[0].subscriptionList.isEmpty());
  }
  //END OF SCENARIOS FOR SUBSCRIPTIONFETCHAPI CLASS
  
  //SCENARIOS FOR SERIALMOVEHELPER CLASS
  /** Scenario8 : Account search. Should return an account
   */
  @isTest static void test_ShouldGetAccount() {
 
    Test.startTest();
      //Get the partner account
      Account partnerAccount = [SELECT Id FROM Account WHERE User_Na__c = 'testpartner'];
      partnerAccount.Type = 'Partner - MSP';
      update partnerAccount;
      
      // Call the method that performs the callout
      List<Account> result = SerialMoveHelper.findAccounts('partner', 10);
             
    Test.stopTest();

    // Verify response received contains values returned by the mock response.
    System.assert(result!=null && result.size()==1);
  }

  /** Scenario9 : Account search. Should not return an account
   */
  @isTest static void test_ShouldNotGetAccount() {
 
    Test.startTest();

      // Call the method that performs the callout
      List<Account> result = SerialMoveHelper.findAccounts('nonexistent', 10);
             
    Test.stopTest();

    // Verify response received contains values returned by the mock response.
    System.assert(result==null || result.isEmpty());
  } 

  /** Scenario10 : Update Assigned Serial Subscription field to Target Subscription
   */
  // @isTest static void test_ShouldUpdateAssignedSerials() {

  //   Test.startTest();
  //     //Get JSON String
  //     String jsonString = prepareJSONString(); 

  //     // Call the method that performs the callout
  //     SerialMoveHelper.SerialUpdateResult result = SerialMoveHelper.updateAssignedSerials(jsonString);
             
  //   Test.stopTest();

  //   //Get target parent subscription
  //   SBQQ__Subscription__c targetSubscription = [SELECT Id,
  //                                                      SBQQ__Contract__c
  //                                               FROM SBQQ__Subscription__c 
  //                                               WHERE SBQQ__Product__r.ProductCode = 'TEST_SKU_UPGRADE' LIMIT 1];

  //   // SBQQ__Subscription__c targetChildSubscription = [SELECT Id
  //   //                                                  FROM SBQQ__Subscription__c 
  //   //                                                  WHERE SBQQ__Product__r.ProductCode = 'TEST_SKU_CHILD' 
  //   //                                                  AND SBQQ__RootId__c = :targetSubscription.Id LIMIT 1];
                                     
  //   //Get updated assigned serial and assert field updates
  //   for(Assigned_Serial__c currentAS: [SELECT Subscription__c,
  //                                             Subscription__r.SBQQ__Product__r.ProductCode,
  //                                             Parent_Subscription__c,
  //                                             Contract__c 
  //                                      FROM Assigned_Serial__c]){
  //     if(String.isNotBlank(currentAS.Subscription__r.SBQQ__Product__r.ProductCode)) {
  //       if(currentAS.Subscription__r.SBQQ__Product__r.ProductCode == 'TEST_SKU_CHILD'){
  //         System.assertEquals(targetSubscription.Id, currentAS.Parent_Subscription__c);
  //       }
  //       else{
  //         System.assertEquals('TEST_SKU_UPGRADE', currentAS.Subscription__r.SBQQ__Product__r.ProductCode);
  //         System.assertEquals(targetSubscription.Id, currentAS.Subscription__c);
  //       }
  //     }
  //   }
  //   // Verify response received contains values returned by the mock response.
  //   System.assertEquals('Serials updated in Salesforce',result.message);
  //   System.assert(result.result);
  // }

  @isTest static void test_ShouldUpdateAssignedSerials() {

    Test.startTest();
      //Get JSON String
      String jsonString = prepareJSONString(); 

      // Call the method that performs the callout
      SerialMoveHelper.SerialUpdateResult result = SerialMoveHelper.updateAssignedSerials(jsonString);
             
    Test.stopTest();

   
    System.assertEquals('Serials updated in Salesforce',result.message);
    System.assert(result.result);
  }
  //END OF SCENARIOS FOR SERIALMOVEHELPER CLASS

  //SCENARIOS FOR SERIALMOVEAPI CLASS
  /** Scenario11 : Call SerialMove API for Migration
   *               Both Serials and SMB is moved successfully
   */
  @isTest static void test_SerialMoveAPISuccess() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('mockSerialMoveAPISuccessResponse');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
      //Build request instance
      SerialMoveAPI.FlowMoveAPIRequest apiRequest = new SerialMoveAPI.FlowMoveAPIRequest();
      apiRequest.smbusername = 'TESTSMBUSER';
      apiRequest.sourceAccountUsername = 'TESTSOURCEACCT';
      apiRequest.targetPartnerUsername = 'TESTTARGETACCT';
      apiRequest.serialSubMap = prepareJSONString();
      apiRequest.moveType    = 'Migration';
      apiRequest.countryCode = 'US';

      // Call the method that performs the callout
      List<SerialMoveAPI.MoveAPIResult> result = SerialMoveAPI.moveSerials(new List<SerialMoveAPI.FlowMoveAPIRequest>{apiRequest});
           
    Test.stopTest();

    // Verify response received contains values returned by the mock response.
    System.assertEquals('Serials and SMB were moved successfully', result[0].message);
    System.assert(result[0].result);
    System.assert(String.isBlank(result[0].failedSerials));
  }

  /** Scenario12 : Call SerialMove API for Migration
   *               Serials are moved successfully
   *               SMB move fails
   */
  @isTest static void test_SerialMoveAPISMBMoveFail() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('mockSerialMoveAPISMBFailed');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
      //Build request instance
      SerialMoveAPI.FlowMoveAPIRequest apiRequest = new SerialMoveAPI.FlowMoveAPIRequest();
      apiRequest.smbusername = 'TESTSMBUSER';
      apiRequest.sourceAccountUsername = 'TESTSOURCEACCT';
      apiRequest.targetPartnerUsername = 'TESTTARGETACCT';
      apiRequest.serialSubMap = prepareJSONString();
      apiRequest.moveType    = 'Migration';
      apiRequest.countryCode = 'US';

      // Call the method that performs the callout
      List<SerialMoveAPI.MoveAPIResult> result = SerialMoveAPI.moveSerials(new List<SerialMoveAPI.FlowMoveAPIRequest>{apiRequest});
           
    Test.stopTest();

    // Verify response received contains values returned by the mock response.
    System.assertEquals('Unabled to move SMB to new partner', result[0].message);
    System.assert(!result[0].result);
    System.assert(String.isBlank(result[0].failedSerials));
  }

  /** Scenario13 : Call SerialMove API for Migration
   *               Serial move fails
   *               SMB move fails
   */
  @isTest static void test_SerialMoveAPISerialMoveFail() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('mockSerialMoveAPISerialFailed');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
      //Build request instance
      SerialMoveAPI.FlowMoveAPIRequest apiRequest = new SerialMoveAPI.FlowMoveAPIRequest();
      apiRequest.smbusername = 'TESTSMBUSER';
      apiRequest.sourceAccountUsername = 'TESTSOURCEACCT';
      apiRequest.targetPartnerUsername = 'TESTTARGETACCT';
      apiRequest.serialSubMap = prepareJSONString();
      apiRequest.moveType    = 'Migration';
      apiRequest.countryCode = 'US';

      // Call the method that performs the callout
      List<SerialMoveAPI.MoveAPIResult> result = SerialMoveAPI.moveSerials(new List<SerialMoveAPI.FlowMoveAPIRequest>{apiRequest});
           
    Test.stopTest();

    // Verify response received contains values returned by the mock response.
    System.assertEquals('Serials failed to move to target subscriptions', result[0].message);
    System.assert(!result[0].result);
    System.assert(String.isNotBlank(result[0].failedSerials) && result[0].failedSerials.contains('1234567'));
  } 

  /** Scenario14 : Call SerialMove API for Migration
   *               404 Response received
   */
  @isTest static void test_SerialMoveAPI404() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('mockSerialMoveAPI404');
    mock.setStatusCode(404);
    mock.setHeader('Content-Type', 'application/json');

    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
      //Build request instance
      SerialMoveAPI.FlowMoveAPIRequest apiRequest = new SerialMoveAPI.FlowMoveAPIRequest();
      apiRequest.smbusername = 'TESTSMBUSER';
      apiRequest.sourceAccountUsername = 'TESTSOURCEACCT';
      apiRequest.targetPartnerUsername = 'TESTTARGETACCT';
      apiRequest.serialSubMap = prepareJSONString();
      apiRequest.moveType    = 'Migration';
      apiRequest.countryCode = 'US';

      // Call the method that performs the callout
      List<SerialMoveAPI.MoveAPIResult> result = SerialMoveAPI.moveSerials(new List<SerialMoveAPI.FlowMoveAPIRequest>{apiRequest});
           
    Test.stopTest();

    // Verify response received contains values returned by the mock response.
    System.assertEquals('Resource not found.', result[0].message);
    System.assert(!result[0].result);
    System.assert(String.isBlank(result[0].failedSerials));
  }
  
  /** Scenario14 : Call SerialMove API for Migration
   *               Call Out Exception
   */
  @isTest static void test_SerialMoveAPICallOutException() {
    Test.setMock(HttpCalloutMock.class, new MockCalloutError());

    Test.startTest();
      //Build request instance
      SerialMoveAPI.FlowMoveAPIRequest apiRequest = new SerialMoveAPI.FlowMoveAPIRequest();
      apiRequest.smbusername = 'TESTSMBUSER';
      apiRequest.sourceAccountUsername = 'TESTSOURCEACCT';
      apiRequest.targetPartnerUsername = 'TESTTARGETACCT';
      apiRequest.serialSubMap = prepareJSONString();
      apiRequest.moveType    = 'Migration';
      apiRequest.countryCode = 'US';

      // Call the method that performs the callout
      List<SerialMoveAPI.MoveAPIResult> result = SerialMoveAPI.moveSerials(new List<SerialMoveAPI.FlowMoveAPIRequest>{apiRequest});
           
    Test.stopTest();

    // Verify response received contains values returned by the mock response.
    System.assert(result[0].message.contains('Mock Callout Exception'));
    System.assert(!result[0].result);
    System.assert(String.isBlank(result[0].failedSerials));
  }    
  //END OF SCENARIOS FOR SERIALMOVEAPI CLASS

  /**Utility method to prepare JSOn string */
  @isTest
  private static String prepareJSONString(){
    //Get static resource containing the JSON string to be passed to the method
    StaticResource jsonResource = [SELECT Body FROM StaticResource WHERE Name = 'mockSerialMoveJSON'];

    //Get current parent subscription
    SBQQ__Subscription__c currentParentSub = [SELECT Id, 
                                                      SBQQ__Product__r.Name,
                                                      SBQQ__Product__r.ProductCode
                                              FROM SBQQ__Subscription__c 
                                              WHERE SBQQ__Product__r.ProductCode = 'TEST_SKU' Limit 1];

    //Get target parent subscription
    SBQQ__Subscription__c targetParentSub = [SELECT Id, 
                                                    SBQQ__Product__r.Name,
                                                    SBQQ__Product__r.ProductCode
                                              FROM SBQQ__Subscription__c 
                                              WHERE SBQQ__Product__r.ProductCode = 'TEST_SKU_UPGRADE' Limit 1];
    //Get parent assigned serial
    Assigned_Serial__c assignedSerial = [SELECT Id
                                          FROM Assigned_Serial__c 
                                          WHERE Subscription__c = :currentParentSub.Id Limit 1];
    //Get serial
    Serial__c serial = [SELECT Id,
                                Serial_Number__c,
                                Base_Product_SKU__c
                        FROM Serial__c 
                        WHERE Serial_Number__c = '1234567' Limit 1];

    //Get Order
    Order o = [SELECT Id FROM Order LIMIT 1]; 
    
    //Get order line Id
    OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];

    //Add Ids and values corresponding to test data
    return jsonResource.Body.toString().replace('testsubid', targetParentSub.Id)
           .replace('testproductname', targetParentSub.SBQQ__Product__r.Name)
           .replace('testproductcode', targetParentSub.SBQQ__Product__r.ProductCode)
           .replace('testorderid', o.Id)
           .replace('testorderlineid', oi.Id)
           .replace('testsubrootid', targetParentSub.Id)
           .replace('testasid', assignedSerial.Id)
           .replace('testserialnumber', serial.Serial_Number__c)
           .replace('testserialid', serial.Id)
           .replace('testbasesku', serial.Base_Product_SKU__c)
           .replace('testoldsubid', currentParentSub.id);
                  
  }

  @isTest static void test_UpdateAssignedSerials() {

    SerialMoveHelperAction.SerialMoveUpdateRequest smReq=new SerialMoveHelperAction.SerialMoveUpdateRequest();

    Test.startTest();
    //Get JSON String
    String jsonString = prepareJSONString();
    smReq.serialSubMap=jsonString;

    // Call the method that performs the callout
    List<SerialMoveHelperAction.SerialMoveUpdateResult> result = SerialMoveHelperAction.updateAssignedSerialsAction(new List<SerialMoveHelperAction.SerialMoveUpdateRequest> {smReq});
           
  Test.stopTest();

      SBQQ__Subscription__c targetSubscription = [SELECT Id,
      SBQQ__Contract__c
    FROM SBQQ__Subscription__c 
    WHERE SBQQ__Product__r.ProductCode = 'TEST_SKU_UPGRADE' LIMIT 1];

// SBQQ__Subscription__c targetChildSubscription = [SELECT Id
//                                                  FROM SBQQ__Subscription__c 
//                                                  WHERE SBQQ__Product__r.ProductCode = 'TEST_SKU_CHILD' 
//                                                  AND SBQQ__RootId__c = :targetSubscription.Id LIMIT 1];

    //Get updated assigned serial and assert field updates
    for(Assigned_Serial__c currentAS: [SELECT Subscription__c,
    Subscription__r.SBQQ__Product__r.ProductCode,
    Parent_Subscription__c,
    Contract__c 
    FROM Assigned_Serial__c]){
      if(String.isNotBlank(currentAS.Subscription__r.SBQQ__Product__r.ProductCode)) {
      if(currentAS.Subscription__r.SBQQ__Product__r.ProductCode == 'TEST_SKU_CHILD'){
      System.assertEquals(targetSubscription.Id, currentAS.Parent_Subscription__c);
    }
    else{
      System.assertEquals('TEST_SKU_UPGRADE', currentAS.Subscription__r.SBQQ__Product__r.ProductCode);
      System.assertEquals(targetSubscription.Id, currentAS.Subscription__c);
    }
    }
    }
// Verify response received contains values returned by the mock response.
System.assertEquals('Serials updated in Salesforce',result[0].message);
}

}