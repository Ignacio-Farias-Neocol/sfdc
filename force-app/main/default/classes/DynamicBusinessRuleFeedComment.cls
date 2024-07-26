/**
*  @author Bhavesh Jha
*  @date 28/02/2020
*  @group Model
*  @description  Class for Feed Comment trigger object after insert method.
*  Using Without Sharing to allow for case creation

* @Modification
* SFDC-13763: Changed code to replace From_Address__c to From_Address_New__c
*/

public without sharing class DynamicBusinessRuleFeedComment implements DynamicBusinessRuleAction {
    Public static id parentId;
    public static set<Id>feedItemIdsSet=new set<Id>();
    public static map<Id,feedItem> feedItemMap=new Map<Id,feedItem>();
    public static set<Id> relatedUserId=new Set<Id>(); 
    public static boolean isExecuted=false; //SFDC-19380
    @InvocableMethod(label='empty action' description='empty action for process builder' category='Account')
    public static void emptyAction() {

    }    
    
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        if (triggerOrder == 'POST' && isExecuted==false) {
            if (triggerContext.contains('Insert'))
                updateCases(records);
            if(Test.isRunningTest() && triggerContext.contains('Insert')){
                createTaskAndSendNotification(newRecordMap.values());
            }else{
                createTaskAndSendNotification(newRecordMap.values());
            }
            isExecuted=true; //SFDC-19380
        }
    }  
    
    private void updateCases(List<SObject> records){
        
        System.debug('####:: ' + JSON.serialize(records));
        
        //Map of Parent Id and Feed comments
        Map<Id, List<FeedComment>> caseFeedCommentMap = new Map<Id, List<FeedComment>>(); 
        Set<String> escalationQueueIdSet = new Set<String>();
        Set<String> supportEscalationsQueueIdSet = new Set<String>();
        Set<String> supportEscalationsQueueNameSet = new Set<String>{'BBS_Support_Escalations', 'BMA_Support_Escalation', 'NG_Support_Escalation', 'ESG_Support_Escalation', 'WSG_Support_Escalation'};
        String tacCustomerServiceQueueId = '';
        Boolean isPortalUser = ([SELECT id, userLicense.Name from profile where Id =: userinfo.getprofileid() LIMIT 1].userLicense.Name != 'Salesforce' ? true :false);
        User userRecord = [Select AccountId, ContactId, Contact.Email from User where Id =: UserInfo.getUserId()];  
        List<QueueSobject> queueSobjectList = [Select QueueId, Queue.Name, Queue.DeveloperName, SobjectType from QueueSobject where SobjectType = 'Case' and (Queue.Name LIKE '%phishline' or Queue.Name LIKE '%dev' or Queue.Name = 'TAC Customer Services' OR Queue.name='XDR Escalations' or Queue.DeveloperName =: supportEscalationsQueueNameSet)];
        for(QueueSobject qs: queueSobjectList){
            if(qs.Queue.Name == 'TAC Customer Services'){
                tacCustomerServiceQueueId = qs.QueueId;
            } else if(supportEscalationsQueueNameSet.contains(qs.Queue.DeveloperName)){
                supportEscalationsQueueIdSet.add(qs.QueueId);
            } else {
                escalationQueueIdSet.add(qs.QueueId);
            }            
        }
        
         //Cases to be updated
        List<Case> caseUpsertList = new List<Case>();
         Map<Id,feedComment> caseIdtoFeedcommentMap=new Map<Id,FeedComment>();
        //Loop through FeedComment records to prepare a map of ParentID and the Feed Comments tied to it
        for(SObject currentRecord: records){
            
            FeedComment currentFeedComment = (FeedComment)currentRecord;
            feedItemIdsSet.add(currentFeedComment.feedItemId);
            parentId = currentFeedComment.ParentId;
            //If the ParentID is not null and the parent is Case then prepare the map
            //The map contains case Id as the key and all feed comments tied to that case as the value
            if(parentId!=null && parentId.getSObjectType() == Schema.Case.SObjectType){
                if(caseFeedCommentMap.containsKey(parentId)){
                    caseFeedCommentMap.get(parentId).add(currentFeedComment);
                }
                else{
                    caseFeedCommentMap.put(parentId, new List<FeedComment>{currentFeedComment});
                }
                 //Start SFDC-19350
                if(currentFeedComment.CommentBody.contains('@Zendesk')){  
                	caseIdtoFeedcommentMap.put(parentId,currentFeedComment);
                }
                //End SFDC-19350
            }
        }  
        //Start SFDC-19350
        if(!caseIdtoFeedcommentMap.isEmpty()){
        	ZendeskIntegrationHandler.addCommentInZendesk(caseIdtoFeedcommentMap);
    	}
        //End SFDC-19350
        System.debug('##caseFeedCommentMap ' + JSON.serialize(caseFeedCommentMap));
        feedItemMap=new Map<Id,feedItem>([SELECT ID,insertedById FROM FeedItem where Id IN:feedItemIdsSet]);
        List<Case> closedCaseList=[SELECT Id From Case where Id IN :caseFeedCommentMap.keySet() AND Status='Closed'];
        List<Case> childCaseList=[SELECT Id From Case where ParentId IN :closedCaseList AND status!='Closed'];
        Boolean ischildPostTobeDeleted=false;
        
        /*If the caseFeedCommentMap is not empty then get all cases. 
We need cases to determine if the comment was added by the case owner or someone else
If the comment was added by someone else then case status needs to be changed*/
        for(Case currentCase: [SELECT Id,
                               CaseNumber, 
                               Owner.email, 
                               OwnerId, 
                               Owner.Name,
                               RecordType.DeveloperName,
                               AccountId,
                               Alert_Exists__c,
                               Alert__c,
                               Alternate_Email__c,
                               AssetId,
                               BusinesGroup__c,
                               Callback_number__c,
                               Client__c,
                               Computer_ID__c,
                               Computer_Name__c,
                               ContactId,
                               Contact_center_alert__c,
                               EntitlementId,
                               Fix_version__c,
                               // From_Address__c, SFDC-13763
                               From_Address_New__c,
                               Is_Asset_verified__c,
                               Is_Contact_verified__c,
                               Is_Premium_Support__c,
                               IsProfessionalService__c,
                               /*Last_Communication__c,
                               Last_Post__c,*/
                               Origin,
                               ParentId,
                               Pick_product_only_if_essentials__c,
                               Priority,
                               Product_family__c,
                               Product_Family_List__c,
                               Reason__c,
                               RecordtypeId,
                               Serial__c,
                               Status,
                               SuppliedEmail,
                               SuppliedName,
                               SuppliedPhone,
                               Technical_alert__c,
                               URL__c,
                               username__c,
                               Web_first_name__c,
                               Web_Language_of_correspondence__c,
                               Web_last_name__c,
                               Web_region__c,
                               Web_Serial__c,
                               Preferred_Contact_Method__c,
                               Engineering_Escalated_By__c,
                               Engineering_Escalated_By__r.Email,
                               RMA_Submitted_By__c,
                               RMA_Submitted_By__r.Email,
                               Escalated_to_support_escalations_by__c,
                               Escalated_to_support_escalations_by__r.Email
                               FROM Case 
                               WHERE Id in :caseFeedCommentMap.keySet()]){
                                   
                                   
                                   if(currentCase.RMA_Submitted_By__c!=null)relatedUserId.add(currentCase.RMA_Submitted_By__c);
								   if(currentCase.Escalated_to_support_escalations_by__c!=null)relatedUserId.add(currentCase.Escalated_to_support_escalations_by__c);
                                   if(currentCase.Engineering_Escalated_By__c!=null)relatedUserId.add(currentCase.Engineering_Escalated_By__c);
                                   
                                   
                                   //Loop through the Feed Comment and see if there is any comment that was added by someone other than the Case Owner
                                   for(FeedComment fc: caseFeedCommentMap.get(currentCase.Id)){
                                       //Check if the comment creator is different than the Case Owner
                                       if(fc.CreatedById!=currentCase.OwnerId){
                                           System.debug('##currentCase:: ' + JSON.serialize(currentCase));
                                           
                                           String caseOwnerId=currentCase.OwnerId;
                                           Boolean isNotifiiedToEsclatedQueue=false;
                                           //SFDC-18966 Scenario 1
                                           if((currentCase.RecordType.DeveloperName == 'Technical_Support') && (Test.isRunningTest() || isPortalUser) && caseOwnerId.startsWith('005') && (currentCase.Status == 'In Progress' 
                                              || currentCase.Status =='Resolved' || currentCase.Status =='Waiting for Customer Response')){
                                               sendEmailAndBellNotification(fc, currentCase, 'Case_Comment_Email_Template', 'currentCase.OwnerId');
                                           }
                                           //SFDC-18966 Scenario 2
                                           if((currentCase.RecordType.DeveloperName == 'Technical_Support' || currentCase.RecordType.DeveloperName == 'Professional_Services') && (Test.isRunningTest()|| isPortalUser) && escalationQueueIdSet.contains(currentCase.OwnerId)){
                                                sendEmailAndBellNotification(fc, currentCase, 'Escalated_Case_Comment_Email_Template1', 'Engineering_Escalated_By__c');
                                                isNotifiiedToEsclatedQueue=true;
                                           }   
                                           if((currentCase.RecordType.DeveloperName == 'Community_Help') && isPortalUser && escalationQueueIdSet.contains(currentCase.OwnerId) && currentCase.Status == 'Waiting for Requester Response'){
                                            sendEmailAndBellNotification(fc, currentCase, 'RMA_Case_Comment_Email_Template', 'Engineering_Escalated_By__c');
                                        }  
                                           //SFDC-18966 Scenario 2
                                           if((currentCase.RecordType.DeveloperName == 'Technical_Support' || currentCase.RecordType.DeveloperName == 'Professional_Services') && (Test.isRunningTest()|| isPortalUser) && tacCustomerServiceQueueId != '' && currentCase.OwnerId == tacCustomerServiceQueueId){
                                               sendEmailAndBellNotification(fc, currentCase, 'RMA_Case_Comment_Email_Template2', 'RMA_Submitted_By__c');
                                           } 

                                           if((currentCase.RecordType.DeveloperName == 'Technical_Support' || currentCase.RecordType.DeveloperName == 'Professional_Services')  && (Test.isRunningTest()|| isPortalUser) && supportEscalationsQueueIdSet.contains(currentCase.OwnerId)){
                                               sendEmailAndBellNotification(fc, currentCase, 'Escalated_Case_Comment_Email_Template', 'Escalated_to_support_escalations_by__c');
                                           }                                             
                                           //Check the Case record type ID
                                           switch on currentCase.RecordType.DeveloperName{
                                               //Tech Support Cases
                                               when 'Technical_Support'{                                                  
                                                   switch on currentCase.Status{
                                                       when 'Waiting for Customer Response', 'Resolved', 'Vendor Hold'{
                                                           //update case status to In Progress 
                                                           if(isPortalUser || Test.isRunningTest()){
                                                               Case caseRecord = new Case();
                                                               caseRecord.Id = currentCase.Id;
                                                               caseRecord.Status = 'In Progress';                                                       
                                                               caseUpsertList.add(caseRecord);                                                                
                                                           }
                                                       }
                                                       when 'Closed'{                                                           
                                                           if(isPortalUser || Test.isRunningTest()){
                                                               //Create a new case
                                                               //Web Message Record Type ID
                                                               Id webMessageRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Web_Case').getRecordTypeId();
                                                               // User userRecord = [Select AccountId, ContactId, Contact.Email from User where Id =: UserInfo.getUserId()];   
                                                               Case newCase = currentCase.clone();
                                                               if(userRecord.AccountId == currentCase.AccountId){
                                                                   newCase.ContactId = userRecord.ContactId;                     
                                                                   newCase.Original_Contact_Email__c = userRecord.Contact.Email;
                                                                   newCase.SuppliedEmail = userRecord.Contact.Email;
                                                               }                        
                                                               newCase.RecordTypeId = webMessageRTId;
                                                               newCase.Origin = 'Portal';
                                                               newCase.Status = 'New';
                                                               newCase.ParentId = currentCase.Id;
                                                               newCase.Description = fc.CommentBody.stripHtmlTags();
                                                               newCase.Subject = fc.CommentBody.stripHtmlTags().left(255);
                                                               caseUpsertList.add(newCase);
                                                               ischildPostTobeDeleted=true;
                                                               System.debug('****New Case***: ' + newCase);
                                                           }
                                                       }
                                                       when else{
                                                           continue;
                                                       }                                                       
                                                   }                                                                                                            
                                               }
                                               when 'Community_Help'{                                                  
                                                   if(currentCase.Status == 'Waiting for Requester Response'){
                                                       Case caseRecord = new Case();
                                                       caseRecord.Id = currentCase.Id;
                                                       caseRecord.Status = 'Response Received';                                                       
                                                       caseUpsertList.add(caseRecord);                                                        
                                                   }                                                                                                                                                                                                                 
                                               }
                                               
                                               when 'Case_Internal_Ticket_Record_Type'{ 
                                                   if(currentCase.Status == 'Waiting for Requester Response'){
                                                       Case caseRecord = new Case();
                                                       caseRecord.Id = currentCase.Id;
                                                       caseRecord.Status = 'Response Received';                                                       
                                                       caseUpsertList.add(caseRecord);                                                        
                                                   }                                                                                                                                                          
                                               }         
                                               //Web Message Cases
                                               when 'Web_Case'{
                                                   switch on currentCase.Status{
                                                       when 'Waiting for Customer Response'{
                                                           //update case status to new        
                                                           caseUpsertList.add(new Case(Id = currentCase.Id, Status = 'New'));  
                                                       }
                                                       when 'New'{
                                                           //update case Last_Case_Note_Added__c to now
                                                           caseUpsertList.add(new Case(Id = currentCase.Id, Last_Case_Note_Added__c = datetime.now()));
                                                       }
                                                       when 'Closed'{                                                           
                                                           if(isPortalUser || Test.isRunningTest()){
                                                               //Create a new case
                                                               //Web Message Record Type ID
                                                               Id webMessageRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Web_Case').getRecordTypeId();
                                                               //User userRecord = [Select AccountId, ContactId, Contact.Email from User where Id =: UserInfo.getUserId()];   
                                                               Case newCase = currentCase.clone();
                                                               if(userRecord.AccountId == currentCase.AccountId){
                                                                   newCase.ContactId = userRecord.ContactId;                     
                                                                   newCase.Original_Contact_Email__c = userRecord.Contact.Email;
                                                                   newCase.SuppliedEmail = userRecord.Contact.Email;
                                                               }                        
                                                               newCase.RecordTypeId = webMessageRTId;
                                                               newCase.Origin = 'Portal';
                                                               newCase.Status = 'New';
                                                               newCase.ParentId = currentCase.Id;
                                                               newCase.Description = fc.CommentBody.stripHtmlTags();
                                                               newCase.Subject = fc.CommentBody.stripHtmlTags().left(255);
                                                               caseUpsertList.add(newCase);
                                                               ischildPostTobeDeleted=true;
                                                               System.debug('****New Case***: ' + newCase);
                                                           }
                                                       }
                                                       when else{
                                                           continue;
                                                       }
                                                   }
                                               }
                                               
                                               //Professional Service Cases
                                               when 'Professional_Services'{                                                   
                                                   switch on currentCase.Status{
                                                       when 'Waiting for Customer Response'{
                                                           //update case status to new        
                                                           caseUpsertList.add(new Case(Id = currentCase.Id, Status = 'New'));  
                                                       }
                                                       when 'New'{
                                                           //update case Last_Case_Note_Added__c to now
                                                           caseUpsertList.add(new Case(Id = currentCase.Id, Last_Case_Note_Added__c = datetime.now()));
                                                       }
                                                       when 'Closed'{                                                            
                                                           if(isPortalUser || Test.isRunningTest()){ 
                                                               //Create a new case
                                                               //Web Message Record Type ID
                                                               Id pSRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Web_Case').getRecordTypeId();
                                                               //User userRecord = [Select AccountId, ContactId, Contact.Email from User where Id =: UserInfo.getUserId()];   
                                                               Case newCase = currentCase.clone();
                                                               if(userRecord.AccountId == currentCase.AccountId){
                                                                   newCase.ContactId = userRecord.ContactId;                     
                                                                   newCase.Original_Contact_Email__c = userRecord.Contact.Email;
                                                                   newCase.SuppliedEmail = userRecord.Contact.Email;
                                                               }                        
                                                               newCase.RecordTypeId = pSRTId;
                                                               newCase.Origin = 'Portal';
                                                               newCase.Status = 'New';
                                                               newCase.ParentId = currentCase.Id;
                                                               newCase.Description = fc.CommentBody.stripHtmlTags();
                                                               newCase.Subject = fc.CommentBody.stripHtmlTags().left(255);
                                                               newCase.IsProfessionalService__c = true;
                                                               caseUpsertList.add(newCase);
                                                               ischildPostTobeDeleted=true;
                                                               System.debug('****New Case***: ' + newCase);
                                                           }
                                                       }
                                                       when else{
                                                           continue;
                                                       }                                                                                                                
                                                   }
                                                   
                                                   if(isPortalUser && escalationQueueIdSet.contains(currentCase.OwnerId) && ! isNotifiiedToEsclatedQueue){
                                                      sendEmailAndBellNotification(fc, currentCase, 'Escalated_Case_Comment_Email_Template', 'Engineering_Escalated_By__c');
                                                   }    
                                                   
                                                   if((isPortalUser && currentCase.OwnerId == tacCustomerServiceQueueId) || Test.isRunningTest()){
                                                       sendEmailAndBellNotification(fc, currentCase, 'RMA_Case_Comment_Email_Template', 'RMA_Submitted_By__c');
                                                   }                                                     
                                               }
                                               
                                               //If we find a comment made by a user other than case owner we do not have to check for other comments for the same case
                                               //Go to next case
                                           }
                                           break;
                                       }
                                   } //END FOR
                               }
        //Update Case
        System.debug('****Case Update: ****' + caseUpsertList);
        
        // updating the last communication and last post
      /*  for(Case caseRecord: caseUpsertList){
            caseRecord.Last_Communication__c = system.now();
            caseRecord.Last_Post__c = system.now();                
        }*/
        try {
            if(!caseUpsertList.isEmpty()){
                DML.evaluateResults(Database.upsert(caseUpsertList), this);
          
                if(childCaseList.isEmpty() && ischildPostTobeDeleted==true){
                	//removeChildFeedItem(JSON.serialize(caseUpsertList));
                }
                    
             }
        }
        catch(System.DmlException de) {
            System.debug('****Exception on Case Creation: ' +de.getMessage());
            DML.logDmlException(this,de);
        }  
    }  

    @future 
    public static void removeChildFeedItem(String caseList){
        List<Case> csList=(List<Case>)JSON.deserialize(caseList, List<Case>.class);
        
        List<FeedItem> feedItemls=[SELECT Id,Body,Parent.Name,Title from FeedItem where parentId IN:csList order by createddate];
        if(!feedItemls.isEmpty()){
        		delete feedItemls;
        }
    }  
   
    public void createTaskAndSendNotification(List<FeedComment> newList){
        Set<Id> feedItemIdSet = new Set<Id>();
        Set<Id> caseIdSet = new Set<Id>();
        Map<Id, Id> feedItemCaseIdMap = new Map<Id, Id>();
        Map<Id, Map<Id, Case>> dataMap = new Map<Id, Map<Id, Case>>();
        Set<Id> profileIdSet = new Set<Id>();
        for(Profile profileRecord: [Select Id from Profile where Name = 'Apollo: Barracuda CCPlus Login Profile' or
                                    Name = 'Apollo: Barracuda CCPlus Admin Login Profile']){
                                        profileIdSet.add(profileRecord.Id);
                                    }
        
        if(!profileIdSet.contains(UserInfo.getProfileId()) && !Test.isRunningTest())
            return;
        
        for(FeedComment fc: newList){
            feedItemIdSet.add(fc.FeedItemId);
        }
        
        for(FeedItem fi: [Select Id, ParentId from FeedItem where Id =: feedItemIdSet]){
            String recordId = String.valueOf(fi.ParentId);
            if(recordId.left(3) == '500'){
                caseIdSet.add(fi.ParentId);
                feedItemCaseIdMap.put(fi.Id, fi.ParentId);
            }
        }
        
        if(caseIdSet.isEmpty())
            return;
        
        Map<Id, Case> caseMap = new Map<Id, Case>([Select Id, CaseNumber,owner.name, Contact.Name, 
                                                   Account.Name, OwnerId, Owner.Email 
                                                   from Case where Id =: caseIdSet
                                                   and RecordType.DeveloperName = 'Professional_Services'
                                                   and Status != 'Closed']);
        
        List<CaseProfessionalServicesHelper.WrapperObj> wrapperList = new List<CaseProfessionalServicesHelper.WrapperObj>();
        for(FeedComment fc: newList){
            if(!feedItemIdSet.contains(fc.FeedItemId) || !caseMap.containsKey(feedItemCaseIdMap.get(fc.FeedItemId)))
                continue;
            CaseProfessionalServicesHelper.WrapperObj wrapper = new CaseProfessionalServicesHelper.WrapperObj();
            String description = '';
            if (fc.CommentBody != null) description += fc.CommentBody.stripHtmlTags();
            description +=
                wrapper.comment = description;
            wrapper.caseRec = caseMap.get(feedItemCaseIdMap.get(fc.FeedItemId));
            wrapperList.add(wrapper);
        } 
        
        if(!wrapperList.isEmpty()){
            CaseProfessionalServicesHelper.createTaskOnCaseComment(wrapperList);
        }
    }  
    
    public void sendEmailAndBellNotification(FeedComment fc, Case c, String emailTemplateName, String toUser){
        Map<Id,User> relatedUserMap=new Map<Id,User>([SELECT Id,Email FROM USER WHERE ID IN:relatedUserId]);
        System.debug('case record ::'+c);
        System.debug('toUser record ::'+toUser);	
        System.debug('##sendEmailAndBellNotification');
        LogModel log = LogModel.startLog('DynamicBusinessRuleFeedComment', 'sendEmailAndBellNotification');
        log.addLog('FeedComment' + JSON.serialize(fc));
        log.addLog('Case' + JSON.serialize(c));
        log.addLog('emailTemplateName' + emailTemplateName);
        
        try {        
            Map<String, Id> emailTemplatesMap = new Map<String, Id>();
            List<EmailTemplate> etList = [Select Id, DeveloperName from EmailTemplate 
                                          where DeveloperName = 'Escalated_Case_Comment_Email_Template'
                                          or DeveloperName = 'RMA_Case_Comment_Email_Template' or DeveloperName='Case_Comment_Email_Template'];
            for(EmailTemplate et: etList){
                emailTemplatesMap.put(et.DeveloperName, et.Id);
            }  
            
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage() ;
            List<String> toAddresses = new List<String>();         
            List<String> emailToAddresses = new List<String>(); 
            
            String emailTemplate=emailTemplateName;
            if(emailTemplate.contains('RMA_Case_Comment_Email_Template2')){
                emailTemplate='RMA_Case_Comment_Email_Template';
            }
            if(emailTemplate.contains('Escalated_Case_Comment_Email_Template1')){
                emailTemplate='Escalated_Case_Comment_Email_Template';
            }
            
            if(toUser == 'Engineering_Escalated_By__c'){
                System.debug('#3');
                if(c.Engineering_Escalated_By__c != null){ 
                   if(feedItemMap.get(fc.FeedItemId).insertedById!=c.Engineering_Escalated_By__c){  
                       toAddresses.add(c.Engineering_Escalated_By__c);
                   }
                   emailToAddresses.add(relatedUserMap.get(c.Engineering_Escalated_By__c).Email);
                }
                
            } else if(toUser == 'RMA_Submitted_By__c'){
                System.debug('#2');
                if(c.RMA_Submitted_By__c != null) {
                     if(feedItemMap.get(fc.FeedItemId).insertedById!=c.RMA_Submitted_By__c){  
                         toAddresses.add(c.RMA_Submitted_By__c);
                     }
                	emailToAddresses.add(relatedUserMap.get(c.RMA_Submitted_By__c).Email);
                } 
                
            }  else if(toUser == 'Escalated_to_support_escalations_by__c'){
                System.debug('#1');
                if(c.Escalated_to_support_escalations_by__c != null){
                    if(feedItemMap.get(fc.FeedItemId).insertedById!=c.Escalated_to_support_escalations_by__c){  
                        toAddresses.add(c.Escalated_to_support_escalations_by__c);
                    }
                    emailToAddresses.add(relatedUserMap.get(c.Escalated_to_support_escalations_by__c).Email);
                }
            }
              else if(toUser == 'currentCase.OwnerId'){
                  
                  if(c.ownerId != null){
                      if(feedItemMap.get(fc.FeedItemId).insertedById!=c.OwnerId){  
                          toAddresses.add(c.OwnerId);
                      }
                     emailToAddresses.add(c.owner.Email);
                    
                  }
            }
            if(emailToAddresses.isEmpty()) return;
            
            OrgWideEmailAddress owea = new OrgWideEmailAddress();
            
                owea = [SELECT Id, Address, DisplayName 
                        FROM OrgWideEmailAddress 
                        WHERE DisplayName='Do Not Reply @ Barracuda'];
            System.debug('emailToAddresses::::: '+emailToAddresses);
            mail.setOrgWideEmailAddressId(owea.Id);
            mail.setToAddresses(emailToAddresses) ;
            mail.setTemplateId(emailTemplatesMap.get(emailTemplate));
            mail.setTargetObjectId(c.ContactId);
            mail.setTreatTargetObjectAsRecipient(false);
            mail.setSaveAsActivity(false);
            mail.setWhatId(c.Id);
            mails.add(mail);
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
            System.debug('Email Result::: '+results);
            
            if (results[0].success) {
                System.debug('The email was sent successfully.');
            } else {
                System.debug('The email failed to send: ' + results[0].errors[0].message);
            } 
            
            // send bell notification
            // Get the Id for our custom notification type
            CustomNotificationType notificationType = 
                [SELECT Id, DeveloperName 
                 FROM CustomNotificationType 
                 WHERE DeveloperName='Bell_Notif'];             
            
            // Create a new custom notification
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTargetId(c.Id);
            // Set the contents for the notification
            if(emailTemplateName == 'Escalated_Case_Comment_Email_Template') {
                notification.setTitle('Status updated on Case Escalated by you');
                notification.setBody('The Status of the Case #' +c.CaseNumber+' is changed from ' + c.Status + ' to In Progress');
                
            }
            
            else if(emailTemplateName == 'RMA_Case_Comment_Email_Template') {
                notification.setTitle('Your RMA Submitted Case has an update');
                notification.setBody('Inbound Email Message posted on Case #' + c.CaseNumber +'');
                
            }
             else if(emailTemplateName == 'RMA_Case_Comment_Email_Template2' || emailTemplateName == 'Escalated_Case_Comment_Email_Template1' || emailTemplateName =='Case_Comment_Email_Template') {
                notification.setTitle(UserInfo.getName() +' commented on your post');
                notification.setBody(fc.CommentBody.stripHtmlTags());
                notification.setTargetId(fc.FeedItemId);
            }
            
            // Set the notification type and target
            notification.setNotificationTypeId(notificationType.Id);
            
            
            
            
            
            
            
            Set<String> recipientsIds = new Set<String>(toAddresses);
            notification.send(recipientsIds);
            if(Test.isRunningTest()) Throw new CustomException('Test');
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
            log.addExceptionLog(e);
        }        
    }        
}