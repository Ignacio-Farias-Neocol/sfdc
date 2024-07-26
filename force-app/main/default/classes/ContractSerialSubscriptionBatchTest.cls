@IsTest

private class ContractSerialSubscriptionBatchTest {
    @testSetup static void setup() {
        Product2 testProd = TestDataFactory.products[0];
        Account testAcount = TestDataFactory.customers[0];
        Asset testAsset = TestDataFactory.assets[0];
        testAsset.Appliance_Line_Type__c = 'Hardware only (pool)';
        update testAsset;

        Contract testContract = new Contract ();
        testContract.AccountId = TestDataFactory.customers[0].Id;
        testContract.Business_Group__c = 'Core';
        testContract.StartDate = System.Today();
        testContract.ContractTerm = 12;
        testContract.EndDate = System.Today().addmonths(12);
        
        insert testContract;

        List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__RootId__c = testAsset.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), SBCF_Serial_Number__c = '123'),
            new SBQQ__Subscription__c(SBQQ__RootId__c = testAsset.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), SBCF_Serial_Number__c = '321', Cuda_Subscription_Type__c = '321')
        }; 
        insert testSubs;

        List<Serial__c> testSerials = new List<Serial__c> {
            new Serial__c(Serial_Number__c = '123', Activation_Date__c = System.Today().addDays(2)),
            new Serial__c(Serial_Number__c = '321', Activation_Date__c = System.Today().addDays(2))
        };
        insert testSerials;

        List<Assigned_Serial__c> testAssigneds = new List<Assigned_Serial__c> {
            new Assigned_Serial__c(Serial__c = testSerials[0].Id, Subscription__c = testSubs[0].Id),
            new Assigned_Serial__c(Serial__c = testSerials[0].Id, Subscription__c = testSubs[0].Id),
            new Assigned_Serial__c(Serial__c = testSerials[1].Id, Subscription__c = testSubs[1].Id),
            new Assigned_Serial__c(Serial__c = testSerials[1].Id, Subscription__c = testSubs[1].Id)
        };
        insert testAssigneds;
    }

    @IsTest
    static  void unitTest() {
        Test.startTest();
            ContractSerialSubscriptionBatchSched s = new ContractSerialSubscriptionBatchSched();
            String sch ='0 0 * * * ?'; 
            System.schedule('TerstContractSerialSubscriptionBatchSched', sch, s);

            ContractSerialSubscriptionBatch batch = new ContractSerialSubscriptionBatch();
            if (batch.defaultBatchSize == null)
                Database.executeBatch(batch);
            else {
                Database.executeBatch(batch, batch.defaultBatchSize);
            }
        Test.stopTest();
    }
}