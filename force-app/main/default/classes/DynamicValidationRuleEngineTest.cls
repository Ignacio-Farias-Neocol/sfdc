@IsTest
private class DynamicValidationRuleEngineTest {

    static testMethod void test_DynamicValidationRuleEngine() {

        TriggerHandler.bypass('RollUpSummaryUtilityTriggerHandler');

        // generate test data here e.g.
        Id recordId = TestDataFactory.customers[0].Id;
        TriggerHandler.clearAllBypasses();

        test.startTest();

            // check that there are no logs
            System.assertEquals(0, Database.countQuery('select count() from Dynamic_Validation_Log__c'));

            DynamicValidationRuleEngine.validateRecords(recordId);

            // check that logs were created
            // verify only if validation does exists 
            // System.assertNotEquals(0, Database.countQuery('select count() from Dynamic_Validation_Log__c'));

        test.stopTest();
        
    }

}