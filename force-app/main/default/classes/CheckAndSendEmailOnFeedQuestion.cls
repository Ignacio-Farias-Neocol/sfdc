/**
 * @description       : SFDC-11898
**/
global without sharing class CheckAndSendEmailOnFeedQuestion {
    
    private Static List<String> topicList = New List<String>{'Email_Protection_Grouping','Data_Protection','Public_Cloud_Notification','Network_applications'};
    
    @InvocableMethod(label='Check And Send Notification On UnAnswered Questions')
    global static void checkAndSend(List<NotificationInputWrapper> params) {
        NotificationInputWrapper mNotificationInputWrapper = params[0];
        System.debug('CheckAndSendEmailOnFeedQuestion:::checkAndSend:::mNotificationInputWrapper::'+mNotificationInputWrapper);
        List<FeedItem> feedItemList = [SELECT Id, ParentId, Type, CreatedBy.Profile.Name, CreatedByID ,CreatedBy.Username, CreatedDate, IsDeleted, LastModifiedDate, 
                                       SystemModstamp, Revision, LastEditById, LastEditDate, CommentCount, LikeCount, Title, Body, LinkUrl, IsRichText, RelatedRecordId, InsertedById, 
                                       NetworkScope, Visibility, BestCommentId, HasContent, 
                                       HasLink, HasFeedEntity, HasVerifiedComment, Status FROM FeedItem WHERE id =: mNotificationInputWrapper.feedItemId];
        if(feedItemList != null && !feedItemList.isEmpty()){
            FeedItem mFeedItem = feedItemList[0];
            System.debug('CheckAndSendEmailOnFeedQuestion:::checkAndSend:::mFeedItem.CommentCount::'+mFeedItem.CommentCount);
            if(mFeedItem.CommentCount == 0){
                notifyUsersForReply(mNotificationInputWrapper.feedItemId, mFeedItem);
            }
        }
    }
    
    global class NotificationInputWrapper {
        @InvocableVariable (required=true)
        global String feedItemId;
    }
    
    private static void notifyUsersForReply(String feedItemId,FeedItem mFeedItem){
        System.debug('CheckAndSendEmailOnFeedQuestion:::notifyUsersForReply:::feedItemId::'+feedItemId);
        Map<String,Set<String>> feedItemIdvsTopicNamePrimaryMap = new Map<String,Set<String>>();
        Map<String,Set<String>> feedItemIdvsTopicNameSecondaryMap = new Map<String,Set<String>>();
        List<TopicAssignment> topicAssignMentList = new List<TopicAssignment>([SELECT Topic.Name, EntityId FROM TopicAssignment WHERE EntityId =: feedItemId]);
        System.debug('CheckAndSendEmailOnFeedQuestion:::notifyUsersForReply:::mFeedItem::'+JSON.serialize(mFeedItem));
        
        System.debug('CheckAndSendEmailOnFeedQuestion:::notifyUsersForReply:::topicAssignMentList::'+ JSON.serialize(topicAssignMentList));
        for(TopicAssignment ta: topicAssignMentList){
            if(ta.Topic.Name == 'Email Protection' || ta.Topic.Name == 'Data Protection' || ta.Topic.Name == 'Network Security' || ta.Topic.Name == 'Application & Cloud Security'){
                if(!feedItemIdvsTopicNamePrimaryMap.containsKey(ta.EntityId)){
                    feedItemIdvsTopicNamePrimaryMap.put(ta.EntityId,new Set<String>());
                }
                feedItemIdvsTopicNamePrimaryMap.get(ta.EntityId).add(ta.Topic.Name);
            }
            if(ta.Topic.Name != 'Email Protection' && ta.Topic.Name != 'Data Protection' && ta.Topic.Name != 'Network Security' && ta.Topic.Name != 'Application & Cloud Security'){
                if(!feedItemIdvsTopicNameSecondaryMap.containsKey(ta.EntityId)){
                    feedItemIdvsTopicNameSecondaryMap.put(ta.EntityId,new Set<String>());
                }
                feedItemIdvsTopicNameSecondaryMap.get(ta.EntityId).add(ta.Topic.Name);
            }
        }
        System.debug('CheckAndSendEmailOnFeedQuestion:::notifyUsersForReply:::feedItemIdvsTopicNamePrimaryMap::'+feedItemIdvsTopicNamePrimaryMap);
        System.debug('CheckAndSendEmailOnFeedQuestion:::notifyUsersForReply:::feedItemIdvsTopicNameSecondaryMap::'+feedItemIdvsTopicNameSecondaryMap);
        if(!feedItemIdvsTopicNamePrimaryMap.isEmpty()){
           
            
            Map<String,Set<Id>> topicNameVsUserIdsMap = new Map<String,Set<Id>>();
            Map<String,Id> groupNameVsGroupIdMap = new Map<String,Id>();
            
            for(Group mGroup: [Select id,DeveloperName from Group where DeveloperName in: topicList]){
                groupNameVsGroupIdMap.put(mGroup.DeveloperName,mGroup.id);
            }
            System.debug('CheckAndSendEmailOnFeedQuestion:::checkAndSend:::groupNameVsGroupIdMap::'+groupNameVsGroupIdMap);
            
            Map<String,String> topicVsGroupMap = new Map<String,String>{
                'Email Protection'=>'Email_Protection_Grouping',
                    'Data Protection'=>'Data_Protection',
                    'Network Security'=>'Network_applications',
                    'Application & Cloud Security'=>'Public_Cloud_Notification'};
                        
                        System.debug('CheckAndSendEmailOnFeedQuestion:::checkAndSend:::topicVsGroupMap::'+topicVsGroupMap);
            if(!feedItemIdvsTopicNamePrimaryMap.isEmpty() && feedItemIdvsTopicNamePrimaryMap.get(feedItemId) != null ){
                for(String topic: feedItemIdvsTopicNamePrimaryMap.get(feedItemId)){
                    if(groupNameVsGroupIdMap.get(topicVsGroupMap.get(topic))!=null){
                        if(!topicNameVsUserIdsMap.containsKey(topic))
                            topicNameVsUserIdsMap.put(topic,new Set<Id>());
                        topicNameVsUserIdsMap.get(topic).addall(getUserIdsFromGroup(new Set<Id>{groupNameVsGroupIdMap.get(topicVsGroupMap.get(topic))}));
                    }
                }
            }
            System.debug('CheckAndSendEmailOnFeedQuestion:::checkAndSend:::topicNameVsUserIdsMap::'+topicNameVsUserIdsMap);
            
            Set<Id> userIdSet = new Set<Id>();
            for(String topic: topicNameVsUserIdsMap.keyset()){
                userIdSet.addAll(topicNameVsUserIdsMap.get(topic));
            }            
            
            Map<String, String> userIdVsEmailAddressMap = new Map<String, String>();
            Map<Id, User> userMap = new Map<Id, User>([Select id,Email from User where id in: userIdSet]);
            
            for(User u: userMap.Values()){
                userIdVsEmailAddressMap.put(u.Id, u.Email);
            }
            
            System.debug('CheckAndSendEmailOnFeedQuestion:::checkAndSend:::userIdVsEmailAddressMap::'+userIdVsEmailAddressMap);
            
            User customerUser = [Select id,Username,Contact.Account.Name,Contact.Account.Premium_Support__c,Email from User Where id =: mFeedItem.CreatedById LIMIT 1];
            
            System.debug('CheckAndSendEmailOnFeedQuestion:::checkAndSend:::customerUser::'+customerUser);
            
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
            EmailTemplate template = [SELECT Id, Name, DeveloperName, NamespacePrefix, Body, 
                                      HtmlValue, Subject, Description, 
                                      TemplateType, IsActive 
                                      FROM EmailTemplate 
                                      where DeveloperName  = 'Moderator_Notify_after_24' LIMIT 1];
            
            System.debug('CheckAndSendEmailOnFeedQuestion:::checkAndSend:::template::'+template);
            
            List<OrgWideEmailAddress> oweaList = new List<OrgWideEmailAddress>([SELECT Id, Address, DisplayName FROM
                                                                                OrgWideEmailAddress WHERE Address='noreply@barracuda.com' LIMIT 1]);
            
            
            
            System.debug('CheckAndSendEmailOnFeedQuestion:::checkAndSend:::oweaList::'+oweaList);
            if(!oweaList.isEmpty()){
                String htmlBody = template.HtmlValue;
                htmlBody = htmlBody.replace('{!COMUSERNAME}', customerUser.Username);
                htmlBody = htmlBody.replace('{!ACCNAME}', customerUser.Contact.Account.Name);
                htmlBody = htmlBody.replace('{!PREMIUMSUPPORT}', customerUser.Contact.Account.Premium_Support__c ? 'Yes' : 'No');
                htmlBody = htmlBody.replace('{!QUESTIONASKED}', mFeedItem.Title);
                if(mFeedItem.Body != null){
                    htmlBody = htmlBody.replace('{!QUESTION}', mFeedItem.Body);
                }                
                htmlBody = htmlBody.replace('{!DATESUBMITTED}', String.valueof(mFeedItem.CreatedDate));
                String mainTopic = '';
                String subString = '';
                String topicAndSubtopicText = '';
                for(String tmpFeedItemId: feedItemIdvsTopicNamePrimaryMap.keyset()){
                    mainTopic = String.valueof(feedItemIdvsTopicNamePrimaryMap.get(tmpFeedItemId)).remove('{').remove('}');
                    topicAndSubtopicText = '<ul><li>'+String.valueof(feedItemIdvsTopicNamePrimaryMap.get(tmpFeedItemId)).remove('{').remove('}')+'<ul>';
                    if(feedItemIdvsTopicNameSecondaryMap.get(tmpFeedItemId) != null){
                        for(String secondaryTopic: feedItemIdvsTopicNameSecondaryMap.get(tmpFeedItemId)){
                            topicAndSubtopicText+= '<li>'+secondaryTopic+'</li>';
                            subString +=secondaryTopic+',';
                        }
                    }
                    topicAndSubtopicText += '</ul></li><ul>';
                    topicAndSubtopicText += '</ul>';
                }
                subString = subString.removeEnd(',');
                System.debug('CheckAndSendEmailOnFeedQuestion:::checkAndSend:::topicAndSubtopicText::'+topicAndSubtopicText);
                htmlBody = htmlBody.replace('{!TOPICSUBTOPIC}', topicAndSubtopicText);
                Messaging.SingleEmailMessage theMessage = new Messaging.SingleEmailMessage();
                theMessage.setToAddresses(userIdVsEmailAddressMap.values());
                theMessage.setOrgWideEmailAddressId(oweaList[0].id);
                theMessage.setUseSignature(false);
                theMessage.setBccSender(false);
                theMessage.setHtmlBody(htmlBody);
                theMessage.setSaveAsActivity(true);
                theMessage.setTemplateId(template.Id);
                String subject = '';
                if(mFeedItem.CreatedBy.Profile.Name != null){
                    if(mFeedItem.CreatedBy.Profile.Name.containsIgnoreCase('CCPlus') || mFeedItem.CreatedBy.Profile.Name.containsIgnoreCase('Customer')){
                        subject = 'A question in Customer Community needs attention - has not been answered in 24hrs';
                    }else if(mFeedItem.CreatedBy.Profile.Name.containsIgnoreCase('partner')){
                        subject = 'A question in Partner Community needs attention - has not been answered in 24hrs';
                    }else{
                        subject = 'A question in Community Workspace needs attention - has not been answered in 24hrs';
                    }
                }else{
                    subject = template.Subject;
                }
                theMessage.setSubject(subject);
                messages.add(theMessage);
                
                string bellNotificationBody = 'Question submitted by '+customerUser.Username+'\n';
                bellNotificationBody += 'Account Name: '+customerUser.Contact.Account.Name+'\n';
                bellNotificationBody += 'Premium Support: '+ String.valueof(customerUser.Contact.Account.Premium_Support__c ? 'Yes' : 'No')+'\n';
                bellNotificationBody += 'Question asked: '+mFeedItem.Title +'\n';
                bellNotificationBody += 'Topic: '+mainTopic+'\n';
                bellNotificationBody += 'Subtopic(s): '+subString+'\n';
                bellNotificationBody += 'Date Submitted: '+String.valueof(mFeedItem.CreatedDate.format()) +'\n';
                sendBellNotification(bellNotificationBody, new List<String>(userIdVsEmailAddressMap.keyset()), mFeedItem.CreatedBy.Profile.Name.containsIgnoreCase('partner'));
            }
            System.debug('CheckAndSendEmailOnFeedQuestion:::checkAndSend:::messages::'+messages);
            if(!Test.isRunningTest()){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                
                for(Messaging.SendEmailResult sr: results){
                    if(!sr.isSuccess()){
                        for(Messaging.SendEmailError err: sr.getErrors()){
                            System.debug('notifyUsersForReply :: SendEmailError :: err:'+err.getMessage()+', Error Code: '+err.getStatusCode());
                        }
                    }
                }
            }
        }
    }
    
    @future(callout=true)
    public static void sendBellNotification(String message, List<String> userIds, Boolean isPartnerCommunity){
        
        List<CustomNotificationType> mCustomNotificationTypeList = [SELECT Id,DeveloperName FROM CustomNotificationType where DeveloperName = 'Send_Bell_To_Community_Moderators'];
        if(mCustomNotificationTypeList  != null && mCustomNotificationTypeList.size() > 0){
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Url.getOrgDomainUrl().toExternalForm()
                            + '/services/data/v46.0/actions/standard/customNotificationAction');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json');
            CustomNotificationActionInput input = new CustomNotificationActionInput();
            input.customNotifTypeId = mCustomNotificationTypeList[0].id;
            input.recipientIds = userIds;
            
            if(isPartnerCommunity){
                input.title = 'A question in Partner Community needs attention - has not been answered in 24hrs';
            } else {
                input.title = 'A question in Customer Community needs attention - has not been answered in 24hrs';
            }            
            
            input.body = message;
            input.targetId = mCustomNotificationTypeList[0].id;
            CustomNotificationAction action = new CustomNotificationAction();
            action.inputs = new List<CustomNotificationActionInput>{input};
                req.setBody(JSON.serialize(action));
            if(!Test.isRunningTest()){
                HttpResponse res = h.send(req);
                System.debug(res.getBody());
            }
        }
    }
    
    public class CustomNotificationAction{
        public List<CustomNotificationActionInput> inputs { get; set; }
    }
    
    public class CustomNotificationActionInput{
        public String customNotifTypeId { get; set; }
        public List<String> recipientIds { get; set; }
        public String title { get; set; }
        public String body { get; set; }
        public String targetId { get; set; }
    }
    
    private static Set<id> getUserIdsFromGroup(Set<Id> groupIds){
        // store the results in a set so we don't get duplicates
        Set<Id> result=new Set<Id>();
        String userType = Schema.SObjectType.User.getKeyPrefix();
        String groupType = Schema.SObjectType.Group.getKeyPrefix();
        Set<Id> groupIdProxys = new Set<Id>();
        // Loop through all group members in a group
        
        for(GroupMember m : [Select Id, UserOrGroupId From GroupMember Where GroupId in :groupIds]) {
            System.debug('CheckAndSendEmailOnFeedQuestion:::checkAndSend:::m.UserOrGroupId::'+m.UserOrGroupId+' :: '+groupType);
            // If the user or group id is a user
            if(((String)m.UserOrGroupId).startsWith(userType)){
                result.add(m.UserOrGroupId);
            }
            // If the user or group id is a group
            // Note: there may be a problem with governor limits if this is called too many times
            else if (((String)m.UserOrGroupId).startsWith(groupType)){
                groupIdProxys.add(m.UserOrGroupId);
            }
        }
        if(groupIdProxys.size() > 0){
            result.addAll(getUserIdsFromGroup(groupIdProxys));
        }
        return result; 
    }
}