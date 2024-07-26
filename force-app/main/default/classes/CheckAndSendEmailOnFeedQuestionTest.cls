/**
 * @File Name          : CheckAndSendEmailOnFeedQuestionTest.cls
 * @Description        : 
 * @Group              : Barracuda
**/
@isTest
public class CheckAndSendEmailOnFeedQuestionTest {

    @TestSetup
    static void makeData(){
        Account ac = new Account(name ='Grazitti') ;
        insert ac; 
        
        Contact con;
        Contact communityCon;
        
        communityCon = new Contact(LastName ='testCon',AccountId = ac.Id,email='testbjha@test.com');
        insert communityCon;
        
        Account acc;
        acc = new Account();
        acc.Name = 'NAME';
        acc.Type = 'Partner - Reseller';
        acc.Status__c = 'Active';
        insert acc;

        con = new Contact();
        con.AccountId = acc.id;
        con.Firstname = 'TEST';
        con.Lastname = 'TEST';
        con.email = 'TES@TEST.COM';
        insert con;
    }

    @IsTest static void methodName(){
        
        /*
        Account acc;
        acc = new Account();
        acc.Name = 'NAME';
        acc.Type = 'Partner - Reseller';
        acc.Status__c = 'Active';
        insert acc;

        Id p = [select id from profile where name LIKE '%CCPlus%' LIMIT 1].id;

        Account ac = new Account(name ='Grazitti') ;
        insert ac;

        Contact con = new Contact(LastName ='testCon',AccountId = ac.Id,email='email@test.com');
        insert con;        
		*/
        
        Id p = [select id from profile where name LIKE '%CCPlus%' LIMIT 1].id;
        
        Contact con = [Select Id from Contact limit 1];
        
        Account acc = [Select Id from Account limit 1];

        User user = new User(alias = 'test123', email='test123@noemail.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = p, country='United States',IsActive =true,
        ContactId = con.Id,
        timezonesidkey='America/Los_Angeles', username='tester@noemail.com');

        insert user;
		
        Test.startTest();        
        FeedItem item = new FeedItem();
        item.parentId = acc.id;
        item.Type = 'QuestionPost';
        item.Title = 'QuestionPost';
        item.Body = 'QuestionPost';
        item.CreatedById = user.id;
        insert item;


        Topic mTopic = new Topic();
        mTopic.Name = 'TESTABC';
        insert mTopic;

        Topic mTopic2 = new Topic();
        mTopic2.Name = 'Data Protection';
        insert mTopic2;

        TopicAssignment mTopicAssignment = new TopicAssignment();
        mTopicAssignment.TopicId = mTopic.id;
        mTopicAssignment.EntityId = item.id;
        insert mTopicAssignment;

        TopicAssignment mTopicAssignment2 = new TopicAssignment();
        mTopicAssignment2.TopicId = mTopic2.id;
        mTopicAssignment2.EntityId = item.id;
        insert mTopicAssignment2;

        CheckAndSendEmailOnFeedQuestion.NotificationInputWrapper mNotificationInputWrapper = new CheckAndSendEmailOnFeedQuestion.NotificationInputWrapper();
        mNotificationInputWrapper.feedItemId = item.id;
        CheckAndSendEmailOnFeedQuestion.checkAndSend(new List<CheckAndSendEmailOnFeedQuestion.NotificationInputWrapper> {mNotificationInputWrapper});
        Test.stopTest();
    }
}