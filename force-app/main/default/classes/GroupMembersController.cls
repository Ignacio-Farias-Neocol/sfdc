public without sharing class GroupMembersController {
    
    @AuraEnabled
    public static List<User> getGroupMembers(String groupDeveloperName, String searchTerm) {
        List<string> profileTobeInclude=new List<String>{
            'Apollo: Custom- Support Profile - Omni Channel',
			'Apollo: Custom- Support Profile' };
        List<Profile> profileList=new List<Profile>([select Id From Profile WHERE Name IN :profileTobeInclude]);
        List<User> groupMembers = new List<User>();
        if (groupDeveloperName == 'TAC_Global_Premium_SME') {
            groupMembers = [SELECT Id, Name,IsActive FROM User WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'TAC_Global_Premium_SME') AND Name LIKE :('%' + searchTerm + '%') and Profile.userType='Standard' and IsActive = true and profileId IN:profileList];
        } else if (groupDeveloperName == 'WW_Premium_Manager_Group') {
            groupMembers = [SELECT Id, Name,IsActive FROM User WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'WW_Premium_Manager_Group')AND Name LIKE :('%' + searchTerm + '%')  and Profile.userType='Standard' and IsActive = true  and profileId IN:profileList];
        }
        return groupMembers;
    }
    
    @AuraEnabled
    public static List<User> getUsersNotInGroups(String groupDeveloperName, String searchTerm) {
        List<string> profileTobeInclude=new List<String>{
            'Apollo: Custom- Support Profile - Omni Channel',
			'Apollo: Custom- Support Profile' };
        List<Profile> profileList=new List<Profile>([select Id From Profile WHERE Name IN :profileTobeInclude]);
        List<User> usersNotInGroups = new List<User>();
        usersNotInGroups = [SELECT Id, Name FROM User WHERE Id NOT IN 
                            (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName IN ('TAC_Global_Premium_SME', 'WW_Premium_Manager_Group')) and Profile.UserType = 'Standard' and IsActive = true  and profileId IN:profileList];
        if (searchTerm != null && searchTerm != '') {
            usersNotInGroups = [SELECT Id, Name FROM User WHERE Name LIKE :('%' + searchTerm + '%') AND Id NOT IN 
                                (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName =:groupDeveloperName)  and Profile.UserType = 'Standard' and IsActive = true  and profileId IN:profileList];
        }
        return usersNotInGroups;
    }
    
    @AuraEnabled
    public static void removeGroupMembers(String groupDeveloperName, Id userIds) {
        List<GroupMember> groupMembersToDelete = new List<GroupMember>();
        if (groupDeveloperName == 'TAC_Global_Premium_SME') {
            groupMembersToDelete = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :userIds AND Group.DeveloperName = :groupDeveloperName];
        } else if (groupDeveloperName == 'WW_Premium_Manager_Group') {
            groupMembersToDelete = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :userIds AND Group.DeveloperName = :groupDeveloperName];
        }
        if (!groupMembersToDelete.isEmpty()) {
            delete groupMembersToDelete;
        }
    }
    @AuraEnabled
    public static void addGroupMembers(String groupDeveloperName, Id userIds) {
        List<GroupMember> groupMembersToadd = new List<GroupMember>();
        
        if (groupDeveloperName == 'TAC_Global_Premium_SME') {
            GroupMember groupMember = new GroupMember();
            groupMember.GroupId = '00G5x000006utipEAA';
            groupMember.UserOrGroupId = userIds;
            groupMembersToadd.add(groupMember);     
            system.debug(userIds);
        } else if (groupDeveloperName == 'WW_Premium_Manager_Group') {
            GroupMember groupMember = new GroupMember();
            groupMember.GroupId = '00G5x000004MustEAC';
            groupMember.UserOrGroupId = userIds;
            groupMembersToadd.add(groupMember);
            system.debug(userIds);
        }
        if (!groupMembersToadd.isEmpty()) { 
            insert groupMembersToadd;
        }
    }
}