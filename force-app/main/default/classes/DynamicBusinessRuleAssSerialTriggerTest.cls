/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-07-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
private class DynamicBusinessRuleAssSerialTriggerTest {
    @testSetup static void setup() {
         Test.startTest();
        Product2 testProd = TestDataFactory.products[0];
        testProd.SBCF_Is_Shipped__c = TRUE;
        update testProd;

        Opportunity testOpp = TestDataFactory.opportunities[0];
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c ();
        testQuote.SBQQ__Opportunity2__c = testOpp.Id;
        testQuote.SBQQ__Primary__c = true;
        
        insert testQuote;

        Contract testContract = new Contract(AccountId = TestDataFactory.customers[0].Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, StartDate = System.Today());
        testContract.contractterm = 12;
        testContract.EndDate = System.Today().addMonths(12);
        insert testContract;

        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today()); 
        insert testSub;
        Test.stopTest();
    }

    @IsTest
    static  void unitTest() {
        SBQQ__Quote__c testQuote = [Select ID From SBQQ__Quote__c][0];
        Product2 testProd = [Select ID From Product2][0];
        SBQQ__Subscription__c testSub = [Select ID From SBQQ__Subscription__c][0];
        Test.startTest();
         
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 0, SBCF_Is_Shipped__c = TRUE, Appliance_Line_Type__c = 'Standard');
        insert testQuoteLine; 

       

            Serial__c testSerial = new Serial__c(Serial_Number__c = '123', Activation_Date__c = System.Today().addDays(2));
            insert testSerial;

            Assigned_Serial__c testAssigned = new Assigned_Serial__c(Serial__c = testSerial.Id, Subscription__c = testSub.Id);
            insert testAssigned;

        Test.stopTest();
    }
}