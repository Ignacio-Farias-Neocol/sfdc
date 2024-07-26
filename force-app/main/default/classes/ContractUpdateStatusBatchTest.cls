@isTest
private  class ContractUpdateStatusBatchTest {   

    static Account testAccount;
    static Contract testContract ;
    static List<SBQQ__Subscription__c> testSubs;

    
    static void setup() {
      
        testAccount = TestDataFactory.customers[0];
        
        testContract = new Contract(AccountId = testAccount.Id, Business_Group__c = 'Core', StartDate = System.Today());
        insert testContract;

        testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123'),
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123'),
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123'),
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAccount.Id, SBCF_Serial_Number__c = '123')
        }; 
        insert testSubs;
    }

    @isTest
    static void testRMATrue(){   

        Test.startTest();           
        
        setup();

        System.debug('testContract.status :: ' + [Select status from Contract
        where Id=:testContract.Id].Status);

        testContract.All_Subs_RMA__c=true;

        update testContract;

        ContractUpdateStatusBatch con = new ContractUpdateStatusBatch();
        
        Id batchId = Database.executeBatch(con);

        Test.stopTest();       

        System.assertEquals('InActive',[Select status from Contract
        where Id=:testContract.Id].Status
);
    }   
}