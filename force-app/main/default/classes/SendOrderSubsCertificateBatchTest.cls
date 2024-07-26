@isTest
public class SendOrderSubsCertificateBatchTest {
   /* @testSetup static void testSetupMethod(){
        List<Account> customers = TestDataFactory.customers;
        List<Account> partners = TestDataFactory.partners;
        List<Opportunity> oppty = TestDataFactory.opportunities;
        Order mOrder = new Order();
        Product2 prod;
        
        prod = new Product2(Name = 'Barracuda Backup Server Appliance 190 Demo Conversion MSP',CurrencyIsoCode='USD');
        insert prod;
        
        customers[0].Bill_To_Email__c = 'bjha@test.com';
        update customers;
        
        mOrder.Name='ProductName1';
        mOrder.Bill_To_Account__c = customers[0].id;
        mOrder.Status = 'Draft';
        mOrder.EffectiveDate = Date.today();
        mOrder.EndDate = Date.today().addDays(2);
        mOrder.CurrencyIsoCode = 'USD';
        mOrder.Type = 'New';
        mOrder.AccountId = customers[0].id;
        mOrder.OpportunityId = oppty[0].Id;
        insert mOrder;
        
        Contract cd = new Contract();
        cd.AccountId = customers[0].id;
        cd.CurrencyIsoCode = 'USD';
        cd.Account = customers[0];
        cd.Status = 'Draft';
        cd.ContractTerm = 21;
        cd.Business_Group__c = 'MSP';
        cd.Unique_Contract_ID__c = 'CD2342324235';
        insert cd;
        
        List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = cd.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = customers[0].Id, SBCF_Serial_Number__c = '123'),
                new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = cd.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = customers[0].Id, SBCF_Serial_Number__c = '123'),
                new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = cd.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = customers[0].Id, SBCF_Serial_Number__c = '123'),
                new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = cd.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = customers[0].Id, SBCF_Serial_Number__c = '123')
                }; 
                    insert testSubs;
        
        List<Serial__c> serialList = new List<Serial__c>{new Serial__c(Activation_Date__c =  Date.today(),Serial_Number__c = '123123',Capacity__c = 132,Order__c = mOrder.Id)};
            insert serialList;
        
        List<Assigned_Serial__c> assignedSerials = new List<Assigned_Serial__c>{new Assigned_Serial__c(
            End_User_Account__c = customers[0].Id,
            Subscription__c = testSubs[0].id,
            Unique_Contract_ID__c = '2342344214',Serial__c = serialList[0].Id,
            Order__c = mOrder.id)};
                insert assignedSerials;
        
        
    } */
    
    @isTest static void unitTestBatch(){
    
      List<Account> customers = TestDataFactory.customers;
        List<Account> partners = TestDataFactory.partners;
        List<Opportunity> oppty = TestDataFactory.opportunities;
        Order mOrder = new Order();
        Product2 prod;
        
        prod = new Product2(Name = 'Barracuda Backup Server Appliance 190 Demo Conversion MSP',CurrencyIsoCode='USD');
        insert prod;
        
        customers[0].Bill_To_Email__c = 'bjha@test.com';
        update customers;
        
        mOrder.Name='ProductName1';
        mOrder.Bill_To_Account__c = customers[0].id;
        mOrder.Status = 'Draft';
        mOrder.EffectiveDate = Date.today();
        mOrder.EndDate = Date.today().addDays(2);
        mOrder.CurrencyIsoCode = 'USD';
        mOrder.Type = 'New';
        mOrder.AccountId = customers[0].id;
        mOrder.OpportunityId = oppty[0].Id;
        insert mOrder;
        
        Contract cd = new Contract();
        cd.AccountId = customers[0].id;
        cd.CurrencyIsoCode = 'USD';
        cd.Account = customers[0];
        cd.Status = 'Draft';
        cd.ContractTerm = 21;
        cd.Business_Group__c = 'MSP';
        cd.Unique_Contract_ID__c = 'CD2342324235';
        insert cd;
        
        List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = cd.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = customers[0].Id, SBCF_Serial_Number__c = '123'),
                new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = cd.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = customers[0].Id, SBCF_Serial_Number__c = '123'),
                new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = cd.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = customers[0].Id, SBCF_Serial_Number__c = '123'),
                new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = cd.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = customers[0].Id, SBCF_Serial_Number__c = '123')
                }; 
                    insert testSubs;
        
        List<Serial__c> serialList = new List<Serial__c>{new Serial__c(Activation_Date__c =  Date.today(),Serial_Number__c = '123123',Capacity__c = 132,Order__c = mOrder.Id)};
            insert serialList;
        
         Test.startTest();
        
        List<Assigned_Serial__c> assignedSerials = new List<Assigned_Serial__c>{new Assigned_Serial__c(
            End_User_Account__c = customers[0].Id,
            Subscription__c = testSubs[0].id,
            Unique_Contract_ID__c = '2342344214',Serial__c = serialList[0].Id,
            Order__c = mOrder.id)};
                insert assignedSerials;
    
    
    
        List<Order> mOrderList = [Select PoNumber,Bill_To_Account__r.Name,Active_Contract__r.Reseller__r.Name,Active_Contract__r.SBQQ__Quote__r.Name from Order LIMIT 1];
        
        //we do not make any data manupulation operation here so, check assertion on size only.
        System.assert(!mOrderList.isEmpty());
       
        ApexPages.StandardController sc = new ApexPages.StandardController(mOrderList[0]);
        OrderSubscriptionCertificateController ext = new OrderSubscriptionCertificateController(sc);
       
        Database.executeBatch(new SendOrderSubscriptionCertificateBatch(),200);
        Test.stopTest();
       
        
    }
    
}