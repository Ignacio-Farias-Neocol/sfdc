/**
* @author        Ivan Yeung/salesforce services
* @date          2019-01-31
* @description   Unit Test class for CPQActivateOrderBatch,
* @group         Test
*
*/
@isTest
public with sharing class AccountTerritoryUpdateBatchTest {

    @testSetup
    static void setup() {

        // to do: add setup on data
    }


    @isTest static void unitTest() {


        AccountTerritoryUpdateBatch.executeBatch();

    }


    @isTest static void unitTestSchedueable() {

        Test.StartTest();
        AccountTerritoryUpdateBatchSchedulable m = new AccountTerritoryUpdateBatchSchedulable();
        String sch = '20 30 8 10 2 ?';
        String jobID = system.schedule('Account Schedule Job', sch, m);
        Test.StopTest();
        m.finish(null); 
        system.debug('Job ID: ' + jobID);



//        Test.startTest();
//        String CRON_EXP = '0 0 0 1 1 ? 2025';
//        String jobId = System.schedule('testScheduledApex', CRON_EXP, new AccountTerritoryUpdateBatchSchedulable() );
//
//        CronTrigger ct = [select id, CronExpression, TimesTriggered, NextFireTime from CronTrigger where id = :jobId];
//
//        System.assertEquals(CRON_EXP, ct.CronExpression);
//        System.assertEquals(0, ct.TimesTriggered);
//        System.assertEquals('2025-01-01 00:00:00', String.valueOf(ct.NextFireTime));
//
//        Test.stopTest();



    }

}