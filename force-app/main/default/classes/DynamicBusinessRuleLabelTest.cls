@IsTest
private class DynamicBusinessRuleLabelTest {

    @IsTest
    static  void unitTest() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');

        // generate test data here e.g.
        List<Order> orders = TestDataFactory.orders;
        TriggerHandler.clearAllBypasses();

        test.startTest();

        List <OrderItem> orderItems = [select id, Original_Order_Number__c, Order_Number__c, RMA_Id__c from OrderItem];
        DynamicBusinessRuleLabel rule = new DynamicBusinessRuleLabel();
        rule.processRecords(null, null, orderItems, '', '', '');

        test.stopTest();

   }


}