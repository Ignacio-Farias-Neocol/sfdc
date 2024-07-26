@IsTest
public class DisableFeedPostDeletesTest {

    @isTest
    static void deleteFeeditem(){
        feedItem lstFeedItem=new feedItem();
		Chatter_Delete_Settings__c settings = new Chatter_Delete_Settings__c();
        settings.Allow_Feed_Post_and_Comment_deletes__c=false;
        insert settings;
      lstFeedItem=new FeedItem(ParentId = userinfo.getuserid(),
                                   body = 'test');
        insert lstFeedItem;
        
        Test.startTest();
         Database.DeleteResult  result = Database.delete(lstFeedItem, false);
        System.assertEquals('Your administrator has disabled feed post and comment deletions.',
                             result.getErrors()[0].getMessage());
        Test.stopTest();
    }
}