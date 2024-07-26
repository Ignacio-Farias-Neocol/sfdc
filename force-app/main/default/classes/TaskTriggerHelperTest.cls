@isTest
public class TaskTriggerHelperTest {
    
    @isTest
    static void OpportunityFirstResponseTimeTest(){
        
        Opportunity testOpp = TestDataFactory.opportunities[0];
        
        Task taskRecord = new Task();
        taskRecord.Subject = 'Test subject';
        taskRecord.WhatId = testOpp.Id;
        taskRecord.Status = 'Completed';
        taskRecord.Type='Other';
        insert taskRecord;
        Test.startTest();
		TaskTriggerHelper.updateOpportunityFirstResponseTime(new List<Task>{taskRecord}, null);
        Test.stopTest();
        
    }
    
    @isTest
    static void updateCSMLastTouchDateTest(){
        
        Account acc = new Account();
        acc.Name = 'testAccount';
        insert acc;
               
        Task taskRecord = new Task();
        taskRecord.Subject = 'Test subject';
        taskRecord.WhatId = acc.Id;
        taskRecord.Status = 'Completed';
        taskRecord.Type='Other';
        taskRecord.Description = 'Test';
        insert taskRecord;
         Test.startTest();
        TaskTriggerHelper.updateCSMLastTouchDate(new List<Task>{taskRecord}, null);
        Test.stopTest();

        
    }

}