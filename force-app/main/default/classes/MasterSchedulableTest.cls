@IsTest(SeeAllData=false)
private class MasterSchedulableTest {

    static testMethod void test_MasterScedulable_CreateSchedule() {

        Id jobId;

        jobId = MasterSchedulable.createHourlySchedule();
        // System.UnexpectedException: No more than one executeBatch can be called from within a test method. Please make sure the iterable returned from your start method matches the batch size, resulting in one executeBatch invocation.
        jobId = MasterSchedulable.createHourlySchedule();         // call it twice so both logic paths run
        System.assertNotEquals(null, jobId);

    }

    static testMethod void test_MasterScedulable_MissingClass() {

        // update custom setting
        insert new Schedulable_Batch__c(
                Name = 'A_Class_That_Doesnt_Exist',
                Is_Active__c = true,
                Interval__c = 1,
                Scope__c = 1
        );

        // immediately begin
        new MasterSchedulable().execute(null);

    }

    static testMethod void test_MasterScedulable_BadInstanceOf() {

        // update custom setting
        insert new Schedulable_Batch__c(
                Name = 'TestUtils',
                Is_Active__c = true,
                Interval__c = 1,
                Scope__c = 1
        );

        // immediately begin
        new MasterSchedulable().execute(null);

    }

    static testMethod void test_MasterScedulable() {

        // update custom setting
        Schedulable_Batch__c sb = new Schedulable_Batch__c(
                Name = 'UpdateQueuesOnUserRecord',
                Is_Active__c = true,
                Interval__c = 1,
                Scope__c = 1
        );

        // activate the current hour window field
        Integer currentHourGmt = DateTime.now().hourGmt();
        String fieldName = String.format('X{0}00__c', new List<String> { String.valueOf(currentHourGmt).leftPad(2).replaceAll(' ', '0') });

        sb.put(fieldName, true);
        insert sb;

        Test.startTest();
        {
            // immediately begin
            new MasterSchedulable().execute(null);
        }
        Test.stopTest();

        // call again now that there is history
        new MasterSchedulable().execute(null);

    }

}