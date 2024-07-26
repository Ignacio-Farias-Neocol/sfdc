/**
 * @author            : Bhavesh Jha
 * @group             : Barracuda Portal
 * @last modified on  : 08-31-2020
 * @last modified by  : Bhavesh Jha
**/
@isTest(seeAllData=true)
public class PortalRecordsCCTest
{

    static void testData(String topicName){
        Id netId= [SELECT Id,Name FROM Network WHERE Name LIKE '%Customer%' LIMIT 1].Id;
        try{
            ConnectApi.Topic newtopic = ConnectApi.Topics.createTopic(String.valueOf(netId), topicName, 'this is test topic for test class');
        
            List<FeedItem> feedItemList = new List<FeedItem>();
            for(integer i=0; i<2; i++){
                FeedItem item = new FeedItem();
                item.parentId = UserInfo.getUserId(); // where to post message
                item.createdById = UserInfo.getUserId(); // author to impersonate
                item.body = 'test123' + String.valueof(i);
                item.isRichText = false;
                item.NetworkScope= netId;
                item.Status = 'Published';
                item.Title = 'Test';
                item.Type='TextPost';
                item.Visibility= 'AllUsers';
                feedItemList.add(item);
            }
            insert feedItemList;
                
            FeedComment testFeed1Comment = new FeedComment(CommentBody='Test Feed 1 Comment', FeedItemId=feedItemList[0].Id, CommentType='TextComment', Status='Published');
            insert testFeed1Comment;
            
            
            List<TopicAssignment> topicAssignmentList = new List<TopicAssignment>();
            for(integer i=0; i<feedItemList.size(); i++){
                TopicAssignment tassign = new TopicAssignment();
                tassign.EntityId = feedItemList[i].id;
                tassign.NetworkId = netId;
                tassign.TopicId = newtopic.id;
                topicAssignmentList.add(tassign);
            }
            insert topicAssignmentList;
        }catch(Exception e){
            system.debug('Error : '+e);
        }
    }
    
    @isTest static void testGetRecsWithoutFilter() {
        testData('ok');
        testData('Email Protection');
        PortalRecordsCC.getPortalRecords('','','','Customer Community',1,0,'true');
        PortalRecordsCC.PortalRecordsWrapper wrap = new PortalRecordsCC.PortalRecordsWrapper(Id.valueof('0D5K000000vu50SKAQ'),Id.valueof('0TO5x0000000y7DGAQ'),'main','MainTitle','https//www.google.com/');
    }
    
    @isTest static void testGetRecsWithAllFilters() {
        PortalRecordsCC.getPortalRecords('Email Protection','yes','THIS_YEAR','Customer Community',1,1,'true');
    }
    
    @isTest static void testGetRecsLoop1Filter() {
        PortalRecordsCC.getPortalRecords('Email Protection','no','THIS_YEAR','Customer Community',1,0,'true');
    }
    
    @isTest static void testGetRecsLoop2Filter() {
        PortalRecordsCC.getPortalRecords('ok','yes','THIS_YEAR','Customer Community',1,0,'true');
    }
    
    @isTest static void testGetRecsLoop3Filter() {
        PortalRecordsCC.getPortalRecords('ok','yes','THIS_YEAR','Customer Community',1,0,'false');
    }
    
    @isTest static void testGetRecsLoop4Filter() {
        PortalRecordsCC.getPortalRecords('Email Protection','unanswered','THIS_YEAR','Customer Community',1,0,'true');
    }
    
    @isTest static void testGetRecsLoop5Filter() {
        PortalRecordsCC.getPortalRecords('ok','yes','THIS_YEAR','Customer Community',1,0,'false');
    }
    
    @isTest static void testGetRecsLoop6Filter() {
        PortalRecordsCC.getPortalRecords('Email Protection','answered','THIS_YEAR','Customer Community',1,0,'true');
    }
    
    @isTest static void testGetRecsLoop7Filter() {
        PortalRecordsCC.getPortalRecords('ok','answered','THIS_YEAR','Customer Community',1,0,'true');
    }
    
    @isTest static void testGetRecsDateLoop1Filter() {
        PortalRecordsCC.getPortalRecords('Email Protection','','THIS_YEAR','Customer Community',1,0,'true');
    }
    
    @isTest static void testException() {
        PortalRecordsCC.getPortalRecords('Email Protection','','test','Customer Community',1,0,'true');
    }
}