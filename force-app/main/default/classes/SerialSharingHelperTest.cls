/***** SFDC-18733******/
@IsTest

public class SerialSharingHelperTest {

    @testSetup static void setup() {
        Product2 testProd = TestDataFactory.products[0];
        //testProd.SBCF_Is_Shipped__c = TRUE;
        //update testProd;
        
           PricebookEntry entry = new PricebookEntry();
                    entry.Pricebook2Id = TestDataFactory.priceBookId; 
                    entry.Product2Id = testProd.Id; 
                    entry.UnitPrice = 1; 
                    entry.IsActive = true; 
                   
                    entry.UseStandardPrice = false; // useStandardPrice; 
                    
                  
        insert entry;  
        
        Opportunity testOpp = TestDataFactory.opportunities[0];
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true,SBQQ__Type__c='Quote',SBCF_Order_Type__c='New');
        insert testQuote;
        
        test.startTest();
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 0,SBQQ__DiscountScheduleType__c = 'Slab',SBCF_Is_Shipped__c = true);
        insert testQuoteLine;
        
        
        /*Order testOrder = TestDataFactory.orders[0];
        testOrder.SBQQ__Quote__c = testQuote.Id;
        update testOrder;*/
        
        Order testOrder = new Order();
        testOrder.AccountId = testOpp.Accountid;
        testOrder.EffectiveDate = Date.today();
        testOrder.Pricebook2Id = TestDataFactory.priceBookId;
        testOrder.description = 'Order 1' ;
        testOrder.Status = 'Draft';
        testOrder.Type = 'New'; // new order
        testOrder.OpportunityId = testOpp.Id;
        insert testOrder;
        
        //TestDataFactory.addOrderItem(new List<Order>{testOrder});
        //OrderItem oItem = [Select Id,SBCF_Order_Line_Type__c from OrderItem Limit 1];
        //oItem.SBCF_Order_Line_Type__c = 'New';
        //update oItem;
        
        
                  
        OrderItem rec = new OrderItem();  
        rec.orderId = testOrder.Id;
        rec.Quantity = 1; 
        rec.UnitPrice = 1; 
        rec.PricebookEntryId = entry.Id; 
        rec.SBCF_Order_Line_Type__c = 'New';
        rec.SBQQ__QuoteLine__c = testQuoteLine.Id;
        insert rec;
                
        
        
        Serial__c testSerial = new Serial__c(Serial_Number__c = '123', Order__c = testOrder.Id , Fulfillment_Date__c = System.Today(), Activation_Date__c = System.Today());
        insert testSerial;
        
        Account acc =  TestDataFactory.customers[0];
        Contract testContract = new Contract(AccountId = acc.Id, Business_Group__c = 'Core', SBQQ__Quote__c = testQuote.Id, StartDate = System.Today() , ContractTerm = 3,Status='Draft');
        //testContract.Distributor__c = TestDataFactory.customers[1].Id;
        insert testContract;
        
        SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(),SBQQ__OrderProduct__c = rec.Id); 
        insert testSub;
        test.stopTest();
        
        Assigned_Serial__c testAssigned = new Assigned_Serial__c(Serial__c = testSerial.Id, Subscription__c = testSub.Id);
        insert testAssigned;
        
        Contact customerContact = new Contact(Email='July@testcon.com',LastName ='July',AccountId = acc.Id);
        insert customerContact;

        
    }
    
   @isTest
    static void processsharing_Test(){
        Profile pf= [Select Id from profile where Name='Barracuda Partner Core Admin'];
        map<Id,Serial__c> serialId = new map<Id,Serial__c>([Select Id from Serial__c]);
        List<Id> serialids = new List<Id>();
        serialids.addall(serialId.keyset());
       // List <Account> accounts = TestDataFactory.partners;
        
        
         
       
        test.startTest();
        Account customerAccount = [Select Id from Account limit 1];
        Contact customerContact = [Select Id,AccountId from COntact where AccountId=:customerAccount.Id limit 1];
        
        
         User user = new User(alias = 'Julytest', email='Julytest@test.com',
                    emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                    localesidkey='en_US', profileid = pf.id, country='United States',IsActive =true,
                    ContactId = customerContact.Id,
                    timezonesidkey='America/Los_Angeles', username='Julytest@123.com');
         insert user;
         
         //user = [Select Contact.AccountId,IsActive from User where Id=:user.Id];
        // Contract testContract = [Select Id from Contract];
         test.Stoptest();  
         SerialSharinghelper.CreateSerialSharing(serialIds,'Update');
         //testContract.Distributor__c = customerAccount.Id;
         //update testContract;
         

       
    }
}