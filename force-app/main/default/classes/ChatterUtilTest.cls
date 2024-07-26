/**
* @author        Ivan Yeung/salesforce services
* @date          2018-11-10
* @description   Unit Test class for ChatterUtil
* @group         Test
*
*/
// All test methods in this class can access all data because Network.getNetworkId()
@isTest(SeeAllData=true)
public with sharing class ChatterUtilTest {


    @isTest static void unitTest() {

        /////Adding users to Queue//////////

        User aUser = TestDataFactory.createUser('System Administrator');
        Id userId = aUser.Id;

        //Get the group you want. Queues are stored as group objects with a type of Queue
        QueueSObject q = TestDataFactory.createQueue('Lead', 'TestQueue');
        Group g = [select Id from Group where Name='TestQueue' AND Type = 'Queue' limit 1];
        System.debug('~~~ group: ' + g);
        GroupMember member = new GroupMember();
        member.UserOrGroupId = userId;
        member.GroupId = g.Id;
        DML.save( member);

        Test.startTest();

        ChatterUtil.PostFeedItemMethodQueue(userId, 'Test Message', 'TestQueue', aUser.Username);

        Map<Id,String> subjectIdToMessageMap = new Map<Id, String>();
        subjectIdToMessageMap.put(userId, 'Test Message ');
        Map<Id,String> subjectIdToQueueNameMap = new Map<Id, String>();
        subjectIdToQueueNameMap.put(userId, 'Test TestQueue ');
        ChatterUtil.PostFeedItemMethodQueueBulk(subjectIdToMessageMap, subjectIdToQueueNameMap);

        Test.stopTest();

    }


}