public without sharing class PriceListHelper {
    @AuraEnabled
    public static Map<String,String> getContentDocumentId(String theater, String currencyCode, String territory, String subTheater,String userId) {
        String condition = null;
        if(territory.contains('CHINA')){
            condition = '%CHINA%';
        }else if(subTheater.contains('LATAM')){
            condition = '%LATAM%';
        }else{
            condition = '%'+theater+'_'+currencyCode+'%';
        }
        System.debug('condition...'+condition);
        String contentDocId = null;
        Map<String,String> respMap = new Map<String,String>();
        String query = 'SELECT Id, Title,ContentDocumentId FROM ContentVersion WHERE Title LIKE :condition ORDER BY CREATEDDATE DESC LIMIT 1';
        List<ContentVersion> contentVersionList = Database.Query(query);
        System.debug('contentVersionList...'+contentVersionList);
        if(contentVersionList!=null && contentVersionList.size()>0){
            contentDocId = contentVersionList[0].ContentDocumentId;
        }
        ContentDocumentLink contentDocumentLink = createContentDocumentLink(contentDocId,userId);
        System.debug('contentDocumentLink...'+contentDocumentLink);
        respMap.put('contentDocId',contentDocId);
        respMap.put('contentDocLinkId',contentDocumentLink.Id);
        return respMap;
    }

    @AuraEnabled
    public static Map<String,String> createLibraryUserAccess(String userId) {
        Boolean libConfigSuccess = false;
        Map<String,String> mapOfRes = new Map<String,String>();
        //List<ContentWorkspace> contentWSList = [SELECT Id, Name FROM ContentWorkspace WHERE Name ='List Price' LIMIT 1];
        //if(contentWSList!=null && contentWSList.size()>0){
            ContentWorkspacePermission contentWSPermission = createContentWSPermission('List Price');
            ContentWorkspaceMember contentWSMember = createContentWSMember(System.Label.ContentWorkSpaceID,contentWSPermission.Id,userId);
            libConfigSuccess = true;
            mapOfRes.put('isLibraryConfigSuccess','true');
            mapOfRes.put('contentWSPermission',contentWSPermission.Id);
            mapOfRes.put('contentWSMember',contentWSMember.Id);
        
        return mapOfRes;
    }

    public static ContentWorkspacePermission createContentWSPermission(String contentWSName){
        ContentWorkspacePermission contentWSPermission = [SELECT Id,Type FROM ContentWorkspacePermission WHERE Type='Admin'];
       /* ContentWorkspacePermission contentWSPermission = new ContentWorkspacePermission();
        contentWSPermission.Type = 'Viewer';
        contentWSPermission.Name = contentWSName;
        contentWSPermission.PermissionsDeliverContent = true;
        INSERT contentWSPermission;*/

        return contentWSPermission;
    }

    public static ContentWorkspaceMember createContentWSMember(Id contentWSId, Id contentWSPermissionId, String userId){
        List<ContentWorkspaceMember> contentWSMemberexist = new List<ContentWorkspaceMember>();
        contentWSMemberexist = [SELECT Id,Member.Name FROM ContentWorkspaceMember WHERE ContentWorkspaceId =: contentWSId and MemberId =:userId];
        
        if(contentWSMemberexist.IsEmpty() && contentWSMemberexist.Size()==0){
            ContentWorkspaceMember contentWSMember = new ContentWorkspaceMember();
            contentWSMember.ContentWorkspaceId = contentWSId;
            contentWSMember.ContentWorkspacePermissionId = contentWSPermissionId;
            contentWSMember.MemberId = userId;
            //contentWSMember.MemberType = 'U';
            INSERT contentWSMember;
            return contentWSMember;
        }else{
          return contentWSMemberexist[0];
        }
        
    }

    public static ContentDocumentLink createContentDocumentLink(Id contentDocId, String userId){
       
        List<Product2> prod = [Select Id,Name From Product2 where isActive = true LIMIT 1];
        List<ContentDocumentLink> doclink = new List<ContentDocumentLink>();
        doclink = [Select Id,ContentDocumentId from ContentDocumentLink where LinkedEntityId=:prod[0].Id and ContentDocumentId =:contentDocId limit 1];
        
        if(doclink.IsEmpty() && doclink.size()==0){
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocId;
            cdl.LinkedEntityId = prod[0].Id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;
             return cdl;
          }else{
            return doclink[0];
          }

       
    }

    @AuraEnabled
    public static void deleteLibraryUserAccess(String wsMemberId, String wsPermissionId, String contentDocLinkId) {
        ContentWorkspaceMember contentWSMember = new ContentWorkspaceMember(Id=wsMemberId);
        DELETE contentWSMember;
        
        /*ContentWorkspacePermission contentWSPermission = new ContentWorkspacePermission(Id=wsPermissionId);
        DELETE contentWSPermission;*/

        ContentDocumentLink contentDocLink = new ContentDocumentLink(Id=contentDocLinkId);
        DELETE contentDocLink;
    }

    @AuraEnabled(cacheable=true)
    public static String getBaseURL() {
        String baseURL = url.getsalesforcebaseurl().toexternalform();
        return baseURL;
    }
    
}