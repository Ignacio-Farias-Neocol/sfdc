@isTest
public class SendQuoteAlertFromOpportunityTest {
   
    @testSetup static void testSetupMethod(){
        
        Product2 testProd = TestDataFactory.products[0];
        testProd.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        testProd.SBQQ__SubscriptionTerm__c = 1;
        update testProd;

        Account testAccount = TestDataFactory.customers[0];
        testAccount.SBQQ__RenewalPricingMethod__c = 'Same';
        testAccount.Bill_To_Contact__c = 'Test Test';
        testAccount.Bill_To_Email__c = '123@123.com';
        update testAccount;

        Contract testContract = new Contract(AccountId = testAccount.Id, 
            Business_Group__c = 'MSP', 
            SBQQ__RenewalPricebookId__c = '01sf2000003FSkFAAW', 
            SBQQ__RenewalOpportunityRecordTypeId__c = '012f2000001261kAAA', 
            SBQQ__RenewalOpportunityStage__c = 'Not Contacted', 
            StartDate = System.Today() - 720, ContractTerm = 12);
        insert testContract;
        testContract.Status = 'Activated';
        update testContract;

        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today() - 720); 
        insert testSub;

        TriggerContextVariables.RUN_OPPORTUNITY_TRIGGER = false;
        Opportunity testOpp = TestDataFactory.opportunities[0];
        testOpp.RecordTypeID = '012f2000001261kAAA';
        testOpp.Business_Group__c = 'MSP';
        testOpp.CloseDate = System.Today();
        testOpp.SBQQ__RenewedContract__c = testContract.Id;
        testOpp.SBQQ__Renewal__c = true;
        testOpp.Contract_Error_Check__c = '123';
        testOpp.Bill_To_Account__c = testAccount.Id;
        update testOpp;
        // TriggerContextVariables.RUN_OPPORTUNITY_TRIGGER = true;

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Renewal');
        insert testQuote;

        Order testOrder = TestDataFactory.orders[0];
        testOrder.OpportunityId = testOpp.Id;
        testOrder.Contract_Error_Check__c = '123';
        testOrder.BillingCity = 'Denver';
        testOrder.BillingPostalCode = '80000';
        testOrder.BillingState = 'Colorado';
        testOrder.BillingCountry = 'United States';
        testOrder.ShippingCity = 'Denver';
        testOrder.ShippingPostalCode = '80000';
        testOrder.ShippingState = 'Colorado';
        testOrder.ShippingCountry = 'United States';

        update testOrder;
        
    }
   
    @isTest static void unitTestPositive(){
        List<Opportunity> optyList = new List<Opportunity>([Select id from Opportunity where Recordtype.Name = 'Renewal' LIMIT 10]);
        System.debug('optyList::'+JSON.serialize(optyList));
        if(!optyList.isEmpty()){
            List<Id> oppIds = new List<Id>();
            for(Opportunity opp: optyList){
                oppIds.add(opp.Id);
            }
            System.debug('oppIds::'+JSON.serialize(oppIds));
            //Assert code can execute multiple record(s).
            
            Test.startTest();
            TriggerContextVariables.RUN_OPPORTUNITY_TRIGGER = false;
            SendQuoteAlertFromOpportunity.sendQuoteFromOpportunity(oppIds);
            Test.stopTest();
        }
    }
}