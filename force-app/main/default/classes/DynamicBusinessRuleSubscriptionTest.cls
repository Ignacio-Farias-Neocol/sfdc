/**
* @author Yuli
* @date 11/08/2019
*
* @group Test
* SFDC-13294: Added test for Has SaaS logic
* SFDC-13091: Added test to set RMA detected on Contract logic
*/
@IsTest
private class DynamicBusinessRuleSubscriptionTest {
    static Account testAccount;
    static SBQQ__Quote__c testQuote;
    static SBQQ__QuoteLine__c testQuoteLine;
    static List<SBQQ__Subscription__c> testSubs;
    static Product2 testProd;
    static Opportunity testOpp;
    static void setup() {
        testProd = TestDataFactory.products[0];
        testAccount = TestDataFactory.customers[0];
        //List<Order> orders = TestDataFactory.orders;

        //testContract is legacy contract with a sub
        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core', StartDate = System.Today());
        insert testContract;

        testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123'),
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123'),
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123'),
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123')
        }; 
        insert testSubs;

        //renewal oppty renewed testContract
        testOpp = TestDataFactory.opportunities[0];
        testContract.SBQQ__RenewalOpportunity__c = testOpp.Id;
        update testContract;

        testOpp.SBQQ__RenewedContract__c = testContract.Id;
        update testOpp;
    }
    
    @IsTest
    static  void unitTest() {
        setup();
        Test.startTest();
            testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true);
            insert testQuote;
    
            //quote line renewed sub of testContract
            testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuote.Id, SBQQ__RenewedSubscription__c = testSubs[0].Id, SBQQ__NetPrice__c = 0, SBCF_Is_Shipped__c = TRUE, Appliance_Line_Type__c = 'Standard');
            insert testQuoteLine; 
            
            testSubs[0].SBQQ__RevisedSubscription__c = testSubs[1].Id;
            testSubs[2].SBQQ__QuoteLine__c = testQuoteLine.Id;
            testSubs[2].SBQQ__RevisedSubscription__c = testSubs[3].Id;
            update testSubs;

            //testContract2 is new renewal contract
            Contract testContract2 = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, StartDate = System.Today());
            insert testContract2;

            //new sub is created from the quote line
            SBQQ__Subscription__c testSub1 = new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract2.Id, SBQQ__QuoteLine__c = testQuoteLine.Id, SBQQ__SubscriptionStartDate__c = System.Today()); 
            insert testSub1;
        Test.stopTest();
    }

    @IsTest
    static  void unitTestPSFOwned() {
        Account testAccount = TestDataFactory.customers[0];
        testAccount.Product_Sales_Groups_Owned__c = 'IBU,BBS';
        update testAccount;

        Product2 testProd = TestDataFactory.products[0];
       // testProd.Product_Sales_Grouping__c = 'EchoPlatform';
       testProd.Product_Sales_Grouping__c = 'IBU';
        update testProd;

        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'MSP', StartDate = System.Today());
        insert testContract;

        Test.startTest();
            SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Account__c = testAccount.Id, SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today()); 
            insert testSub;
        Test.stopTest();
    }

    @isTest
    static void unitTestAllSubsRMATrue() {

        // AfterInsert
        Test.startTest();
        Account testAccount = TestDataFactory.customers[0];
        
        Product2 testProd = TestDataFactory.products[0];
        testProd.ProductCode='BEO-AES1-MSP';
        update testProd;

        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core', StartDate = System.Today(),All_Subs_RMA__c=false);
        insert testContract;
                       
        List<SBQQ__Subscription__c>  testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id,SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123'),
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id,SBQQ__Quantity__c = -1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123')
        }; 

        insert testSubs;      

        Contract con=[SELECT Id, All_Subs_RMA__c, Auto_Renewal_Eligible_Core__c,Description FROM Contract WHERE Id = :testContract.Id];

        System.debug('testContract::'+testContract);
        System.assertEquals(true,con.All_Subs_RMA__c);
        System.assertEquals(false,con.Auto_Renewal_Eligible_Core__c);

        // After Update 

        testSubs[0].SBQQ__Quantity__c=2;
        testSubs[1].SBQQ__Quantity__c=-2;

        update testSubs;

        con=[SELECT Id, All_Subs_RMA__c, Auto_Renewal_Eligible_Core__c,Description FROM Contract WHERE Id = :testContract.Id];
    
        Test.stopTest();

        System.assertEquals(true,con.All_Subs_RMA__c);
        System.assertEquals(false,con.Auto_Renewal_Eligible_Core__c);
    }

    @isTest
    static void unitTestAllSubsRMAFalse() {
        
        //AfterInsert
        Test.startTest();

        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                      .get('Customer').getRecordTypeId();

        Account testAccount = TestDataFactory.customers[0];
        testAccount.Terr_Theater__c='AMERICAS';
        testAccount.Terr_Region__c='WEST - REGION';        
        testAccount.RecordTypeId =recordTypeId;
        update testAccount;
        
        Product2 testProd = TestDataFactory.products[0];
        testProd.ProductCode='BEO-AES1-MSP';
        update testProd;

        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core',
        Reseller__c=null,Distributor__c=null,
        StartDate = System.Today(),All_Subs_RMA__c=false,Auto_Renewal_Status_Core__c=null);
        insert testContract;
                       
        List<SBQQ__Subscription__c>  testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id,SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123'),
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id,SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123')
        }; 

        insert testSubs;      

        Contract con=[SELECT Id, All_Subs_RMA__c, Auto_Renewal_Eligible_Core__c,Description FROM Contract WHERE Id = :testContract.Id];

        System.debug('testContract::'+testContract);

        System.assertEquals(false,con.All_Subs_RMA__c);
        System.assertEquals(true,con.Auto_Renewal_Eligible_Core__c);

        // After Update         
        testSubs[0].SBQQ__Quantity__c=2;

        update testSubs;

        con=[SELECT Id, All_Subs_RMA__c, Auto_Renewal_Eligible_Core__c,Description FROM Contract WHERE Id = :testContract.Id];
    
        Test.stopTest();

        System.assertEquals(false,con.All_Subs_RMA__c);
        System.assertEquals(true,con.Auto_Renewal_Eligible_Core__c);     
    }

    @isTest
    static void unitTestSendPEtoMS() {
        
        //AfterInsert
        Test.startTest();    

        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                      .get('Customer').getRecordTypeId();

        Account testAccount = TestDataFactory.customers[0];
        testAccount.Terr_Theater__c='AMERICAS';
        testAccount.Terr_Region__c='WEST - REGION';        
        testAccount.RecordTypeId =recordTypeId;
        update testAccount;
        
        Product2 testProd = TestDataFactory.products[0];
        testProd.ProductCode='BEO-AES1-MSP';
        update testProd;

        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core',
        Reseller__c=null,Distributor__c=null,
        StartDate = System.Today(),All_Subs_RMA__c=false,Auto_Renewal_Status_Core__c=null);
        insert testContract;
                       
        List<SBQQ__Subscription__c>  testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id,SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123'),
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id,SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123')
        }; 

        insert testSubs;      

        Contract con=[SELECT Id, All_Subs_RMA__c, Auto_Renewal_Eligible_Core__c,Description FROM Contract WHERE Id = :testContract.Id];
      
        // After Update         
          testSubs[0].SBQQ__Quantity__c=2;
       
          update testSubs;

          System.assertEquals(false,con.All_Subs_RMA__c);
          System.assertEquals(true,con.Auto_Renewal_Eligible_Core__c);   
           
    }

    @isTest  
    static void  statusActiveInactiveRMATrueTest(){

        // AfterInsert
        Test.startTest();
        Account testAccount = TestDataFactory.customers[0];
        
        Product2 testProd = TestDataFactory.products[0];
        testProd.ProductCode='BEO-AES1-MSP';
        update testProd;

        Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core', StartDate = System.Today(),All_Subs_RMA__c=false);
        insert testContract;
                       
        List<SBQQ__Subscription__c>  testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id,SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123'),
            new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id,SBQQ__Quantity__c = -1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123')
        }; 

        insert testSubs;      

        Contract con=[SELECT Id, status, All_Subs_RMA__c, Auto_Renewal_Eligible_Core__c,Description FROM Contract WHERE Id = :testContract.Id];

        System.debug('testContract::'+testContract);
        System.assertEquals(true,con.All_Subs_RMA__c);
        System.assertEquals(false,con.Auto_Renewal_Eligible_Core__c);

        // After Update 

        testSubs[0].SBQQ__Quantity__c=2;
        testSubs[1].SBQQ__Quantity__c=-2;

        update testSubs;

        con=[SELECT Id, status, All_Subs_RMA__c, Auto_Renewal_Eligible_Core__c,Description FROM Contract WHERE Id = :testContract.Id];
    
        Test.stopTest();

        System.assertEquals(true,con.All_Subs_RMA__c);
        System.assertEquals(false,con.Auto_Renewal_Eligible_Core__c);
        //System.assertEquals('InActive',con.status);
    }

    @isTest
    static void  statusActiveInactiveRMAFalseTest(){

      //AfterInsert
      Test.startTest();

      Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('Customer').getRecordTypeId();

      Account testAccount = TestDataFactory.customers[0];
      testAccount.Terr_Theater__c='AMERICAS';
      testAccount.Terr_Region__c='WEST - REGION';        
      testAccount.RecordTypeId =recordTypeId;
      update testAccount;
      
      Product2 testProd = TestDataFactory.products[0];
      testProd.ProductCode='BEO-AES1-MSP';
      update testProd;

      Contract testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core',
      Reseller__c=null,Distributor__c=null,
      StartDate = System.Today(),All_Subs_RMA__c=false,Auto_Renewal_Status_Core__c=null);
      insert testContract;
                     
      List<SBQQ__Subscription__c>  testSubs = new List<SBQQ__Subscription__c> {
          new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id,SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123',SBQQ__TerminatedDate__c=System.TODAY().addDays(1)),
          new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id,SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123',SBQQ__TerminatedDate__c=System.TODAY().addDays(1))
      }; 

      insert testSubs;      
      List<SBQQ__Subscription__c> SubResult = [SELECT Id,SBQQ__Contract__c,Active__c,SBQQ__TerminatedDate__c FROM SBQQ__Subscription__c WHERE (Active__c = TRUE OR SBQQ__TerminatedDate__c = NULL)];
      for(SBQQ__Subscription__c ag: SubResult){
            system.debug('SubResult'+ag);
        }    
      Contract con=[SELECT Id, status,All_Subs_RMA__c, Auto_Renewal_Eligible_Core__c,Description FROM Contract WHERE Id = :testContract.Id];

      System.debug('testContract::'+testContract);

      System.assertEquals(false,con.All_Subs_RMA__c);
      System.assertEquals(true,con.Auto_Renewal_Eligible_Core__c);

      // After Update         
    //   testSubs[0].SBQQ__Quantity__c=2;

    //   update testSubs;

      // con=[SELECT Id, status, All_Subs_RMA__c, Auto_Renewal_Eligible_Core__c,Description FROM Contract WHERE Id = :testContract.Id];
  
      Test.stopTest();

      System.assertEquals(false,con.All_Subs_RMA__c);
      System.assertEquals(true,con.Auto_Renewal_Eligible_Core__c);    
      System.assertEquals('Activated',con.status);
    }  

    /*
    @IsTest
    static  void unitTestUpdateReleventOrderFields() {
        Contract testContract = [Select ID From Contract LIMIT 1];
        SBQQ__QuoteLine__c testQuoteLine = [Select ID From SBQQ__QuoteLine__c];
        Order testOrder = [Select ID From Order LIMIT 1];
        List<OrderItem> orderLines = [Select ID From OrderItem Where OrderId =: testOrder.Id];
        
        Test.startTest();
            SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Contract__c = testContract.Id, SBQQ__OrderProduct__c = orderLines[0].Id, SBQQ__QuoteLine__c = testQuoteLine.Id);
            DynamicBusinessRuleSubscription.updateReleventOrderFields(new List<SObject> {testSub}, null);
        Test.stopTest();
    }
    */

    //Test not required since events are not fired for sub changes
    // @IsTest
    // static void unitTestForInsertOrUpdateSubscription() {
    //     Test.startTest();
            
    //         //========================Scenario:01:Subscription:Insert=============================//
    //         SBQQ__Subscription__c testSub1 = new SBQQ__Subscription__c(SBQQ__Quantity__c = 1); 
    //         insert testSub1;
            
    //         List<Integration_Snapshot__c> snapShotListDup = [Select id from Integration_Snapshot__c where Record_ID__c =: testSub1.id];
            
    //         //Assert Integration_Snapshot__c, whether it has been created or not after publishing Platform Event (Integration_Event__e).
    //         System.assert(snapShotListDup != null && !snapShotListDup.isEmpty());
            
    //         //========================Scenario:02:Subscription:Update=============================//
    //         //get notify on Update three field(s)(SBQQ__StartDate__c,SBQQ__EndDate__c,SBQQ__Quantity__c).
            
    //         List<SBQQ__Subscription__c> subListOld = new List<SBQQ__Subscription__c>([Select id,SBQQ__Quantity__c,SBQQ__StartDate__c,SBQQ__EndDate__c from SBQQ__Subscription__c where SBQQ__Quantity__c = 1]);
            
    //         List<SBQQ__Subscription__c> subListForUpdate = new List<SBQQ__Subscription__c>();
    //         for(SBQQ__Subscription__c sub: subListOld){
    //             sub.SBQQ__Quantity__c = 5;
    //             subListForUpdate.add(sub);
    //         }
            
    //         Database.update(subListForUpdate);
            
    //         //get created Integration_Snapshot__c for assert.
    //         List<Integration_Snapshot__c> snapShotList = [Select id from Integration_Snapshot__c where Record_ID__c =: subListForUpdate.get(0).id];
            
    //         System.assert(snapShotList != null && !snapShotList.isEmpty());
            
    //     Test.stopTest();
    // }

    /**
     * Test: Should update Contract and mark the Has SaaS product to true
     */
    // @isTest
    // private static void test_ShouldUpdateContractSaas(){
    //     TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
    //     //Create Parent Product
    //     Product2 testParentProduct                  = new Product2();
    //     testParentProduct.Name                      = 'Parent Product';
    //     testParentProduct.is_pst_enterprise__c      = true;
    //     testParentProduct.Base_SKU__c               = 'BEO001a';
    //     testParentProduct.ProductCode               = 'BEO001a';
    //     testParentProduct.SBQQ__SubscriptionType__c = 'Renewable'; 
    //     testParentProduct.SBCF_Form_Factor__c        = 'SaaS'  ;

    //     //Create a child product
    //     Product2 testChildProduct                     = new Product2();
    //     testChildProduct.Name                         = 'Child Product';
    //     testChildProduct.is_pst_enterprise__c         = true;
    //     testChildProduct.Base_SKU__c                  = 'TEST_SKU_CHILD';
    //     testChildProduct.ProductCode                  = 'TEST_SKU_CHILD';
    //     testChildProduct.SBQQ__SubscriptionPricing__c = 'Fixed Price';
    //     testChildProduct.SBQQ__SubscriptionTerm__c    = 1;
    //     testChildProduct.SBQQ__SubscriptionType__c    = 'Renewable'; 
    //     testChildProduct.SBCF_Form_Factor__c           = 'SaaS'  ; 

    //     insert new List<Product2>{testParentProduct, testChildProduct};

    //     //Account
    //     Account acc = TestDataFactory.customers[0];

    //     //Opportunity
    //     Opportunity testOpp = TestDataFactory.opportunities[0];

    //     //Quote
    //     SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, 
    //                                                   SBQQ__Primary__c      = true);

    //     insert testQuote;

    //     //Contract
    //     Contract testContractSaaS = new Contract(AccountId            = TestDataFactory.customers[0].Id, 
    //                                           Business_Group__c    = 'Core', 
    //                                           SBQQ__Quote__c       = testQuote.Id, 
    //                                           StartDate            = System.today(),
    //                                           ContractTerm         = 12,
    //                                           SBQQ__RenewalTerm__c = 12);

    //     Contract testContractRMA = new Contract(AccountId            = TestDataFactory.customers[0].Id, 
    //                                           Business_Group__c    = 'Core', 
    //                                           SBQQ__Quote__c       = testQuote.Id, 
    //                                           StartDate            = System.today(),
    //                                           ContractTerm         = 12,
    //                                           SBQQ__RenewalTerm__c = 12);                                              

    //     insert new List<Contract>{testContractSaaS, testContractRMA};
    //     //Subscription
    //     SBQQ__Subscription__c testSubRMA = new SBQQ__Subscription__c(SBQQ__Quantity__c             = 1, 
    //                                                                 Current_Quantity__c            = 1,
    //                                                                 SBQQ__Contract__c              = testContractRMA.Id, 
    //                                                                 SBQQ__SubscriptionStartDate__c = System.today(),
    //                                                                 SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
    //                                                                 SBQQ__Product__c               = testChildProduct.Id,
    //                                                                 SBQQ__RequiredByProduct__c     = testParentProduct.Id,
    //                                                                 SBQQ__Account__c               = acc.Id);
    //     insert testSubRMA;

    //     TriggerHandler.clearAllBypasses();  
    //     Test.startTest();
    //         //Subscription
    //         SBQQ__Subscription__c testSubSaaS = new SBQQ__Subscription__c(SBQQ__Quantity__c           = 1, 
    //                                                                    Current_Quantity__c            = 1,
    //                                                                    SBQQ__Contract__c              = testContractSaaS.Id, 
    //                                                                    SBQQ__SubscriptionStartDate__c = System.today(),
    //                                                                    SBQQ__SubscriptionEndDate__c   = System.today().addDays(90),
    //                                                                    SBQQ__Product__c               = testChildProduct.Id,
    //                                                                    SBQQ__RequiredByProduct__c     = testParentProduct.Id,
    //                                                                    SBQQ__Account__c               = acc.Id); 

    //         //RMA test
    //         testSubRMA.SBQQ__TerminatedDate__c = Date.today().addDays(-1);

    //         upsert new List<SBQQ__Subscription__c>{testSubSaaS, testSubRMA};
    //     Test.stopTest();   

    //     //get Contract
    //     Map<Id,Contract> updatedContractMap = new Map<ID, Contract>([SELECT Has_SaaS_Products__c,RMA_Detected__c FROM Contract WHERE Id in (:testContractSaaS.Id, :testContractRMA.Id)]);
    //     System.assert(updatedContractMap.get(testContractSaaS.Id).Has_SaaS_Products__c);
    //     System.assert(updatedContractMap.get(testContractRMA.Id).RMA_Detected__c);

    // }
}