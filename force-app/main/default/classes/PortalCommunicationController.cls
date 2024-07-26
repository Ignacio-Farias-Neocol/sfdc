/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-24-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class PortalCommunicationController {
    public portalCommunicationController() {}
    
    @AuraEnabled
    public static String getCustomerComments(String req){ 
        Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(req); 
        Set<Id> contentVersionIdSet=new Set<Id>();
        Set<Id> cdnIdSet=new Set<Id>();
        String recordId = (String) requestMap.get('recordId');
        Case caseobj = [SELECT CreatedBy.Name,Id, Customers_Provided_Business_Impact__c, 
                        preferred_Contact_Method__c , Origin,
                        Close_Reason_Comments__c,Community_Request_Close_Reason__c 
                        FROM Case WHERE Id=: recordId LIMIT 1];
        
        String caseCreatedUserName = caseobj.CreatedBy.Name;
        
        Set<String> customerTypes = new Set<String>{
            'PowerCustomerSuccess', 'CspLitePortal','PowerPartner','CsnOnly'
                };
                    
                    Set<String> postTypes = new Set<String>{
                        'ContentPost', 'TextPost'
                            };
                                
                                List<FeedItem> feedItemsList = 
                                [
                                    SELECT Id, 
                                    ParentId, 
                                    Type, 
                                    Title, 
                                    Body,
                                    InsertedById,
                                    InsertedBy.Name, 
                                    // CreatedBy.SmallPhotoUrl, 
                                    Createddate,
                                    NetworkScope,
                                    (SELECT 
                                     Id, 
                                     ParentId, 
                                     FeedItemId, 
                                     CommentBody, 
                                     relatedRecordId,
                                     InsertedById,
                                     InsertedBy.Name, 
                                     InsertedBy.UserType, 
                                     InsertedBy.SmallPhotoUrl,
                                     CommentType,
                                     CreatedDate
                                     FROM FeedComments 
                                     WHERE ParentId =: recordId
                                     //AND InsertedBy.UserType IN : customerTypes                    
                                     ORDER BY Createddate Asc) 
                                    FROM FeedItem 
                                    WHERE ParentId =: recordId AND Visibility= 'AllUsers' 
                                    //AND Type IN : postTypes
                                    ORDER BY Createddate Asc
                                ];
        //Start SFDC- 18849 
        
        for(feedItem itm:feedItemsList){
 
            contentVersionIdSet.add(itm.Id);

        for(feedComment fc:itm.feedComments){
                    contentVersionIdSet.add(fc.Id);
                    cdnIdSet.add(fc.relatedRecordId);
                   
            }
            
        }
        Map<id,FeedAttachment> cVMap;
        Map<id,List<Id>> cdnMap=new Map<Id,List<Id>>();
        if(!contentVersionIdSet.isEmpty()){
            cVMap=new Map<Id,FeedAttachment>([SELECT ID,RecordId,FeedEntityId FROM FeedAttachment  where FeedEntityId  in :contentVersionIdSet ]); 
        }
		System.debug('cdnMap:: '+cVMap);
        if(cVMap !=null ){
               for(String key:cVMap.keySet()){
                List<Id> IdList=new List<Id>();
                
                if(cdnMap.containsKey(cVMap.get(key).FeedEntityId)){
                    IdList=cdnMap.get(cVMap.get(key).FeedEntityId);
                }
                IdList.add(cVMap.get(key).RecordId);
                cdnIdSet.add(cVMap.get(key).RecordId);
                cdnMap.put(cVMap.get(key).FeedEntityId,IdList);
        }
        }

        Map<Id,ContentVersion> contentVersionMap=new Map<Id,ContentVersion>();
        if(!cdnIdSet.isEmpty()){
            contentVersionMap=new Map<Id,ContentVersion>([SELECT ID,ContentDocumentId FROM ContentVersion where Id IN :cdnIdSet]); 
        }
       //End SFDC- 18849 
        List<String> userIds = new List<String>();
        List<FeedItemWrp> feedItemWrpList = new List<FeedItemWrp>();
        for(FeedItem  feedItemObj : feedItemsList){
            List<FeedComment> customerComments = feedItemObj.FeedComments;
            if(customerComments == null || customerComments.isEmpty()){
                //continue;
            }
            if(feedItemObj.type == 'CreateRecordEvent' && (customerComments == null || customerComments.isEmpty()) && caseobj.Origin != 'Portal' ){
                if(caseCreatedUserName != 'Maestro MSP') {
                    if(string.isBlank(caseObj.Community_Request_Close_Reason__c))
                        continue;
                }
                
            }
            //Start SFDC- 18849 
        List<String> attachemntIds=new List<String>();
        if(cdnMap.containsKey(feedItemObj.Id)){ 
          for(String entityId:cdnMap.get(feedItemObj.Id)){
              if(contentVersionMap.containsKey(entityId)){
                  System.debug('content Document::: '+contentVersionMap.get(entityId).ContentDocumentId);
                    attachemntIds.add(contentVersionMap.get(entityId).ContentDocumentId);
              }else{
                    attachemntIds.add(entityId);
              }
                 
          }
          }
		//End SFDC- 18849 

            FeedItemWrp feedItemWrpObj = new FeedItemWrp();
            feedItemWrpObj.relatedRecordId=attachemntIds;
            feedItemWrpObj.commentBody=feedItemObj.Body;
            feedItemWrpObj.commentType = feedItemObj.Type;
            feedItemWrpObj.feedItemId = feedItemObj.Id;
            feedItemWrpObj.parentId = feedItemObj.parentId;
            feedItemWrpObj.userId = feedItemObj.InsertedById;
            feedItemWrpObj.userName = feedItemObj.InsertedBy.Name;
            userIds.add(feedItemWrpObj.userId);
            //feedItemWrpObj.smallPhotoURL = feedItemObj.CreatedBy.smallPhotoURL;
            
            feedItemWrpObj.agoDate = getRelativeDateTime(feedItemObj.Createddate, Datetime.now());
            List<FeedCommentWrp> feedCommentWrpList = new List<FeedCommentWrp>();
            Boolean isCustomerComment = false;
            for(FeedComment customerCommentObj  : customerComments){
                if( customerTypes.contains(customerCommentObj.InsertedBy.UserType) || test.isRunningTest()){
                    isCustomerComment = true;
                }
                FeedCommentWrp feedCommentWrpObj = new FeedCommentWrp();
                
                feedCommentWrpObj.commentBody = customerCommentObj.CommentBody;
                
                //Start SFDC- 18849 
                List<String> attachemntId=new List<String>();
          
                if(cdnMap.containsKey(customerCommentObj.Id)){ 
                for(String entityId:cdnMap.get(customerCommentObj.Id)){
                     attachemntId.add(entityId);
                } 
               
                }
                 
                if(customerCommentObj.relatedRecordId!=null && contentVersionMap.containsKey(customerCommentObj.relatedRecordId)){
                    
                    attachemntId.add(contentVersionMap.get(customerCommentObj.relatedRecordId).ContentDocumentId);   
                }
                //End SFDC- 18849 
                
                feedCommentWrpObj.feedItemId = customerCommentObj.FeedItemId;
                feedCommentWrpObj.parentId = customerCommentObj.ParentId;
                feedCommentWrpObj.userId = customerCommentObj.InsertedById;
                feedCommentWrpObj.userName = customerCommentObj.InsertedBy.Name;
                feedCommentWrpObj.commentType = customerCommentObj.CommentType;
                feedCommentWrpObj.feedCommentId = customerCommentObj.Id;
                feedCommentWrpObj.smallPhotoURL = customerCommentObj.InsertedBy.SmallPhotoUrl;
                feedCommentWrpObj.agoDate = getRelativeDateTime(customerCommentObj.Createddate, Datetime.now());
                feedCommentWrpObj.relatedRecordId=attachemntId;
                feedCommentWrpList.add(feedCommentWrpObj);
            }
            feedItemWrpObj.feedCommentWrpList = feedCommentWrpList;
            if(isCustomerComment || true){
                feedItemWrpList.add(feedItemWrpObj);
            }
        }
        
        Map<Id, User> userIdObjMap = new Map<Id, User>([Select Id,smallPhotoURL FROM User WHERE Id IN: userIds]);
        for(FeedItemWrp feedItemWrpObj : feedItemWrpList){
            feedItemWrpObj.smallPhotoURL = userIdObjMap.get(feedItemWrpObj.userId).smallPhotoURL;
        }
        
        /*
List<FeedComment> customerComments = 
[
SELECT 
Id, 
ParentId, 
FeedItemId, 
CommentBody, 
InsertedById,
InsertedBy.Name, 
InsertedBy.UserType, 
InsertedBy.SmallPhotoUrl,
CommentType,
CreatedDate
FROM FeedComment 
WHERE InsertedBy.UserType IN : customerTypes
AND ParentId =: recordId
ORDER BY Createddate Asc
];
*/
        
        
        User currentUser = 
            [
                SELECT 
                Id,
                Name,
                SmallPhotoUrl
                FROM User
                WHERE Id=:UserInfo.getUserId()
            ];
        
        Map<String,Object> res = new Map<String, object>();
        res.put('status', true);
        res.put('isMSPCase', caseCreatedUserName == 'Maestro MSP' ? true : false);
        res.put('currentUser', currentUser);
        if(caseCreatedUserName == 'Maestro MSP' && feedItemWrpList.size() == 1 && feedItemWrpList[0].feedCommentWrpList.isEmpty() &&  string.isBlank(caseObj.Community_Request_Close_Reason__c)){
            feedItemWrpList = new List<FeedItemWrp>();
        }
        res.put('feedCommentWrpList', feedItemWrpList);
        res.put('caseObj', [SELECT Id, Customers_Provided_Business_Impact__c, preferred_Contact_Method__c , Origin,
                            Close_Reason_Comments__c,Community_Request_Close_Reason__c  FROM Case WHERE Id=: recordId LIMIT 1]);
        return JSON.serializePretty(res);
    }
    
    
    public class FeedItemWrp{
        @AuraEnabled public String feedItemId{get;set;}
        @AuraEnabled public String parentId{get;set;}
        @AuraEnabled public String commentBody{get;set;}
        @AuraEnabled public String userId{get;set;}
        @AuraEnabled public String userName{get;set;}
        @AuraEnabled public String commentType{get;set;}
        @AuraEnabled public String smallPhotoURL{get;set;}
        @AuraEnabled public String agoDate{get;set;}
        @AuraEnabled public List<FeedCommentWrp> feedCommentWrpList{get;set;}
        @AuraEnabled public List<String> relatedRecordId{get;set;}
    }
    
    public class FeedCommentWrp{
        @AuraEnabled public String feedCommentId{get;set;}
        @AuraEnabled public String feedItemId{get;set;}
        @AuraEnabled public String parentId{get;set;}
        @AuraEnabled public List<String> relatedRecordId{get;set;}
        @AuraEnabled public String commentBody{get;set;}
        @AuraEnabled public String userId{get;set;}
        @AuraEnabled public String userName{get;set;}
        @AuraEnabled public String commentType{get;set;}
        @AuraEnabled public String smallPhotoURL{get;set;}
        @AuraEnabled public String agoDate{get;set;}
        
    }
    
    
    public static String getRelativeDateTime(Long diff) {
        diff /= 1000; //turn milliseconds to seconds
        if (diff < 60) {
            return 'a few seconds';
        }
        
        diff /= 60; // turn seconds to minutes
        if (diff < 60) {
            return String.valueOf(diff) + ' minute' + (diff == 1 ? '' : 's');
        }
        
        diff /= 60; // turn minutes to hours
        if (diff < 24) {
            return String.valueOf(diff) + ' hour' + (diff == 1 ? '' : 's');
        }
        
        diff /= 24; // turn hours to days
        if (diff < 28) {
            return String.valueOf(diff) + ' day' + (diff == 1 ? '' : 's');
        }
        
        if (diff / 28 < 12) {
            return String.valueOf(diff / 28) + ' month' + (diff == 1 ? '' : 's');
        }
        
        diff /= 365; //  turn days to years
        return String.valueOf(diff / 28) + ' year' + (diff == 1 ? '' : 's');
    }
    
    public static String getRelativeDateTime(Datetime givenDate, Datetime toCompareDate) {
        Long diff = Math.abs(toCompareDate.getTime() - givenDate.getTime());
        
        if (givenDate <= toCompareDate) {
            return getRelativeDateTime(diff) + ' ago';
        } else {
            return 'in ' + getRelativeDateTime(diff);
        }
    }
    //Last Modfied: Start SFDC- 18849
    @AuraEnabled
    public static String insertFeedComment(String req){ 
        Map<String, Object> requestMap = (Map<String, Object>)JSON.deserializeUntyped(req); 
        String recordId = (String) requestMap.get('recordId');
        String feedItemId = (String) requestMap.get('feedItemId');
        String commentText = (String) requestMap.get('commentText');
        
        FeedComment fc = new FeedComment();
        if(commentText!=null)
        fc.CommentBody = commentText.escapeHtml4();
        fc.FeedItemId = feedItemId;
        //Modfied: End SFDC- 18849
        if(requestMap.containsKey('file') && String.valueOf(requestMap.get('file'))!=''){
            Map<String,Object>fileMap=(Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(requestMap.get('file')));
            if(fileMap.containsKey('base64')){
            	fc.relatedRecordId= insertAttachment(recordId,String.valueOf(fileMap.get('base64')),String.valueOf(fileMap.get('name')));
            }
        }
        //end
        insert fc;
        
        Map<String,Object> res = new Map<String, object>();
        res.put('status', true);
        return JSON.serializePretty(res);
    }
    

    //Start SFDC- 18849
    public static String insertAttachment(String csId,String body,string title){
        
        //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = title;
        cv.PathOnClient = title;
        cv.VersionData = EncodingUtil.base64Decode(body);
        cv.IsMajorVersion = true;
        Insert cv;
        
        //Get Content Documents
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
        //Create ContentDocumentLink 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = csId;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
        
        return cv.Id;
    }
    //end SFDC- 18849
    
}