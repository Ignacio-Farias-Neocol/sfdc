@isTest
public class UpdateEarliestSubscriptionEndDateTest {
  @isTest
    static void testBatchExecution() {
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');  
  	   	 TriggerHandler.bypass('DynamicBusinessRuleQuoteLineBefore');
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
        rec.AccountId = customers[0].Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';
        insert rec;

 TriggerHandler.clearAllBypasses();   
        Opportunity testOpp1=new Opportunity(AccountId = customers[0].Id,
        Business_Group__c = 'Core', 
        CloseDate = System.Today(),
        SBQQ__RenewedContract__c = testContract.Id,
        Earliest_Subscription_End_Date__c= null,     
        SBQQ__Renewal__c = false,
        Bill_To_Account__c = customers[0].Id,
        Primary_Contact__c = rec.Id,
        StageName = 'Accepted',
        Name = 'Test Opportunity'
        );

        insert testOpp1; 
         testContract.Status = 'Activated';
		testContract.SBQQ__Opportunity__c=testOpp1.id;
        update testContract;

                // Create test Subscriptions
        List<SBQQ__Subscription__c> testSubscriptions = new List<SBQQ__Subscription__c>();
        for(Integer i = 0; i < 4; i++) {
            SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(SBQQ__Contract__c = testContract.Id,
                                                                            SBQQ__SubscriptionEndDate__c = Date.today().addDays(i),
                                                                            SBQQ__RenewalQuantity__c = 2,SBQQ__Account__c  = testOpp1.accountId,
                                                                            SBCF_Serial_Number__c = null,Status__c = 'Active',SBQQ__Quantity__c=1);
            testSubscriptions.add(subscription);
        }
        insert testSubscriptions;

        
        // Start the batch job
        Test.startTest();
        
        List<Opportunity> opptyList= new List<Opportunity>();
        opptyList.add(testOpp1);
       UpdateEarliestSubscriptionEndDate obj=new UpdateEarliestSubscriptionEndDate();
        Database.QueryLocator ql= obj.start(null);
        obj.execute(null,opptyList);
        obj.finish(null);
       
        Test.stopTest();
       
    }
}