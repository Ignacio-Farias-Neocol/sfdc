@isTest
public class CreateProfServiceCaseByOrderTest {
    
    @testSetup 
    static void setupData(){
        TestDataFactory.createRealData = false; // don't create real data by default
        TestDataFactory.suffixNumber = 100;
        
        SBQQ__ProductOption__c productOption = new SBQQ__ProductOption__c();
        productOption.SBQQ__Number__c = 1;
        insert productOption;     
        
        List <Account> partners = TestDataFactory.partners;
        List <Account> customers = TestDataFactory.customers;
        List <Contact> customerContacts = TestDataFactory.customerContacts;
        List <Order> orders = TestDataFactory.orders;
        Id conId = [SELECT Id from contact limit 1].Id;
        for(Order o : orders){
            o.Service_Contact__c = conId;
        }
        update orders;
        List<PricebookEntry> priceBookEntry  = TestDataFactory.priceBookEntry;
        Map<String, Map<String, State__c>> states = TestDataFactory.states;
        Map<String, Country__c> countries = TestDataFactory.countries;     
    }
    
    @isTest 
    static void testprocessRecords(){
        List<Order> ord = [SELECT Id,(SELECT Id, Product2Id FROM OrderItems) FROM Order LIMIT 1];
        system.debug('###'+ord[0].OrderItems.size());
        System.debug('##json:: ' + JSON.serialize(ord));
        Set<Id> prodId = new Set<Id>();
        for(Order s1 : ord){
            for(OrderItem s2 : s1.OrderItems){
                prodId.add(s2.Product2Id);
            }
        }
        system.debug('####'+  prodId.size());      
        List<Product2> prdList = [SELECT id, Is_ProfService_Product__c FROM Product2 WHERE Id IN : prodId];
        for(Product2 p:prdList){
            p.Is_ProfService_Product__c = true;
            p.Base_SKU__c = 'test';
        } 
        update prdList;
        List<Sobject> sobj = [SELECT Id,AccountId,Service_Contact__c FROM Order WHERE Id=: ord[0].Id];
        CreateProfServiceCaseByOrder createCaseByOrder = new CreateProfServiceCaseByOrder();
        createCaseByOrder.processRecords(null, null, null, null, null, null);
        createCaseByOrder.processRecords(null, null, sobj, null, null, null);
    }
    
    @isTest 
    static void ProfessionalCaseSubjectUpdationTest(){
        // insert case
        Case c = new Case();
        c.Subject = 'Test';
        c.Origin = 'Email';
        insert c;  
        
        Test.startTest();
        CreateProfServiceCaseByOrder.ProfessionalCaseSubjectUpdation(new Set<Id>{c.Id});
        Test.stopTest();
    }    

}