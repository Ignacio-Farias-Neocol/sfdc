/**
* @author Dilowar Hussain
* @date 2023-10-18
*
* @description 
* When a case gets de-escalated from JIRA system, this class updates the Case owner back 
* to the person, who escalated it earlier. Also it creates a feed item with the comment added 
* by the service engineer from JIRA system.
*
* 
* This has been added as a part of SFDC-20019
*/
public with sharing class DynamicBusinessRuleCsFeedItemCreate implements DynamicBusinessRuleAction{
    /**
    * Method description:
    * @param
    * @Return
    * This has been added as a part of SFDC-20019
    */
    public void processRecords(Map<Id,SObject> newRecordMap, 
                                                            Map<Id,SObject> oldRecordMap,
                                                            List <SObject> records, 
                                                            String jsonParameter, 
                                                            String triggerOrder, 
                                                            String triggerContext) {
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('DynamicBusinessRuleCsFeedItemCreate', 'processRecords', LogModel.LOG_CATEGORY_APEX); 
        //system.debug('Invoke implements DynamicBusinessRuleAction Apex Class');
        Map<Id, Case> mapCase = new Map<Id, Case>();
        try{
            //Get the Case record types.
            Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
            Id caseRTProfId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
            //Get the users. This will be used to distinguish between Jira Integration user and 
            /*List<User> jiraIntgUser = new List<User>();
            String jiraIntgUserName = Label.Jira_Integration_UserName;
            if(jiraIntgUserName != NULL){
                jiraIntgUser = [select id from user where username = : jiraIntgUserName];
            }*/
            List<User> loggedInUserList = [Select id from User where id =: UserInfo.getUserId()];
            if((triggerContext.contains('Insert') || triggerContext.contains('Update')) 
                /*&& !String.valueOf(loggedInUserList[0]).equals(String.valueOf(autoUserList[0]))*/){
                    for(SObject rec: records){
                        Case cs = (Case)rec;
                        Case cs2 = oldRecordMap == null ? null : (Case)oldRecordMap.get(cs.Id);
                        if (cs2 == null){cs2 = new Case();}
                        if(caseRecordTypeId != NULL && caseRTProfId != NULL && (String.valueOf(caseRecordTypeId).equals(String.valueOf(cs.recordTypeID))||String.valueOf(caseRTProfId).equals(String.valueOf(cs.recordTypeID)))){
                            if((cs.Case_Descalation_comment__c != NULL && cs2.Case_Descalation_comment__c == NULL) || (cs.Case_Descalation_comment__c != NULL && cs2.Case_Descalation_comment__c != cs.Case_Descalation_comment__c)){
                                mapCase.put(cs.id, cs);
                            }
                        }
                    }
                if(!mapCase.isEmpty()){
                    //system.debug('Call Feed Item creation');
                    createFeedItemOnCase(mapCase);
                    for(SObject rec: records){
                        Case cs = (Case)rec;
                        Case cs2 = oldRecordMap == null ? null : (Case)oldRecordMap.get(cs.Id);
                        if (cs2 == null){cs2 = new Case();}
                        if(mapCase.containsKey(cs.id)){
                            //system.debug('Final Assignment');
                            cs.OwnerId = mapCase.get(cs.id).Engineering_Escalated_By__c != NULL ? mapCase.get(cs.id).Engineering_Escalated_By__c : cs.OwnerId;
                            cs.Last_Case_Note_Added__c = system.now();
                            //cs.Case_Re_Escalated__c = '';
                        }
                    }
                }
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception' +e.getMessage()+'occurred at:' +e.getStackTraceString());
        }  
    }
    
    /***************************
     * Method Description: 
     * Creates FeedItem record for a Case record.
     * 
     * @Param: Map<id, Case>
     * @return void
     */
    public static void createFeedItemOnCase(Map<id, Case> mapCS){
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('DynamicBusinessRuleCsFeedItemCreate', 'createFeedItemOnCase', LogModel.LOG_CATEGORY_APEX);
        String fbBody01 = Label.Jira_Integration_Feed_Static_Comment_01;
        String fbBody02 = Label.Jira_Integration_Feed_Static_Comment_02;
        String fbBody03 = Label.Jira_Integration_Feed_Static_Comment_03;
        String fbBody04 = Label.Jira_Integration_Feed_Static_Comment_04;
        List<FeedItem> lstFeeds = new List<FeedItem>();
        //String str = 'BNBS-52002';
        try{
            for(Case cs : mapCS.values()){
                //system.debug('Feed Item creation');
                if(cs.Jira_ID__c != NULL){
					  FeedItem fd = new FeedItem(
                    	parentId = cs.id,
                    	body = '<p>'+fbBody01+' '+'<a href="'+fbBody04+cs.Jira_ID__c+'"'+' '+'target="_blank">'+cs.Jira_ID__c+'</a>'+' '+fbBody02+' '+fbBody03+':</p><p>&nbsp;</p>'+cs.Case_Descalation_comment__c,
                    	//body = '<p>'+fbBody01+' '+'<a href="https://barratestrun2.atlassian.net/browse/'+str+'"'+' '+'target="_blank">'+str+'</a>'+' '+fbBody02+' '+fbBody03+':</p><p>&nbsp;</p>'+cs.Case_Descalation_comment__c,
                    	isRichText = true
                	);
					lstFeeds.add(fd);                    
                }	
            }
            //system.debug('lstFeeds is:' +lstFeeds);
            if(!lstFeeds.isEmpty()){
                insert lstFeeds;
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception' +e.getMessage()+'occurred at:' +e.getStackTraceString());
        }
    }
}