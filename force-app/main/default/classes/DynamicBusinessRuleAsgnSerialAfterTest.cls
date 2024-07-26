@IsTest
public class DynamicBusinessRuleAsgnSerialAfterTest {
    
    @testSetup static void setup() {
       
        Product2 testProd = TestDataFactory.products[0];
        testProd.SBCF_Is_Shipped__c = TRUE;
        update testProd;
        
        Opportunity testOpp = TestDataFactory.opportunities[0];
         Test.startTest();
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true);
        insert testQuote;
        
        Order testOrder = TestDataFactory.orders[0];
        testOrder.SBQQ__Quote__c = testQuote.Id;
        update testOrder;
        
        TestDataFactory.addOrderItem(new List<Order>{testOrder});
        OrderItem oItem = [Select Id,SBCF_Order_Line_Type__c from OrderItem Limit 1];
        oItem.SBCF_Order_Line_Type__c = 'New';
        update oItem;
        
        Contract testContract = new Contract(AccountId = TestDataFactory.customers[0].Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, StartDate = System.Today() , ContractTerm = 3);
        insert testContract;
        Test.stopTest();
        //Test.startTest();
        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(),SBQQ__OrderProduct__c = oItem.Id); 
        insert testSub;
        //Test.stopTest();
    }
    
    
    @IsTest
    static void test_updateSubAndConStartDateWithSerialActDateTest() {
        Order testOrder = [Select Id From Order];
        SBQQ__Subscription__c testSub = [Select ID,SBQQ__SubscriptionStartDate__c From SBQQ__Subscription__c];
        
        
        //Contract testContract = [select Id, StartDate  from Contract limit 1];
        //testContract.StartDate = System.Today();
        //update testContract;
        
        Serial__c testSerial = new Serial__c(Serial_Number__c = '123', Order__c = testOrder.Id , Fulfillment_Date__c = System.Today().addDays(2), Activation_Date__c = System.Today());
        insert testSerial;
        Test.startTest();
        Assigned_Serial__c testAssigned = new Assigned_Serial__c(Serial__c = testSerial.Id, Subscription__c = testSub.Id);
        insert testAssigned;
        
        //SBQQ__Quote__c testQuote = [Select ID From SBQQ__Quote__c][0];
        //Product2 testProd = [Select ID From Product2][0];
        
        //SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 0,SBQQ__DiscountScheduleType__c = 'Slab',SBCF_Is_Shipped__c = true);
        //insert testQuoteLine;
        
        //List<Serial__c> testSerials = [Select ID From Serial__c];        
        //Test.startTest();
        //testSerials[0].Activation_Date__c = System.Today().addDays(10);
        //update testSerials;
        
        //List<Assigned_Serial__c> testAssignedSerials = [Select ID,Serial__c,Order__c,Subscription__c,Activation_Date__c From Assigned_Serial__c];        
        Map<Id,Assigned_Serial__c> testAssignedSerialsOldMap = new Map<Id,Assigned_Serial__c>();
        //testAssignedSerialsOldMap.put(testAssignedSerials[0].Id, testAssignedSerials[0]);
        
       // Map<Id,SObject> newRecordMap = new Map<Id,SObject> ();
        //DynamicBusinessRuleAssignedSerialAfter dynamicBusinessRuleAssignedSerialAfter = new DynamicBusinessRuleAssignedSerialAfter();
        //dynamicBusinessRuleAssignedSerialAfter.processRecords(newRecordMap, testAssignedSerialsOldMap, testAssignedSerials, '', 'POST','Insert');
        //SBQQ__Subscription__c testSub2 = [Select ID,SBQQ__SubscriptionStartDate__c From SBQQ__Subscription__c];
        //system.assertEquals(testSub2.SBQQ__SubscriptionStartDate__c, testAssignedSerials[0].Activation_Date__c);
        
        //Contract contractRecord = [Select Id, StartDate from Contract Limit 1];
        //system.assertEquals(testAssignedSerials[0].Activation_Date__c, contractRecord.StartDate);
        Test.stopTest();
    }
}