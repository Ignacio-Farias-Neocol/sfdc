@isTest
public with sharing class MWBatchTest {

    @isTest static void testMWInactiveOMDeleteBatch() {
        MWInactiveOMDeleteBatchSched b = new MWInactiveOMDeleteBatchSched();
        b.execute(null);
    }


    @isTest static void testMWServiceCenterStatusUpdateBatch() {
        MWServiceCenterStatusUpdateBatchSched b = new MWServiceCenterStatusUpdateBatchSched();
        b.execute(null);
    }
}