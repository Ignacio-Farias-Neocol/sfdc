/**
 * @description       : 
 * @group             : 
 * @last modified on  : 09-25-2020
 * @last modified by  : Bhavesh Jha
**

* @description SFDC-13303 Fixed the issue of data not loading when Question Type is not "All"
* @description SFDC-14004 Moderator(Non Admin) is not seeing latest updates on the integrated dashboard.
*/
public without sharing class PortalRecordsCC
{
    @AuraEnabled
    public static resultWrapper getPortalRecords(String topicName, String commentType, String dateFilter, String network, Decimal pageNumber, Decimal pageSize,String showSubTopics ) {
      
        try {
            
            Integer pSize = (Integer)pageSize;
            Integer pNumber = (Integer)pageNumber;
             
            //Offset for SOQL
            Integer offset = (pNumber - 1) * pSize;                 
        
            System.debug('@@ topicName:'+ topicName );
            System.debug('@@ commentType:'+ commentType);
            System.debug('@@ dateFilter:'+ dateFilter);
            System.debug('@@ network:'+ network);
            System.debug('@@ pageNumber:'+ pageNumber);
            System.debug('@@ pageSize:'+ pageSize);
             System.debug('@@ showSubTopics:'+ showSubTopics);
            Id networkId = [SELECT Id,Name FROM Network WHERE Name=:network LIMIT 1].Id;
            
            ConnectApi.Community community = ConnectApi.Communities.getCommunity(String.valueOf(networkId));
            
            // Rahul
            topicName= topicName.replace('-','&');
            String subTopicQuery=' in(\''+topicName+'\',';
            String mainTopicQuery=' in(';
            ConnectApi.ManagedTopicCollection topics = ConnectApi.ManagedTopics.getManagedTopics(String.valueOf(networkId),ConnectApi.ManagedTopicType.Navigational);
            Set<String> subtopicNames = new Set<String>();
            for (ConnectApi.ManagedTopic managedTopic : topics.managedTopics) {
                 mainTopicQuery=mainTopicQuery + '\''+((ConnectApi.Topic)managedTopic.topic).name+'\',';
                
                if(String.valueOf(showSubTopics).equals('true') && String.isNotBlank(topicName))
                {
                    if(topicName==((ConnectApi.Topic)managedTopic.topic).name)    
                    {
                       
                        for (ConnectApi.ManagedTopic childManagedTopic : ConnectAPI.ManagedTopics.getManagedTopic(networkId, (managedTopic.id), 2).children) {
                              subtopicNames.add(((ConnectApi.Topic)childManagedTopic.topic).name);
                              subTopicQuery=subTopicQuery + '\''+((ConnectApi.Topic)childManagedTopic.topic).name+'\',';
                         
                         }
                    }
                    else if(topicName.equals('All'))
                    {
                         for (ConnectApi.ManagedTopic childManagedTopic : ConnectAPI.ManagedTopics.getManagedTopic(networkId, (managedTopic.id), 2).children) {
                              subtopicNames.add(((ConnectApi.Topic)childManagedTopic.topic).name);
                              mainTopicQuery=mainTopicQuery + '\''+((ConnectApi.Topic)childManagedTopic.topic).name+'\',';
                         
                         }
                    }
                        
               }
                
            }
            
            mainTopicQuery=mainTopicQuery.substring(0,mainTopicQuery.length()-1)+')';
            subTopicQuery=subTopicQuery.substring(0,subTopicQuery.length()-1)+')';
             System.debug('@@ mainTopicQuery:'+ mainTopicQuery);
             System.debug('@@ subTopicQuery:'+ subTopicQuery);
             //Rahul
            //
            String topicAssignQry = 'SELECT Id,EntityId,TopicId,Topic.Name FROM TopicAssignment WHERE NetworkId =:networkId';
            if(String.isNotBlank(topicName)) {
                if(!String.valueOf(topicName).equals('All')){
                  //  topicName = topicName.replace('-','&');
                   // topicAssignQry += ' AND Topic.Name =:topicName';
                    subTopicQuery = subTopicQuery.replace('-','&');
                   topicAssignQry += ' AND Topic.Name' +subTopicQuery;
                }else{
                   // String reqs = '(Topic.Name = \'Email Protection\' OR Topic.Name = \'Data Protection\' OR Topic.Name = \'Network Security\' OR Topic.Name = \'Application - Cloud Security\'OR Topic.Name = \'Cloud Application Security\')';
                  //  reqs = reqs.replace('-','&');
                  //  topicAssignQry += ' AND '+reqs;
                   mainTopicQuery = mainTopicQuery.replace('-','&');
                     topicAssignQry += ' AND Topic.Name' +mainTopicQuery;
                }
            }else{
                topicAssignQry += ' AND id = null';
            }
            topicAssignQry += ' ORDER BY CreatedDate DESC LIMIT 10000';
            system.debug('@@ topicAssignQry:'+topicAssignQry);
            
            Map<Id,TopicAssignment> entityIdVsTopicAssignmentMap = new Map<Id,TopicAssignment>();
            Set<Id> sFeedId = new Set<Id>();
            List<PortalRecordsWrapper> lResult = new List<PortalRecordsWrapper>();
            List<TopicAssignment> topicAssignmentList = Database.query(topicAssignQry);
            System.debug('@@ topicAssignmentList:::Size::'+ topicAssignmentList.size());
            for(TopicAssignment ta: topicAssignmentList) {
                
                entityIdVsTopicAssignmentMap.put(ta.EntityId,ta);
                //if(!topicName.equals('All')){
                    sFeedId.add(ta.EntityId);
                //}
            }
            system.debug('@@ mTA:'+JSON.serialize(entityIdVsTopicAssignmentMap));
            system.debug('@@ sFeedId:'+JSON.serialize(sFeedId));
            
            String feedItemQry = 'SELECT BestCommentId,Id,LikeCount,NetworkScope,ParentId,RelatedRecordId,Status,Title,Type FROM FeedItem';
            
            if(!sFeedId.isEmpty()) {
                feedItemQry += ' WHERE Id IN:sFeedId';
            }
            if(!String.valueOf(commentType).equals('All')){
                if(!String.isBlank(commentType)){  //SFDC-13303
                    if(String.isNotBlank(commentType) && commentType.equalsIgnoreCase('yes') && feedItemQry.contains('WHERE')) {
                        feedItemQry += ' AND BestCommentId != \'\'';
                    }else if(String.isNotBlank(commentType) && commentType.equalsIgnoreCase('no') && feedItemQry.contains('WHERE')) {
                        feedItemQry += ' AND BestCommentId = \'\'';
                    }else if(String.isNotBlank(commentType) && commentType.equalsIgnoreCase('yes') && !feedItemQry.contains('WHERE')) {
                        feedItemQry += ' WHERE BestCommentId != \'\'';
                    }else if(String.isNotBlank(commentType) && commentType.equalsIgnoreCase('no') && !feedItemQry.contains('WHERE')) {
                        feedItemQry += ' WHERE BestCommentId = \'\'';
                    }else if(String.isNotBlank(commentType) && commentType.equalsIgnoreCase('unanswered') && feedItemQry.contains('WHERE')) {
                        feedItemQry += ' AND CommentCount = 0';
                    }else if(String.isNotBlank(commentType) && commentType.equalsIgnoreCase('unanswered') && !feedItemQry.contains('WHERE')) {
                        feedItemQry += ' WHERE CommentCount = 0';
                    }else if(String.isNotBlank(commentType) && commentType.equalsIgnoreCase('answered') && feedItemQry.contains('WHERE')) {
                        feedItemQry += ' AND CommentCount > 0';
                    }else if(String.isNotBlank(commentType) && commentType.equalsIgnoreCase('answered') && !feedItemQry.contains('WHERE')) {
                        feedItemQry += ' WHERE CommentCount > 0';
                    }
                }else{
                    if(feedItemQry.contains('WHERE')){
                        feedItemQry += ' AND id = null';
                    }else{
                        feedItemQry += ' WHERE id = null';
                    }
                }
            }
            
            if(String.isNotBlank(dateFilter) && feedItemQry.contains('WHERE')) {
                feedItemQry += ' AND CreatedDate = '+dateFilter;
            }else if(String.isNotBlank(dateFilter) && !feedItemQry.contains('WHERE')) {
                feedItemQry += ' WHERE CreatedDate = '+dateFilter;
            }
            
            feedItemQry += ' AND Type=\'QuestionPost\' ORDER BY CreatedDate DESC';
            //feedItemQry += ' ORDER BY CreatedDate DESC';
           
            Integer totalRecords =  Database.query(feedItemQry).size(); //Querying the count of the records queried for pagination
            
            feedItemQry += ' LIMIT :pSize OFFSET :offset';
            system.debug('@@ feedItemQry:'+feedItemQry);
            List<Id> sflist = new list<id>();
            sflist.addAll(sfeedid);
            system.debug('sFeedId: '+ string.join(sflist,','));
            system.debug('psize:'+ psize + ' offset '+offset);
            //Integer feedItemQryCount = Database.countQuery('SELECT COUNT() FROM FeedItem '+String.valueOf(feedItemQry.split('FeedItem')[1]).split('ORDER')[0]);
            for(FeedItem fi: Database.query(feedItemQry)) {
                system.debug('::fi::OUT:'+fi);
                //if(entityIdVsTopicAssignmentMap.get(fi.Id) != null){
                    //for(TopicAssignment ta: entityIdVsTopicAssignmentListMap.get(fi.Id)){
                        TopicAssignment ta = entityIdVsTopicAssignmentMap.get(fi.id);
                        if(ta != null){
                            /*system.debug('::fi::IN:'+fi);
                            system.debug('@@ ta: '+ta);
                            system.debug('@@ ta.TopicId: '+ta.TopicId);
                            system.debug('@@ ta.Topic.Name: '+ta.Topic.Name);
                            system.debug('@@ fi.Title: '+fi.Title);
                            system.debug('@@ community.siteUrl: '+community.siteUrl);*/
                            lResult.add(new PortalRecordsWrapper(fi.Id,ta.TopicId,ta.Topic.Name,fi.Title,community.siteUrl));
                        }
                     //10/06 - Pagination Changes
                       // totalRecords++;
                    //}
                //}
            }
            system.debug('@@ lResult:'+JSON.serializePretty(lResult));
            //Total Records
            Integer recordEnd = pSize * pNumber;
            
            //Instance of resultWrapper Table Wrapper Class
            resultWrapper objDT =  new resultWrapper();  
            objDT.pageSize = pSize;
            objDT.pageNumber = pNumber;
            objDT.recordStart = offset + 1;
            objDT.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
            objDT.totalRecords = totalRecords;
            objDT.resultList = lResult;
            
            return objDT;
        } catch(Exception e){
            system.debug('@@ error:' + e.getMessage()+', at line: '+e.getLineNumber());
            return new resultWrapper();
        }            

    }
    
    public class PortalRecordsWrapper {
        @AuraEnabled public Id FeedItemId {get;set;}
        @AuraEnabled public String TopicId {get;set;}
        @AuraEnabled public String TopicName {get;set;}     
        @AuraEnabled public String Title {get;set;}
        @AuraEnabled public String portalUrl {get;set;}
        public PortalRecordsWrapper(Id FeedId, Id topicId, String Topic, String title, String url) {
            this.FeedItemId = FeedId;
            this.TopicId = topicId;
            this.TopicName = Topic;
            this.Title = title;
            this.portalUrl = url;
        }
    }
    
    public class resultWrapper {
        @AuraEnabled public Integer pageSize {get;set;}
        @AuraEnabled public Integer pageNumber {get;set;}
        @AuraEnabled public Integer totalRecords {get;set;}
        @AuraEnabled public Integer recordStart {get;set;}
        @AuraEnabled public Integer recordEnd {get;set;}
        @AuraEnabled public List<PortalRecordsWrapper> resultList {get;set;}
    }
}