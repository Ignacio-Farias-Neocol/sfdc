@isTest
public with sharing class CloseOpptyAllSubsciptionsRMATest {
    
    @testSetup static void setup() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        
		Product2 product = new Product2();
		product.Name = 'CR-ADJ-Other';
		product.Description='CR-ADJ-Other';
		product.productCode = 'CR-ADJ-Other';
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
        INSERT oppt;
        
        Opportunity oppt02 = new Opportunity();
        oppt02.Name ='Oppty 002';
        oppt02.AccountID = customer.Id;
        oppt02.Bill_To_Account__c = customer.Id;
        oppt02.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt02.Model_Series__c = 'API';
        oppt02.StageName = 'Accepted';
        oppt02.Amount = 3001;
        oppt02.CloseDate = System.today();
        oppt02.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        oppt02.Bypass_Validation__c = true;
        oppt02.Is_Unit_Test__c = true;
        oppt02.LeadSource = 'Renewal';
        oppt02.BypassBusinessGroupValidation__c = True;
		oppt02.Business_Group__c = 'MSP';
        INSERT oppt02;

        Opportunity oppt03 = new Opportunity();
        oppt03.Name ='Oppty 003';
        oppt03.AccountID = customer.Id;
        oppt03.Bill_To_Account__c = customer.Id;
        oppt03.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        oppt03.Model_Series__c = 'API';
        oppt03.StageName = 'Accepted';
        oppt03.Amount = 3001;
        oppt03.CloseDate = System.today();
        oppt03.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        oppt03.Bypass_Validation__c = true;
        oppt03.Is_Unit_Test__c = true;
        oppt03.LeadSource = 'Renewal';
        oppt03.BypassBusinessGroupValidation__c = True;
		oppt03.Business_Group__c = 'MSP';
        INSERT oppt03;
		
		Contract contract01 = new Contract();
		contract01.AccountId = oppt.accountId;
		contract01.SBQQ__Opportunity__c = oppt.Id;
		contract01.All_Subs_RMA__c = true;
		insert contract01;

		Contract contract02 = new Contract();
		contract02.AccountId = oppt.accountId;
		contract02.SBQQ__Opportunity__c = oppt.Id;
		//contract02.SBQQ__Quote__c = quotes[0].id;
		contract02.All_Subs_RMA__c = true;
		insert contract02;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Opportunity2__c = oppt02.Id; 
        testQuote.SBQQ__Primary__c = true;
        testQuote.SBQQ__Status__c = 'Approved';
        testQuote.SBQQ__Type__c ='Renewal';
        testQuote.Original_Contract_End_Date__c=System.today();
        testQuote.Available_on_Portal__c = true;
        insert testQuote;
        
        SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c();
        qli.SBQQ__StartDate__c = System.today()-10;
        qli.SBQQ__EndDate__c = System.today()+10;
        qli.SBQQ__Quote__c = testQuote.Id;
        qli.SBCF_Serial_Number__c = 'SERIAL001';
        qli.SBQQ__Product__c = product.id;
        SBQQ.TriggerControl.disable();
        insert qli;
        SBQQ.TriggerControl.enable();
        List<OpportunityLineItem> oppLines = new List<OpportunityLineItem>();
        OpportunityLineItem oli = new OpportunityLineItem(
     	    OpportunityId = oppt02.id,
            SBQQ__QuoteLine__c = qli.id,
     		Quantity = 5,
     		PricebookEntryId = standardPrice.Id,
     		TotalPrice = 5 * standardPrice.UnitPrice);
        oppLines.add(oli);
        OpportunityLineItem oli02 = new OpportunityLineItem(
     	    OpportunityId = oppt02.id,
            SBQQ__QuoteLine__c = qli.id,
     		Quantity = 5,
     		PricebookEntryId = standardPrice.Id,
     		TotalPrice = 5 * standardPrice.UnitPrice);
        oppLines.add(oli02);
		insert oppLines;
        TriggerHandler.clearAllBypasses();      

    } 
    
    @isTest static void test_BatchProcess() {
		List<Contract> lstContract = [select id from contract];
        Map<Id, Opportunity> mapOpp = new Map<id, Opportunity>();
        List<Opportunity> lstOpp = [select id, SBQQ__AmendedContract__c, Business_Group__c, SBQQ__RenewedContract__c, StageName, Closed_Lost_Reason__c, Closed_Lost_Reason_Comment__c from Opportunity];
		for(Opportunity opp : lstOpp){
			opp.SBQQ__RenewedContract__c = lstContract[0].id;
			opp.SBQQ__AmendedContract__c = lstContract[1].id;
		}
        update lstOpp;
        Test.startTest();
        ID batchId = Database.executeBatch(new CloseOpptyAllSubsciptionsRMA(), 200);
        Test.stopTest();
    }

}