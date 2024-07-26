@IsTest
public class AsyncUpdateSubDatesOnFulfillmentTest {

    @testSetup static void setup() {
        
		
		TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        
		Product2 product = TestDataFactory.products[0];
        product.SBCF_Is_Shipped__c = TRUE;
        update product;
					
		Id pricebookId = Test.getStandardPricebookId();
		PricebookEntry standardPrice = new PricebookEntry();
		standardPrice.Pricebook2Id = pricebookId;
		standardPrice.Product2Id = product.Id;
		standardPrice.UnitPrice = 1;
		standardPrice.IsActive = true;
		standardPrice.UseStandardPrice = false;
		insert standardPrice ;
		
		Account customer = new Account();
        customer.Is_Unit_Test__c  = true;
        customer.Name = 'Customer 001';
        customer.billingStreet = '415 Mission Street';
        customer.billingCity = 'San Francisco';
        customer.BillingCountryCode = 'US';
        customer.billingStateCode = 'CA';
        customer.billingPostalCode = '94105'; 
        customer.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        customer.Status__c = 'Active';
        customer.Territory_ID__c = '123';
        customer.AccountSource = 'Renewal';
        customer.Terr_Theater__c = 'APAC';
        INSERT customer;
        
        Contact rec = new Contact();
        rec.LastName = 'Test';
        rec.FirstName = 'TEst';
        rec.Email = 'test.test@test.com';
        rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
        rec.AccountId = customer.Id;
        rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
        rec.LeadSource = 'Renewal';
        INSERT rec;
                
        //Opportunity
        Opportunity oppt = new Opportunity();
        oppt.Name ='Oppty 001';
        oppt.AccountID = customer.Id;
        oppt.Bill_To_Account__c = customer.Id;
        oppt.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt.Model_Series__c = 'API';
        oppt.StageName = 'Accepted';
        oppt.Amount = 3000;
        oppt.CloseDate = System.today();
        oppt.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        oppt.Bypass_Validation__c = true;
        oppt.Is_Unit_Test__c = true;
        oppt.LeadSource = 'Renewal';
        oppt.BypassBusinessGroupValidation__c = True;
		oppt.Business_Group__c = 'Core';
        oppt.Street__c = 'Test Street';
        oppt.City__c = 'LA';
        oppt.State__c = 'CA';
        oppt.Country__c = 'United States';
        oppt.Country_ISO_Code__c = 'US';
        oppt.Zip_Postal_Code__c = '94945';
        oppt.Ship_To_Street__c = 'Test Shipping Street';
		oppt.Ship_To_City__c = 'LA';
		oppt.Ship_To_Country__c = 'United States';
        oppt.Shipping_Country_ISO_Code__c = 'US';
        oppt.Ship_To_Zip_Postal_Code__c = '94945';
        oppt.Ship_To_State__c = 'CA';
        INSERT oppt;
      
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Opportunity2__c = oppt.Id; 
        testQuote.SBQQ__Primary__c = true;
        testQuote.SBQQ__Status__c = 'Approved';
        testQuote.SBQQ__Type__c ='Quote';
        testQuote.Original_Contract_End_Date__c=System.today();
        testQuote.Available_on_Portal__c = true;
		testQuote.SBCF_Order_Type__c='New';
        testQuote.BypassValidation__c = TRUE;
        insert testQuote;
        
        Order testOrder = new Order();
        testOrder.AccountId = customer.id;
        testOrder.Name = 'test order';
        //newOrder.TotalAmount = 100;
        testOrder.Status = 'Draft';
        testOrder.Quote_Business_Group__c = 'MSP';
        testOrder.SBCF_Order_Type__c = 'Renewal';
        testOrder.EffectiveDate = System.today();
        testOrder.OpportunityId = oppt.id;
        testOrder.Has_RMA_Replace__c = false; 
        testOrder.Status = 'Draft';
        testOrder.Pricebook2Id = pricebookId;
        testOrder.Bill_To_Account__c = customer.id;
        testOrder.Bill_To_Contact__c = rec.id;
        testOrder.SBQQ__Quote__c = testQuote.Id;
        insert testOrder;

        OrderItem newOrderProduct = new OrderItem();
        newOrderProduct.SBQQ__Status__c = 'Draft';
        newOrderProduct.UnitPrice= 100;
        newOrderProduct.Quantity = 10;
        newOrderProduct.Product2Id = product.id;
        newOrderProduct.OrderId = testOrder.id;
        newOrderProduct.PricebookEntryId = standardPrice.id;
        newOrderProduct.SBCF_Order_Line_Type__c = 'New';
        insert newOrderProduct;
        
        test.startTest();
        Serial__c testSerial = new Serial__c(Serial_Number__c = '123', Order__c = testOrder.Id , Fulfillment_Date__c = System.Today(), Activation_Date__c = System.Today());
        insert testSerial;
        
        Contract testContract = new Contract(AccountId = customer.Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, StartDate = System.Today() , ContractTerm = 3);
        insert testContract;
        
        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(),SBQQ__OrderProduct__c = newOrderProduct.Id); 
        insert testSub;
        
        Assigned_Serial__c testAssigned = new Assigned_Serial__c(Serial__c = testSerial.Id, Subscription__c = testSub.Id);
        insert testAssigned;
        
        /*SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Product__c = product.Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 0,SBQQ__DiscountScheduleType__c = 'Slab',SBCF_Is_Shipped__c = true);
        insert testQuoteLine;*/
       test.stopTest();
       TriggerHandler.clearAllBypasses();      
    }
    
   @isTest
    static void processSyncDates_Test(){
        
        SBQQ__Subscription__c testSub2 = [Select ID,SBQQ__SubscriptionStartDate__c From SBQQ__Subscription__c];
        List<String> subList = new List<String>{testSub2.Id};
        Test.startTest();
        
        System.enqueueJob(new AsyncUpdateSubDatesOnFulfillment(subList));
        SBQQ__Subscription__c testSub1 = [Select ID,SBQQ__SubscriptionStartDate__c,SBQQ__SubscriptionEndDate__c,SBQQ__Contract__r.ContractTerm From SBQQ__Subscription__c];
        System.assertEquals( Date.today(),testSub1.SBQQ__SubscriptionStartDate__c);
       //// System.assertEquals( Date.today().addMonths(testSub1.SBQQ__Contract__r.ContractTerm).adddays(-1),testSub1.SBQQ__SubscriptionEndDate__c);
        Test.stopTest();
       
    }
}