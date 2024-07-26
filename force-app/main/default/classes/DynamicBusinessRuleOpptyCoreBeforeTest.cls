@isTest
public with sharing class DynamicBusinessRuleOpptyCoreBeforeTest{   

/* @isTest
    static void process_Test(){
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); 
        
         Product2 testProd = TestDataFactory.products[0];
        testProd.SBCF_Is_Shipped__c = TRUE;
        update testProd;
        List <Account> customers = TestDataFactory.customers;
         Opportunity testOpp = TestDataFactory.createOpportunity(customers[0]);
        testOpp.StageName = 'Closed Won';
        testOpp.Business_Group__c = 'MSP';
        
        insert testOpp;

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true,SBQQ__Type__c='Quote',SBCF_Order_Type__c='New');
        insert testQuote;
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 0,SBQQ__DiscountScheduleType__c = 'Slab',SBCF_Is_Shipped__c = true);
        insert testQuoteLine;
        
        testOpp.StageName = 'Closed Won';
        testOpp.Business_Group__c = 'MSP';
        Update testOpp;
        DynamicBusinessRuleOpptyCoreBefore testcls = new DynamicBusinessRuleOpptyCoreBefore();
        testcls.processRecords(new Map<Id,sobject>{testOpp.Id=>testOpp},null,new List<sobject>{testOpp},'','1','INsert'); */

  @isTest
  private static void AmendmentOpptyNaming(){

    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');  
  
        List <Account> customers = TestDataFactory.customers;   
        customers[0].Bill_To_Contact__c = 'Test Test';
        customers[0].Bill_To_Email__c = '123@123.com';
        update customers[0];

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

        Contract testContract = new Contract(AccountId = customers[0].Id, 
        Business_Group__c = 'Core', 
        SBQQ__RenewalPricebookId__c = '01sf2000003FSkFAAW', 
        SBQQ__RenewalOpportunityRecordTypeId__c = '012f2000001261kAAA', 
        SBQQ__RenewalOpportunityStage__c = 'Not Contacted', 
        StartDate = System.Today() - 720, ContractTerm = 12);
        insert testContract;

        Contact rec = new Contact();
        rec.LastName = 'Test';
        rec.FirstName = 'Test';
        rec.Email = 'test.test@test.com';
        //rec.Contact_Status__c = 'Active';
       // rec.TRDPS__One_Source_Restriction_Status_Code__c = 'Clear';  
        rec.AccountId = customers[0].Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';
        insert rec;

 TriggerHandler.clearAllBypasses();   
        Opportunity testOpp1=new Opportunity(AccountId = customers[0].Id,
        Business_Group__c = 'Core', 
        CloseDate = System.Today(),
        SBQQ__RenewedContract__c = testContract.Id,
        SBQQ__Renewal__c = false,
        Bill_To_Account__c = customers[0].Id,
        Primary_Contact__c = rec.Id,
        StageName = 'Accepted',
        Name = 'Test Opportunity'
        );

        insert testOpp1; 

        testContract.Status = 'Activated';
        testContract.SBQQ__RenewalOpportunity__c=testOpp1.Id;
        update testContract;        

        Opportunity testOpp2=new Opportunity(AccountId = customers[0].Id,
        Business_Group__c = 'Core', 
        CloseDate = System.Today(),
        SBQQ__AmendedContract__c = testContract.Id,
        SBQQ__Renewal__c = false,
        Bill_To_Account__c = customers[0].Id,
        Primary_Contact__c = rec.Id,
        StageName = 'Accepted',
        Name = 'Test Opportunity'
        );

        insert testOpp2;            
  }   
           // Test method to test UpdateEarliestSubEndDate method
           
    static testMethod void testUpdateEarliestSubEndDate() {
               //create test Account
    List <Account> customers = TestDataFactory.customers;
        customers[0].Bill_To_Contact__c = 'Test Test';
        customers[0].Bill_To_Email__c = '123@123.com';
        update customers[0];
        
        Contract testContract = new Contract(AccountId = customers[0].Id,
        Business_Group__c = 'Core',
        SBQQ__RenewalPricebookId__c = '01sf2000003FSkFAAW',
        SBQQ__RenewalOpportunityRecordTypeId__c = '012f2000001261kAAA',
        SBQQ__RenewalOpportunityStage__c = 'Not Contacted',
        StartDate = System.Today() - 720,
        ContractTerm = 12);
        insert testContract;

        Contact rec = new Contact();
        rec.LastName = 'Test';
        rec.FirstName = 'Test';
        rec.Email = 'test.test@test.com';
       // rec.TRDPS__One_Source_Restriction_Status_Code__c = 'Clear';
        rec.AccountId = customers[0].Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';
        insert rec;
        
        List<Opportunity> testOpportunities = new List<Opportunity>();
       // for(Integer i = 0; i < 3; i++) {
        Opportunity opp1 = new Opportunity(Name = 'Test Opp 1 ',
        AccountId = customers[0].Id,
        Business_Group__c = 'Core',
        CloseDate = System.Today(),
        SBQQ__RenewedContract__c = testContract.Id,
        SBQQ__Renewal__c = true,
        Bill_To_Account__c = customers[0].Id,
        Primary_Contact__c = rec.Id,StageName = 'Accepted');

            testOpportunities.add(opp1);
       // }
        insert testOpportunities;
       
        // Create test Subscriptions
        List<SBQQ__Subscription__c> testSubscriptions = new List<SBQQ__Subscription__c>();
        for(Integer i = 0; i < 4; i++) {
            SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(SBQQ__Contract__c = testContract.Id,
                                                                            SBQQ__SubscriptionEndDate__c = Date.today().addDays(i),
                                                                            SBQQ__RenewalQuantity__c = 1,SBQQ__Account__c  = testOpportunities[0].accountId,
                                                                            SBCF_Serial_Number__c = null,Status__c = 'Active',SBQQ__Quantity__c=1);
            testSubscriptions.add(subscription);
        }
        insert testSubscriptions;
        Test.startTest();
        Date minimumDate=null;
        DynamicBusinessRuleOpptyCoreBefore.UpdateEarliestSubEndDate(testOpportunities);Test.stopTest();
       
        List<Opportunity> updatedOpportunities = [SELECT Id, Earliest_Subscription_End_Date__c FROM Opportunity WHERE Id IN :testOpportunities];
       
       /* for(Opportunity opp : updatedOpportunities) {
            System.assertEquals(testSubscriptions[0].SBQQ__SubscriptionEndDate__c, opp.Earliest_Subscription_End_Date__c, 'Earliest Subscription End Date should be set correctly');
        }*/
    }

}