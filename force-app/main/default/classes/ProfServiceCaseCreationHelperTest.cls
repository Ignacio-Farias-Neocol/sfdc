@isTest
public class ProfServiceCaseCreationHelperTest {
        
    @isTest
    static void testMethod01(){
        TriggerContextVariables.RUN_ORDER_TRIGGER = false;
        TriggerContextVariables.RUN_ORDERLINE_TRIGGER = false;
        
        //Create an Order
        List<Order> orders = TestDataFactory.orders;
        System.debug('##orders:: ' + JSON.serialize(orders));
        
        Contact con = new Contact();
        con.LastName = 'test';
        insert con;
        
        // create serial
        Serial__c serial = new Serial__c();
        serial.Activation_Date__c = Date.today();
        serial.Serial_Number__c = '607662';
        serial.Status__c = 'Active';            
        insert serial;
        
        List<Account> accList = [Select Id, Bill_To_Contact__c from Account];
        
        for(Account acc: accList){
            acc.Bill_To_Contact__c = con.Id;
        }
        update accList;
        
        List<Product2> productList = [Select Id, Is_ProfService_Product__c, Base_SKU__c from Product2];
        for(Product2 prod: productList){
            prod.Is_ProfService_Product__c = true;
            prod.Base_SKU__c = 'abc';
            prod.ProductCode = 'BPS-RMHC-CPC';
        }
        update productList;        
                
        //Create an order item for the order
        TestDataFactory.addOrderItem(orders);
        // TestDataFactory.addOrderItem(orders);
        List<Serial__c> serialList = TestDataFactory.serials;
        List<OrderItem> oiList = [Select Id, Professional_Services_Product__c, 
                                  Product2.Family, Product2.ProductCode, 
                                  SBQQ__RequiredBy__c, SBQQ__BundleRoot__c, 
                                  Base_SKU_for_ProfService_Case__c, 
                                  Serial__c, Parent_Product_Code__c, 
                                  PriceBookEntryId,
                                  is_A_La_Carte__c from OrderItem]; 
        System.debug('##oiList:: ' + JSON.serialize(oiList));
        System.debug('##serialList:: ' + JSON.serialize(serialList));   
        
        Test.startTest();
        
        OrderItem oItem = new OrderItem();
        oItem.OrderId = orders[0].Id;
        oItem.Quantity = 1; 
        oItem.UnitPrice = 1;         
        oItem.priceBookEntryId = oiList[0].priceBookEntryId;
        oItem.SBCF_Serial_Number__c = '607662';
        insert oItem;
        
        for(OrderItem oi: oiList){
            oi.SBCF_Serial_Number__c = '607662';
            oi.SBCF_Order_Line_Type__c = 'Renewal';
            oi.SBQQ__RequiredBy__c = oItem.Id;
        }
        update oiList;    
        
        for(Order ord: orders){
            ord.Status = 'Activated';
        }
        // update orders;
        System.debug('##orders2:: ' + JSON.serialize(orders));
        
        for(Order ord: orders){
            ord.Status = 'Placed';
        }        
        //update orders;
        System.debug('##orders3:: ' + JSON.serialize(orders)); 
        TriggerContextVariables.RUN_ORDERLINE_TRIGGER = true;
        
        
        List<Professional_Service_Case_Creation__e> psList = new List<Professional_Service_Case_Creation__e>();
        Set<Id> orderIdSet = new Map<Id, Order>([Select Id from Order]).keySet();
        
        for(Id orderId: orderIdSet){
            Professional_Service_Case_Creation__e ps = new Professional_Service_Case_Creation__e();
            ps.Order_Id__c = orderId;
            psList.add(ps);
        }
        
        
		List<Database.SaveResult> results = EventBus.publish(psList);
        Test.stopTest();
    }    
      
    /*
    @isTest
    static void testMethod02(){
		List<OrderItem> oiList = [Select Id, SBCF_Serial_Number__c, SBCF_Order_Line_Type__c, 
                                  OrderId, PriceBookEntryId from OrderItem];
        
        Test.startTest();
        OrderItem oItem = new OrderItem();
        oItem.OrderId = oiList[0].OrderId;
        oItem.Quantity = 1; 
        oItem.UnitPrice = 1;         
        oItem.priceBookEntryId = oiList[0].priceBookEntryId;
        oItem.SBCF_Order_Line_Type__c = 'New';
        insert oItem;     
        
        oItem.SBCF_Serial_Number__c = '607662';
        update oItem;
        Test.stopTest();
    }
	*/
}