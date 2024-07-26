@istest
public with sharing class MovePSGBatchSchedTest {
    public static testMethod void testschedule() {
    Test.StartTest();
    MovePSGBatchSched sc = new MovePSGBatchSched();
    String sched = '0 0 12 * * ?';
    system.schedule('Test Sched', sched, sc );
    Test.stopTest();
  }
}