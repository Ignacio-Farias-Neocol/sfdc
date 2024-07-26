@isTest
private class UpdateOpportunityResponseTimeBatchTest {

    static void setupTestData() {
        // Create test data for Opportunities and Tasks
        Opportunity testOpp = TestDataFactory.opportunities[0];
        
        Task taskRecord = new Task();
        taskRecord.Subject = 'Test First RespondTime';
        taskRecord.WhatId = testOpp.Id;
        taskRecord.Status = 'Completed';
        taskRecord.Type='Other';
        insert taskRecord;
    }

    @isTest
    static void testBatch() {
        Test.startTest();

        // Set up test data
        setupTestData();

        // Execute batch class
        UpdateOpportunityResponseTimeBatch batch = new UpdateOpportunityResponseTimeBatch();
        Database.executeBatch(batch);

        Test.stopTest();

    }
}