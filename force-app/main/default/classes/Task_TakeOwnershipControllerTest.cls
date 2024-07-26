@isTest
public class Task_TakeOwnershipControllerTest {
	
    @isTest
    static void takeOwnershipTest(){
        List<Group> queueList = [Select Id, Name, DeveloperName, Type from Group where Type = 'Queue' and DeveloperName = 'Contact_Center_EMEA'];
        List <Case> caseList = TestDataFactory.webCases;
        Task taskRecord = new Task();
        taskRecord.Subject = 'Test subject';
        taskRecord.WhatId = caseList[0].Id;
        taskRecord.OwnerId = queueList[0].Id;
        insert taskRecord;
        
        Task_TakeOwnershipController.isTestRunning = true;
        Task_TakeOwnershipController.takeOwnership(taskRecord.Id);
        
        Task_TakeOwnershipController.isTestRunning = false;
        Task_TakeOwnershipController.takeOwnership(taskRecord.Id);
    }
}