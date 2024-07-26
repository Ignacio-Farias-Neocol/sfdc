@isTest
private class UpdateACVforContractTest {

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

        // Create amendment opportunities with a reference to Contract records
        Opportunity amendmentOpportunities = new Opportunity();
        amendmentOpportunities.AccountId = customers[0].Id;
        amendmentOpportunities.Business_Group__c = 'Core'; 
        amendmentOpportunities.CloseDate = System.Today();
        amendmentOpportunities.SBQQ__AmendedContract__c = testContract.Id;
       amendmentOpportunities.SBQQ__Renewal__c = false;
        amendmentOpportunities.Bill_To_Account__c = customers[0].Id;
        amendmentOpportunities.Primary_Contact__c = rec.Id;
        amendmentOpportunities.StageName = 'Accepted';
        amendmentOpportunities.Name = 'Test Opportunity';
       
         for(Address__c addr : [SELECT id, 
                                      Street__c, 
                                      City__c, 
                                      State_Name__c, 
                                      Country_Name__c, 
                                      Zip_Postal_Code__c,
                                      Type__c
                              FROM Address__c 
                              WHERE Account__c = :customers[0].Id ]){
          if(addr.Type__c == 'Billing'){
            System.debug('Inside billing');
            amendmentOpportunities.Billing_Address__c = addr.Id;
            amendmentOpportunities.Street__c = addr.Street__c;
            amendmentOpportunities.City__c = addr.City__c;
            amendmentOpportunities.State__c = addr.State_Name__c;
            amendmentOpportunities.Country__c = addr.Country_Name__c;
            amendmentOpportunities.Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
          }
          else if(addr.Type__c == 'Shipping'){
            System.debug('Inside shipping');
            amendmentOpportunities.Shipping_Address__c = addr.Id;
            amendmentOpportunities.Ship_To_Street__c = addr.Street__c;
            amendmentOpportunities.Ship_To_City__c = addr.City__c;
            amendmentOpportunities.Ship_To_State__c = addr.State_Name__c;
            amendmentOpportunities.Ship_To_Country__c = addr.Country_Name__c;
            amendmentOpportunities.Ship_To_Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
          }
        }

      
        insert amendmentOpportunities;
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = amendmentOpportunities.Id, SBQQ__Primary__c = true,SBQQ__Type__c = 'Amendment');
        insert testQuote;
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Product__c = product.Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 0,SBCF_Is_Shipped__c = true);
        insert testQuoteLine;
        testQuote.ApprovalStatus__c = 'Approved';
        update testQuote;

        // Start the batch job
        Test.startTest();
        List<Contract> conList= new List<Contract>();
        conList.add(testContract);
        UpdateACVforContract obj=new UpdateACVforContract();
        Database.QueryLocator ql= obj.start(null);
        obj.execute(null,conList);
        obj.finish(null);
       
        Test.stopTest();
       
    }
}