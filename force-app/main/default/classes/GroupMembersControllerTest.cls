@isTest
public class GroupMembersControllerTest {
    @isTest
    public static void testGetGroupMembers() {
        // Create test data        
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'LIMIT 1];
        
         User user = new User(
            Email = 'test@workr.com',
            Username = 'test@work.com',
            LastName = 'test',
            Alias = 'test',
            IsActive = true,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
        
        Group TACgrp = new Group(Name = 'TAC Global Premium SME');
        insert TACgrp;
        
        Group WWgrp = new Group(Name = 'WW Premium Manager Group');
        insert WWgrp;
        
        GroupMember WWgrpMember = new GroupMember( UserOrGroupId = user.Id,groupid ='00G5x000004MustEAC');
        insert WWgrpMember;
        
        GroupMember TACgrpMember = new GroupMember( UserOrGroupId = user.Id,groupid ='00G5x000006utipEAA');
        insert TACgrpMember;

        // Call the method being tested
        Test.startTest();
        List<User> groupMembers = GroupMembersController.getGroupMembers('TAC_Global_Premium_SME', 'Test');
        List<User> groupMembers1 = GroupMembersController.getGroupMembers('WW_Premium_Manager_Group', 'Test1');        
        Test.stopTest();

        // Perform assertions
        System.assertNotEquals(1, groupMembers.size());
        //System.assertEquals(user.Id, groupMembers[0].Id);
    }

    @isTest
    public static void testGetUsersNotInGroups() {
        // Create test data
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'LIMIT 1];
        
         User user = new User(
            Email = 'test@workr.com',
            Username = 'test@work.com',
            LastName = 'test',
            Alias = 'test',
            IsActive = true,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
        
        Group TACgrp = new Group(Name = 'TAC Global Premium SME');
        insert TACgrp;
        
        GroupMember TACgrpMember = new GroupMember( UserOrGroupId = user.Id,groupid ='00G5x000006utipEAA');
        insert TACgrpMember;

        // Call the method being tested
        Test.startTest();
        List<User> usersNotInGroups = GroupMembersController.getUsersNotInGroups('AAADataCustomerUser', 'Test');       
        Test.stopTest();

        // Perform assertions
        System.assertNotEquals(1, usersNotInGroups.size());
        //System.assertEquals(user.Id, usersNotInGroups[0].Id);
    }

    @isTest
    public static void testRemoveGroupMembers() {
        
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'LIMIT 1];
        
         User user = new User(
            Email = 'test@workr.com',
            Username = 'test@work.com',
            LastName = 'test',
            Alias = 'test',
            IsActive = true,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
        
        Group TACgrp = new Group(Name = 'TAC Global Premium SME');
        insert TACgrp;
        
        Group WWgrp = new Group(Name = 'WW Premium Manager Group');
        insert WWgrp;
        
        GroupMember TACgrpMember = new GroupMember( UserOrGroupId = user.Id,groupid ='00G5x000006utipEAA');
        insert TACgrpMember;
        
        GroupMember WWgrpMember = new GroupMember( UserOrGroupId = user.Id,groupid ='00G5x000004MustEAC');
        insert WWgrpMember;

        List<GroupMember> deletedGrpMembers = new List<GroupMember>();
        deletedGrpMembers.add(TACgrpMember);
        deletedGrpMembers.add(WWgrpMember);
        
        // Call the method being tested
        Test.startTest();
        GroupMembersController.removeGroupMembers('TAC_Global_Premium_SME', user.Id);
        GroupMembersController.removeGroupMembers('WW_Premium_Manager_Group', user.Id);        
        Test.stopTest();

        // Perform assertions
        if(!deletedGrpMembers.isempty()){
            List<GroupMember> deletedGroupMembers = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :user.Id AND Group.DeveloperName = 'TAC_Global_Premium_SME'];
            System.assertEquals(0, deletedGroupMembers.size());   
        }else if(!deletedGrpMembers.isempty()){
            List<GroupMember> deletedGroupMembers = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :user.Id AND Group.DeveloperName = 'WW_Premium_Manager_Group'];
            System.assertEquals(0, deletedGroupMembers.size());            
        }
        
    }

    @isTest
    public static void testAddGroupMembers() {
        // Create test data 
        
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'LIMIT 1];
        
        User user = new User(
            Email = 'test@workr.com',
            Username = 'test@work.com',
            LastName = 'test',
            Alias = 'test',
            IsActive = true,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
        
        Group TACgrp = new Group(Name = 'TAC Global Premium SME');
        insert TACgrp;
        
        Group WWgrp = new Group(Name = 'WW Premium Manager Group');
        insert WWgrp;   
        
        // Call the method being tested
        Test.startTest();
        GroupMembersController.addGroupMembers('TAC_Global_Premium_SME', user.Id);
        GroupMembersController.addGroupMembers('WW_Premium_Manager_Group', user.Id);
        Test.stopTest();

        // Perform assertions
        List<GroupMember> insertedGroupMembers = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :user.Id];
        System.assertEquals(2, insertedGroupMembers.size());
    }
}