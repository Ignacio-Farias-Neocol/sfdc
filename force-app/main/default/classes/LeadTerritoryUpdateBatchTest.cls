/**
* @author        Ivan Yeung/salesforce services
* @date          2019-01-31
* @description   Unit Test class for LeadTerritoryUpdateBatch & LeadTerritoryUpdateBatchSchedulable,
* @group         Test
*
*/
@isTest
public with sharing class LeadTerritoryUpdateBatchTest {

    @testSetup
    static void setup() {

    // to do: add setup on data
    }


    @isTest static void unitTest() {

        // by pass business action ,
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        List <Lead> l = TestDataFactory.postMQLLeads;
        TriggerHandler.clearAllBypasses();

        Test.StartTest();
            LeadTerritoryUpdateBatch.executeBatch();
        Test.StopTest();

    }


    @isTest static void unitTestSchedueable() {

    Test.StartTest();
        LeadTerritoryUpdateBatchSchedulable m = new LeadTerritoryUpdateBatchSchedulable();
        String sch = '20 30 8 10 2 ?';
        String jobID = system.schedule('Lead Schedule Job', sch, m);
    Test.StopTest();




    }

}