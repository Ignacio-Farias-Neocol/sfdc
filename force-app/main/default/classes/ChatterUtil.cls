/**
 *  @author Ivan Yeung
 *  @date 7/25/2017
 *  @group Utility
 *  @description  Utility class for various chatter function. Conceptually, it acts as facade pattern to hide some complexity
 *       https://developer.salesforce.com/page/Apex_Design_Patterns_-_Facade
 */

public with sharing class ChatterUtil {



/*******************************************************************************************************
    * @description create a simple chatter post for a record, @menthod all the people in the queue or a single user
    * @param subjectId: The ID of the parent this feed element is being posted to. This value can be the ID of a user, group, or record, or the string me to indicate the context user
    * @return n/a
    * @example
    *
    *  note for single @method, there is already a standard call:
    *  ConnectApi.FeedItem fi = (ConnectApi.FeedItem) ConnectApiHelper.postFeedItemWithMentions(Network.getNetworkId(), 'me', 'Hey there {005D00000015tjz}, how are you?');
    */
    public static void PostFeedItemMethodQueue( Id subjectId, String messageText,  String queueName, String userName){



        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = messageText;  //  'Hey there ';
        messageInput.messageSegments.add(textSegment);


        // @method all the queue member
        if (String.isNotBlank(queueName)){
            for (Group grp: [select  DeveloperName, DoesIncludeBosses, DoesSendEmailToMembers, Email, Id, Name, Type from Group where Type  = 'Queue' and (Name =: queueName or DeveloperName = :queueName) limit 1 ]){
                for (GroupMember member: [select GroupId, Id, SystemModstamp, UserOrGroupId from GroupMember where GroupId =: grp.Id ]){

                    ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
                    mentionSegment.id =  member.UserOrGroupId; // '005D00000015tjz'; // The ID of the user to mention.
                    messageInput.messageSegments.add(mentionSegment);

                }
            }
        }

        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        input.subjectId = subjectId;

        ConnectApi.FeedElement fi = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), input);


    }


    /*******************************************************************************************************
    * @description create a simple chatter post for a record, @menthod all the people in the queue or a single user
    * @param subjectId: The ID of the parent this feed element is being posted to. This value can be the ID of a user, group, or record, or the string me to indicate the context user
    * @return n/a
    * @example
    *
    *  note for single @method, there is already a standard call:
    *  ConnectApi.FeedItem fi = (ConnectApi.FeedItem) ConnectApiHelper.postFeedItemWithMentions(Network.getNetworkId(), 'me', 'Hey there {005D00000015tjz}, how are you?');
    */
    public static void PostFeedItemMethodQueueBulk(Map<Id,String> subjectIdToMessageMap, Map<Id,String> subjectIdToQueueNameMap){
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();    
            
        for(Id s:subjectIdToMessageMap.keySet()){
            ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();

            input.subjectId = s;
            
            ConnectApi.MessageBodyInput body = new ConnectApi.MessageBodyInput();
            body.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            
            String queueName = subjectIdToQueueNameMap.get(s);
            if (String.isNotBlank(queueName)){
                for (Group grp: [select  DeveloperName, DoesIncludeBosses, DoesSendEmailToMembers, Email, Id, Name, Type from Group where Type  = 'Queue' and (Name =: queueName or DeveloperName = :queueName) limit 1 ]){
                    for (GroupMember member: [select GroupId, Id, SystemModstamp, UserOrGroupId from GroupMember where GroupId =: grp.Id ]){

                        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
                        mentionSegment.id =  member.UserOrGroupId; // '005D00000015tjz'; // The ID of the user to mention.
                        body.messageSegments.add(mentionSegment);

                    }
                }
            }
            
            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
            textSegment.text = subjectIdToMessageMap.get(s);

            body.messageSegments.add(textSegment);
            input.body = body;

            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(input);
            batchInputs.add(batchInput);
        }

        If(!Test.isRunningTest()) {
            // avoid:  System.UnsupportedOperationException: ConnectApi methods are not supported in data siloed tests. Please use @IsTest(SeeAllData=true).
            ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
        }
    }

}