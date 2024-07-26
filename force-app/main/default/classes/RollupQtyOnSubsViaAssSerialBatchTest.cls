@IsTest
public class RollupQtyOnSubsViaAssSerialBatchTest {
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    @testSetup static void setup() {
        Account testAcount = TestDataFactory.customers[0];
        
        //Contract for insert legacy contract with a Subscription
        Contract testContract = new Contract(AccountId = testAcount.Id, Business_Group__c = 'MSP', StartDate = System.Today());
        insert testContract;

        List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAcount.Id, SBCF_Serial_Number__c = '123')};
        insert testSubs;
        
        Serial__c testSerial = new Serial__c(Serial_Number__c = '123');
        insert testSerial;
        
        //create Assigned_Serial__c with Qty_in_Use__c for unit test batch class RollupQtyOnSubsViaAssSerialBatch which update Quantity_in_Use__c in SBQQ__Subscription__c.
        List<Assigned_Serial__c> assignedSerialList = new List<Assigned_Serial__c> { 
            new Assigned_Serial__c (Status__c = 'Active',Qty_in_Use__c = 9,Subscription__c = testSubs.get(0).Id,Serial__c = testSerial.Id),
            new Assigned_Serial__c (Status__c = 'Active',Qty_in_Use__c = 9,Subscription__c = testSubs.get(0).Id,Serial__c = testSerial.Id)
        };
        
        insert AssignedSerialList;
    }

    @IsTest
    static  void unitTest() {
        
        //Set the scheduler in test context.
        
        List<SBQQ__Subscription__c> subs_before = new List<SBQQ__Subscription__c>([Select Id,Quantity_in_Use__c from SBQQ__Subscription__c where SBQQ__Quantity__c = 1]);
        
        System.debug('subs_before:::::::::::::::::'+JSON.serialize(subs_before));
        
        Test.startTest();
            String sch = '0 48 * * * ?';
            System.schedule('ScheduledApexTest',
                                            sch, 
                                            new RollupQtyOnSubsViaAssSerialBatch());   
            
            Database.executeBatch(new RollupQtyOnSubsViaAssSerialBatch(),10);
        Test.stopTest();
        //Query SBQQ__Subscription__c records for assertion.
        List<SBQQ__Subscription__c> subs = new List<SBQQ__Subscription__c>([Select Id,Quantity_in_Use__c from SBQQ__Subscription__c where SBQQ__Quantity__c = 1]);
        
        System.debug('subs:::::::::::::::::'+JSON.serialize(subs));
        
        //assert Assigned_Serial__c with Qty_in_Use__c for unit test batch class RollupQtyOnSubsViaAssSerialBatch which update Quantity_in_Use__c in SBQQ__Subscription__c.
        System.assertEquals(18,subs.get(0).Quantity_in_Use__c);
    }
}