@isTest(seeAllData = FALSE)
public with sharing class DynamicBusinessRuleOrderProductRMATest {
    
    public testMethod static void testProcessRecords(){
        LogModel log = LogModel.startLog('DynamicBusinessRuleOrderProductRMATest', 'testProcessRecords', LogModel.LOG_CATEGORY_APEX);
        system.debug('Method testProcessRecords');
        try{
            Test.startTest();
            TriggerHandler.clearAllBypasses();
            List<User> contextuser = [select id, name from User where id =: UserInfo.getUserId()];
            List<Product2> products = TestDataFactory.products;
            Order o = TestDataFactory.orders[0];
            List<OrderItem> orderItemList = new List<OrderItem>();
            List<OrderItem> orderItLstUpdate = new List<OrderItem>();
            List<OrderItem> orderItems = [select id, SBQQ__RequiredBy__c, RMA_Id__c from OrderItem where orderId  = :o.id];
            System.debug('orderItems are:' +orderItems);
            OrderItem orItem = new OrderItem();
            orItem.RMA_Id__c = 'testRMA';
            orItem.orderId = o.id;
            orItem.SBQQ__RequiredBy__c = orderItems[0].id;
            orderItemList.add(orItem);
            if(Test.isRunningTest() && !orderItemList.isEmpty()) {
                insert orderItemList;
            }
            for(OrderItem orIt : orderItems){
                orIt.SBQQ__RequiredBy__c = orderItemList[0].id;
                orIt.RMA_Id__c = '';
                orderItLstUpdate.add(orIt);
            }
            System.runAs(contextuser[0]){
                if(Test.isRunningTest() && !orderItLstUpdate.isEmpty()) {
                    update orderItLstUpdate;
                }
            }
            Test.stopTest();
        }Catch(Exception e){
            log.addExceptionLog(e);
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    }
        
}