@isTest
public with sharing class DeleteContractsSubsCancelledOrderTest {
   
    static void setupData(){
        
        
    }
    public testMethod static void testDeleteContractSubs(){
        try{
            List <Account> customers = TestDataFactory.customers;
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

            Asset testAsset = TestDataFactory.assets[0];
            testAsset.Appliance_Line_Type__c = 'Hardware only (pool)';
            update testAsset;             
            
            Order order = new Order();
            order.AccountId = customers[0].Id;
            order.Status = 'Draft';
            order.EffectiveDate = system.today();
            order.Pricebook2Id =  pricebookId ;
            insert order;
            
            OrderItem orderItem = new OrderItem();
            orderItem.OrderId = order.id;
            orderItem.Quantity = 24;
            orderItem.UnitPrice = 240;
            orderItem.Product2id = product.id;
            orderItem.PricebookEntryId = standardPrice.id;
            insert orderItem; 

            Contract testContract = new Contract();
            testContract.AccountId = customers[0].Id;
            testContract.Business_Group__c = 'Core';
            testContract.StartDate = System.Today();
            testContract.SBQQ__Order__c = order.id;
            insert testContract;

            List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
                new SBQQ__Subscription__c(SBQQ__RootId__c = testAsset.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), Related_Order__c = order.id),
                new SBQQ__Subscription__c(SBQQ__RootId__c = testAsset.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), Related_Order__c = order.id)
            };
            insert testSubs;
            Test.startTest();
            List<Order> lstOrder = [select id, Status from Order where id =:order.id];
            if(!lstOrder.isEmpty()){
                for(Order o : lstOrder){
                    //o.status = 'Cancelled';
					o.Is_Order_Cancelled__c = TRUE;
                }
            DeleteContractsSubsCancelledOrder.processRecords(null, null, lstOrder, null, null, 'Update');
               // update lstOrder;
            }
            Test.stopTest();

        }Catch(Exception e){
            System.debug('Exception occurred at:' +e.getMessage());
        }
    }
}