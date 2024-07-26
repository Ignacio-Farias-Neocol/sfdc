@IsTest
private class DynamicBusinessRuleSerialAfterTest {
    @testSetup static void setup() {
        
        Product2 testProd = TestDataFactory.products[0];
        testProd.SBCF_Is_Shipped__c = TRUE;
        update testProd;
        
        Opportunity testOpp = TestDataFactory.opportunities[0];
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true);
        insert testQuote;
        
        Order testOrder = TestDataFactory.orders[0];
        testOrder.SBQQ__Quote__c = testQuote.Id;
        update testOrder;
        
        TestDataFactory.addOrderItem(new List<Order>{testOrder});
        OrderItem oItem = [Select Id,SBCF_Order_Line_Type__c from OrderItem Limit 1];
        oItem.SBCF_Order_Line_Type__c = 'New';
        update oItem;
        Test.startTest();
        Contract testContract = new Contract(AccountId = TestDataFactory.customers[0].Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, StartDate = System.Today() , ContractTerm = 3);
        insert testContract;
        
        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(),SBQQ__OrderProduct__c = oItem.Id); 
        insert testSub;
        Test.stopTest();
    }
    
    @IsTest
    static  void processRecords_Test() {
        Order testOrder = [Select ID From Order];
        SBQQ__Subscription__c testSub = [Select ID From SBQQ__Subscription__c];
        
        
        Serial__c testSerial = new Serial__c(Serial_Number__c = '123', Order__c = testOrder.Id , Fulfillment_Date__c =System.Today().addDays(2),Activation_Date__c =System.Today(), Status__c = 'Active');
        insert testSerial;
        
        Assigned_Serial__c testAssigned = new Assigned_Serial__c(Serial__c = testSerial.Id, Subscription__c = testSub.Id);
        insert testAssigned;
        Test.startTest();
        SBQQ__Quote__c testQuote = [Select ID From SBQQ__Quote__c][0];
        Product2 testProd = [Select ID From Product2][0];
        
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 0);
        insert testQuoteLine;
        
        List<Serial__c> testSerials = [Select ID,Serial_Number__c,Order__c,Fulfillment_Date__c,Activation_Date__c From Serial__c];        
        Map<Id,Serial__c> testSerialsOldMap = new Map<Id,Serial__c>([Select ID,Serial_Number__c,Order__c,Fulfillment_Date__c,Activation_Date__c From Serial__c]);
        
       // testSerials[0].Activation_Date__c = System.Today().addDays(10);
       // testSerials[0].Fulfillment_Date__c = System.Today().addDays(10);
       // update testSerials;
        
        
        Map<Id,SObject> newRecordMap = new Map<Id,SObject> ();
        DynamicBusinessRuleSerialAfter dynamicBusinessRuleSerialAfter = new DynamicBusinessRuleSerialAfter();
        dynamicBusinessRuleSerialAfter.processRecords(newRecordMap,testSerialsOldMap, testSerials,'', 'POST','Update');
        SBQQ__Subscription__c testSub1 = [Select ID,SBQQ__SubscriptionStartDate__c,SBQQ__SubscriptionEndDate__c,SBQQ__Contract__r.ContractTerm From SBQQ__Subscription__c];
        System.assertEquals( System.today(),testSub1.SBQQ__SubscriptionStartDate__c);
        Test.stopTest();
        //SFDC -16331
        //testSerial.Status__c = 'Inactive';
        //update testSerial;


        
    }
    
    // @IsTest
    /*static  void AsyncCheckFulfillmentDateAndSyncSubs_Test() {
        
        Test.startTest();
        List<Serial__c> testSerials = [Select ID From Serial__c];        
        testSerials[0].Fulfillment_Date__c = System.Today().addDays(1);
        testSerials[0].Activation_Date__c = System.Today().addDays(10);
        update testSerials;
        List<Assigned_Serial__c> listOfAssignedSerials = [Select Id From Assigned_Serial__c where Serial__c =:testSerials[0].Id and Subscription__c != null];
        system.assertNotEquals(listOfAssignedSerials.size(), 0);
        Test.stopTest();
    }*/
}