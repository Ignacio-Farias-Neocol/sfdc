/*Author : Aditya Prasaad Padhy
 Date: 05/13/2022
 Description: Assign PermissionSet to Community Users
 */

public with sharing class AssignPermissionSetForCommunityUsers {

	public static String ORG_NAME = UserInfo.getUserName().substringAfterLast('.');
    
    public static void prepareUserIdPermissionSetMap(List<User> userList){
        System.debug('inside prepareUserIdPermissionSetMap...'+userList);
        List<Id> contIds = new List<Id>();
        for(User usr : userList){
            contIds.add(usr.ContactId);
        }
        
        Map<Id,Contact> mapofContact = new Map<Id,Contact>([SELECT Id, AccountId, Account.Type, Community_User__c,Community_User__r.Profile.Name FROM Contact WHERE Id in :contIds]);
        System.debug('mapofContact...'+mapofContact);
        if(mapofContact != null && !mapofContact.isEmpty()){        
            Map<Id,String> userIdPermissionSetMap = new Map<Id,String>();
            for(User usr : userList){
                if(mapofContact.get(usr.ContactId).Id == usr.ContactId){
                    if(mapofContact.get(usr.ContactId).Account.Type == Label.g_Account_Type_Distributor_Core || mapofContact.get(usr.ContactId).Account.Type == Label.g_Account_Type_Partner_Reseller){
                        userIdPermissionSetMap.put(usr.Id,Label.g_Account_Type_Partner);
                    }
                    else if(mapofContact.get(usr.ContactId).Account.Type == Label.g_Account_Type_Customer){
                        userIdPermissionSetMap.put(usr.Id,Label.g_Account_Type_Customer);
                    }
                }
            }
            assignPermissionSet(userIdPermissionSetMap);
        }
    }
    
    public static void assignPermissionSet(Map<Id,String> userIdPermissionSetMap){
        try{
            List<PermissionSet> psList = [SELECT Id, Name FROM PermissionSet WHERE Name IN (:Label.g_Barracuda_CPQ_Community_User,:Label.g_Salesforce_CPQ_Partner_User_Access,:Label.g_Salesforce_CPQ_Customer_User_Access,:Label.g_Steel_Brick_CPQ_Customer_User,:Label.g_Steel_Brick_CPQ_Partner_User)];        
            List<PermissionSetLicense> psl = [SELECT Id, MasterLabel FROM PermissionSetLicense WHERE MasterLabel = 'Salesforce CPQ License' LIMIT 1];
            List<PermissionSetAssignment> permissionSetAssignList = new List<PermissionSetAssignment>(); 
            List<PermissionSetLicenseAssign> permissionSetLicenseList = new List<PermissionSetLicenseAssign>(); 
            for(Id userId : userIdPermissionSetMap.keySet()){
                for(PermissionSet ps : psList ){
                    if(userIdPermissionSetMap.get(userId) == Label.g_Account_Type_Partner && (ps.Name == Label.g_Barracuda_CPQ_Community_User || ps.Name == Label.g_Salesforce_CPQ_Partner_User_Access || ps.Name == Label.g_Steel_Brick_CPQ_Partner_User )){
                        PermissionSetAssignment pma = new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = userId);
                        permissionSetAssignList.add(pma);
                    }else if(userIdPermissionSetMap.get(userId) == Label.g_Account_Type_Customer && (ps.Name == Label.g_Barracuda_CPQ_Community_User || ps.Name == Label.g_Salesforce_CPQ_Customer_User_Access || ps.Name == Label.g_Steel_Brick_CPQ_Customer_User )){
                        PermissionSetAssignment pma = new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = userId);
                        permissionSetAssignList.add(pma);
                    }
                    
                }
                if(psl!=null && psl.size()>0){
                    PermissionSetLicenseAssign pmla = new PermissionSetLicenseAssign(PermissionSetLicenseId = psl[0].Id, AssigneeId = userId);
                    permissionSetLicenseList.add(pmla);
                    System.debug('permissionSetLicenseList...'+permissionSetLicenseList);
                }
                
            }

            if(permissionSetLicenseList!=null && permissionSetLicenseList.size()>0){
                INSERT permissionSetLicenseList;
            }

            System.debug('permissionSetAssignList...'+permissionSetAssignList);
            if(permissionSetAssignList!=null && permissionSetAssignList.size()>0){
                INSERT permissionSetAssignList;
            }
            
            
        }
        catch(Exception e){
            System.debug('Exception while assigning permission set to User'+e.getMessage());            
			processRecords(e.getStackTraceString());
        }
    }
    
    @future
    public static void processRecords(String stackString){
        LogModel.singleLog('AssignPermissionSetForCommunityUsers', 'Exception on assigning permission set to User' + stackString, LogModel.LOG_CATEGORY_APEX);
    }
}