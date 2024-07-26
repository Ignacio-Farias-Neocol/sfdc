@istest
public with sharing class ContractUpdateStatusBatchSchedTest {
    public static testMethod void testschedule() {
    Test.StartTest();
    ContractUpdateStatusBatchSched sc = new ContractUpdateStatusBatchSched();
    String sched = '0 0 12 * * ?';
    system.schedule('Test Sched', sched, sc );
    Test.stopTest();
  }
}