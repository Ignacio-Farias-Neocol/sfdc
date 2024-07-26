@isTest
public class WorkrampAssignmentTriggerTest {
    @isTest static void testInsertRegistrationWithMatch(){
        // Starting the test context
        Test.startTest();
        
        // Creating test data
        Profile profile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'System Administrator'
                             LIMIT 1];
        
        User user = new User(
            Email = 'user1@workramp.com',
            Username = 'user1@workramp.com',
            LastName = 'Er',
            Alias = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
                
        WorkRamp_Assignment__c assignment = new WorkRamp_Assignment__c(
            Assignee__c = 'user1@workramp.com',
            WorkRampId__c = 'workamp_id_user1',
            PercentComplete__c = 100,
            AssignedDate__c = date.newinstance(2021, 2, 20),
            WorkRampTrainingType__c = 'guide',
            WorkRampTrainingId__c = 'guide1'
        );
        insert assignment;

        Test.stopTest();
        
        WorkRamp_Assignment__c updatedAssignment = [SELECT WorkRampApp_User__c, OwnerId 
                             FROM WorkRamp_Assignment__c
                             WHERE Id =: assignment.Id];
        
        System.assertEquals(user.Id, updatedAssignment.WorkRampApp_User__c);
    }
    
    @isTest static void testInsertWithoutMatch(){
        // Starting the test context
        Test.startTest();
        
        // Creating test data
        Profile profile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'System Administrator'
                             LIMIT 1];
        
        User user = new User(
            Email = 'user2@workramp.com',
            Username = 'user2@workramp.com',
            LastName = 'Er',
            Alias = 'user2',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
                
        WorkRamp_Assignment__c assignment = new WorkRamp_Assignment__c(
            Assignee__c = 'user1@workramp.com',
            WorkRampId__c = 'workamp_id_user1',
            PercentComplete__c = 100,
            AssignedDate__c = date.newinstance(2021, 2, 20),
            WorkRampTrainingType__c = 'guide',
            WorkRampTrainingId__c = 'guide1'
        );
        insert assignment;
        
        WorkRamp_Assignment__c updatedAssignment = [SELECT WorkRampApp_User__c 
                             FROM WorkRamp_Assignment__c
                             WHERE Id =: assignment.Id];
        
        System.assertEquals(updatedAssignment.WorkRampApp_User__c, null);
        
        Test.stopTest();
    }
    
    @isTest static void testUpdateWithMatch(){
        // Starting the test context
        Test.startTest();
        
        // Creating test data
        Profile profile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'System Administrator'
                             LIMIT 1];
        
        WorkRamp_Assignment__c assignment = new WorkRamp_Assignment__c(
            Assignee__c = 'user1@workramp.com',
            WorkRampId__c = 'workamp_id_user1',
            PercentComplete__c = 50,
            AssignedDate__c = date.newinstance(2021, 2, 20),
            WorkRampTrainingType__c = 'guide',
            WorkRampTrainingId__c = 'guide1'
        );
        insert assignment;
        
        User user = new User(
            Email = 'user1@workramp.com',
            Username = 'user1@workramp.com',
            LastName = 'Er',
            Alias = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
        
        WorkRamp_Assignment__c insertedAssignment = [SELECT WorkRampApp_User__c, OwnerId
                             FROM WorkRamp_Assignment__c
                             WHERE Id =: assignment.Id];
        
        // WorkRampApp_User__c field should not be updated yet
        System.assertEquals(insertedAssignment.WorkRampApp_User__c, null);
                
        WorkRamp_Assignment__c assignmentToUpdate = new WorkRamp_Assignment__c(
            Id = insertedAssignment.Id,
            PercentComplete__c = 100
        );
        update assignmentToUpdate;
        
        WorkRamp_Assignment__c updatedAssignment = [SELECT WorkRampApp_User__c, OwnerId 
                             FROM WorkRamp_Assignment__c
                             WHERE Id =: insertedAssignment.Id];
        
        System.assertEquals(updatedAssignment.WorkRampApp_User__c, user.Id);
        
        Test.stopTest();
    }
    
    @isTest static void testUpdateWithExistingMatch(){
        // Starting the test context
        Test.startTest();
        
        // Creating test data
        Profile profile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'System Administrator'
                             LIMIT 1];
        
        User user1 = new User(
            Email = 'user1@workramp.com',
            Username = 'user1@workramp.com',
            LastName = 'Er',
            Alias = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user1;
        
        WorkRamp_Assignment__c assignment = new WorkRamp_Assignment__c(
            Assignee__c = 'user1@workramp.com',
            WorkRampId__c = 'workamp_id_user1',
            PercentComplete__c = 50,
            AssignedDate__c = date.newinstance(2021, 2, 20),
            WorkRampTrainingType__c = 'guide',
            WorkRampTrainingId__c = 'guide1'
        );
        insert assignment;
        
        WorkRamp_Assignment__c insertedAssignment = [SELECT WorkRampApp_User__c, OwnerId 
                             FROM WorkRamp_Assignment__c
                             WHERE Id =: assignment.Id];
        
        System.assertEquals(insertedAssignment.WorkRampApp_User__c, user1.Id);
        
        User user2 = new User(
            Email = 'user2@workramp.com',
            Username = 'user2@workramp.com',
            LastName = 'Er',
            Alias = 'user2',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user2;
                
        // User experiences a change in email address
        WorkRamp_Assignment__c assignmentToUpdate = new WorkRamp_Assignment__c(
            Id = insertedAssignment.Id,
            Assignee__c = 'user2@workramp.com'
        );
        update assignmentToUpdate;
        
        WorkRamp_Assignment__c updatedAssignment = [SELECT WorkRampApp_User__c, OwnerId 
                             FROM WorkRamp_Assignment__c
                             WHERE Id =: insertedAssignment.Id];
        
        System.assertEquals(updatedAssignment.WorkRampApp_User__c, user2.Id);
        
        Test.stopTest();
    }
    
    // If a Workramp assignment record is associated with
    // a Salesforce User and the assignment record 
    // experiences a change
    // in Email address and there is no Salesforce User
    // associated with the new e-mail address, we will 
    // keep the assignment record's WorkRampApp_User__c field value
    // intact. The WorkRampApp_User__c field value will be set to null
    // if the associated User is deleted.
    @isTest static void testUpdateWithNoNewMatch(){
        // Starting the test context
        Test.startTest();
        
        // Creating test data
        Profile profile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'System Administrator'
                             LIMIT 1];
        
        User user1 = new User(
            Email = 'user1@workramp.com',
            Username = 'user1@workramp.com',
            LastName = 'Er',
            Alias = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user1;
        
        WorkRamp_Assignment__c assignment = new WorkRamp_Assignment__c(
            Assignee__c = 'user1@workramp.com',
            WorkRampId__c = 'workamp_id_user1',
            PercentComplete__c = 50,
            AssignedDate__c = date.newinstance(2021, 2, 20),
            WorkRampTrainingType__c = 'guide',
            WorkRampTrainingId__c = 'guide1'
        );
        insert assignment;
        
        WorkRamp_Assignment__c insertedAssignment = [SELECT WorkRampApp_User__c, OwnerId 
                             FROM WorkRamp_Assignment__c
                             WHERE Id =: assignment.Id];
        
        System.assertEquals(insertedAssignment.WorkRampApp_User__c, user1.Id);
                
        // User experiences a change in email address
        WorkRamp_Assignment__c assignmentToUpdate = new WorkRamp_Assignment__c(
            Id = insertedAssignment.Id,
            Assignee__c = 'user2@workramp.com'
        );
        update assignmentToUpdate;
        
        WorkRamp_Assignment__c updatedAssignment = [SELECT WorkRampApp_User__c, OwnerId 
                             FROM WorkRamp_Assignment__c
                             WHERE Id =: insertedAssignment.Id];
        
        System.assertEquals(updatedAssignment.WorkRampApp_User__c, user1.Id);
        
        Test.stopTest();
    }
    
    // We should be able to match a user even if
    // the email case in WorkRamp does not match
    // that in the SFDC User object
    @isTest static void testEmailCaseInsensitivity(){
        // Starting the test context
        Test.startTest();
        
        // Creating test data
        Profile profile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'System Administrator'
                             LIMIT 1];
        
        User user = new User(
            Email = 'user1@workramp.com',
            Username = 'user1@workramp.com',
            LastName = 'Er',
            Alias = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
                
        WorkRamp_Assignment__c assignment = new WorkRamp_Assignment__c(
            Assignee__c = 'USER1@workramp.com',
            WorkRampId__c = 'workamp_id_user1',
            PercentComplete__c = 100,
            AssignedDate__c = date.newinstance(2021, 2, 20),
            WorkRampTrainingType__c = 'guide',
            WorkRampTrainingId__c = 'guide1'
        );
        insert assignment;

        Test.stopTest();
        
        WorkRamp_Assignment__c updatedAssignment = [SELECT WorkRampApp_User__c, OwnerId
                             FROM WorkRamp_Assignment__c
                             WHERE Id =: assignment.Id];
        
        System.assertEquals(updatedAssignment.WorkRampApp_User__c, user.Id);
    }

    @isTest static void testUpdateWithPartialOwnerMatch(){
        // Starting the test context
        Test.startTest();
        
        // Creating test data
        // System Admin always has read access to WorkRamp_Assignment
        // object
        Profile sysAdminProfile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'System Administrator'
                             LIMIT 1];

        // minAccessProfile will not have read access to WorkRamp_Assignment
        Profile minAccessProfile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'Minimum Access - Salesforce'
                             LIMIT 1];
        
        WorkRamp_Assignment__c assignmentExpectOwner = new WorkRamp_Assignment__c(
            Assignee__c = 'user1@workramp.com',
            WorkRampId__c = 'workamp_id_user1',
            PercentComplete__c = 50,
            AssignedDate__c = date.newinstance(2021, 2, 20),
            WorkRampTrainingType__c = 'guide',
            WorkRampTrainingId__c = 'guide1'
        );
        insert assignmentExpectOwner;
        
        User sysAdminProfileUser = new User(
            Email = 'user1@workramp.com',
            Username = 'user1@workramp.com',
            LastName = 'Er',
            Alias = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = sysAdminProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert sysAdminProfileUser;

        WorkRamp_Assignment__c assignmentDefaultOwner = new WorkRamp_Assignment__c(
            Assignee__c = 'user2@workramp.com',
            WorkRampId__c = 'workamp_id_user2',
            PercentComplete__c = 50,
            AssignedDate__c = date.newinstance(2021, 2, 20),
            WorkRampTrainingType__c = 'guide',
            WorkRampTrainingId__c = 'guide1'
        );
        insert assignmentDefaultOwner;
        
        User minAccessProfileUser = new User(
            Email = 'user2@workramp.com',
            Username = 'user2@workramp.com',
            LastName = 'Er',
            Alias = 'user2',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = minAccessProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert minAccessProfileUser;
        
        WorkRamp_Assignment__c firstInsertedAssignment = [SELECT WorkRampApp_User__c, OwnerId
                             FROM WorkRamp_Assignment__c
                             WHERE Id =: assignmentExpectOwner.Id];
        Id defaultOwnerId = firstInsertedAssignment.OwnerId;

        List<Id> assignmentIds = new List<Id>{assignmentExpectOwner.Id, assignmentDefaultOwner.Id};
        List<WorkRamp_Assignment__c> assignmentsToUpdate = [SELECT Id, WorkRampApp_User__c, OwnerId
                             FROM WorkRamp_Assignment__c
                             WHERE Id IN :assignmentIds];
        
        for (WorkRamp_Assignment__c assignment : assignmentsToUpdate) {
            assignment.PercentComplete__c = 100;
        }
        
        update assignmentsToUpdate;
        
        List<WorkRamp_Assignment__c> updatedAssignments = [SELECT Id, WorkRampApp_User__c, OwnerId
                             FROM WorkRamp_Assignment__c
                             WHERE Id IN :assignmentIds];
        
        for (WorkRamp_Assignment__c assignment : updatedAssignments) {
            if (assignment.Id == assignmentExpectOwner.Id) {
                System.assertEquals(assignment.OwnerId, defaultOwnerId);
            } else {
                System.assertEquals(assignment.OwnerId, defaultOwnerId);
            }
        }
        
        Test.stopTest();
    }

    @isTest static void testInsertAssignmentWithValidOwnerMatch(){
        // Starting the test context
        Test.startTest();
        
        // Creating test data
        Profile profile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'System Administrator'
                             LIMIT 1];
        
        User user = new User(
            Email = 'user1@workramp.com',
            Username = 'user1@workramp.com',
            LastName = 'Er',
            Alias = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
                
        WorkRamp_Assignment__c assignment = new WorkRamp_Assignment__c(
            Assignee__c = 'user1@workramp.com',
            WorkRampId__c = 'workamp_id_user1',
            PercentComplete__c = 100,
            AssignedDate__c = date.newinstance(2021, 2, 20),
            WorkRampTrainingType__c = 'guide',
            WorkRampTrainingId__c = 'guide1'
        );
        insert assignment;
        
        WorkRamp_Assignment__c updatedAssignment = [SELECT WorkRampApp_User__c, OwnerId 
                             FROM WorkRamp_Assignment__c
                             WHERE Id =: assignment.Id];
        
        Id oauthUserId = UserInfo.getUserId();
        System.assertEquals(oauthUserId, updatedAssignment.OwnerId);
        
        Test.stopTest();
    }

    // When the associated User does not have a profile
    // that allows them to own the assignment record,
    // the system user executing the trigger will be the 
    // record owner
    @isTest static void testInsertAssignmentInvalidOwnerMatch(){
        // Starting the test context
        Test.startTest();
        
        // Creating test data
        Profile profile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'Minimum Access - Salesforce'
                             LIMIT 1];
        
        User user = new User(
            Email = 'user1@workramp.com',
            Username = 'user1@workramp.com',
            LastName = 'Er',
            Alias = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
                
        WorkRamp_Assignment__c assignment = new WorkRamp_Assignment__c(
            Assignee__c = 'user1@workramp.com',
            WorkRampId__c = 'workamp_id_user1',
            PercentComplete__c = 100,
            AssignedDate__c = date.newinstance(2021, 2, 20),
            WorkRampTrainingType__c = 'guide',
            WorkRampTrainingId__c = 'guide1'
        );
        insert assignment;

        Id oauthUserId = UserInfo.getUserId();
        
        WorkRamp_Assignment__c updatedAssignment = [SELECT WorkRampApp_User__c, OwnerId 
                             FROM WorkRamp_Assignment__c
                             WHERE Id =: assignment.Id];
        
        System.assertEquals(oauthUserId, updatedAssignment.OwnerId);
        
        Test.stopTest();
    }

    @isTest static void testNewAssignmentPermissionSetCreated(){
        // Starting the test context
        Test.startTest();
        
        // Creating test data
        Profile profile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'Minimum Access - Salesforce'
                             LIMIT 1];
        
        User user = new User(
            Email = 'user1@workramp.com',
            Username = 'user1@workramp.com',
            LastName = 'Er',
            Alias = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;

        String wrAssignmentPermSetName = 'WorkRamp_Assignments_Read_Only_Permissions';
		PermissionSet workRampReadOnlyAssignmentPermissionSet = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = :wrAssignmentPermSetName
            LIMIT 1
        ];
        system.debug('testNewAssignmentPermissionSetCreated(): PermSet: ' + workRampReadOnlyAssignmentPermissionSet);
        List<PermissionSetAssignment> permSetAssignments = [
            SELECT AssigneeId, Id, PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :user.Id
                AND PermissionSetId = :workRampReadOnlyAssignmentPermissionSet.Id
        ];

        System.assertEquals(true, permSetAssignments.isEmpty());
        Map<Id, List<Id>> assignmentIdsByUserId = new Map<Id, List<Id>>();
        List<Id> assignmentIds = new List<Id>();
        assignmentIdsByUserId.put(user.Id, assignmentIds);
        WRReadOnlyPermSetAssnJobHandler handler = new WRReadOnlyPermSetAssnJobHandler(assignmentIdsByUserId);
        handler.execute(null);
        
        Test.stopTest();

        permSetAssignments = [
            SELECT AssigneeId, Id, PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :user.Id
                AND PermissionSetId = :workRampReadOnlyAssignmentPermissionSet.Id
        ];
        
        System.assertEquals(false, permSetAssignments.isEmpty());
    }

    @isTest static void testExistingPermSetAssignmentNoChange(){
         // Starting the test context
        Test.startTest();
        
        // Creating test data
        Profile profile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'Minimum Access - Salesforce'
                             LIMIT 1];
        
        User user = new User(
            Email = 'user1@workramp.com',
            Username = 'user1@workramp.com',
            LastName = 'Er',
            Alias = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;

        String wrAssignmentPermSetName = 'WorkRamp_Assignments_Read_Only_Permissions';
		PermissionSet workRampReadOnlyAssignmentPermissionSet = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = :wrAssignmentPermSetName
            LIMIT 1
        ];
        system.debug('testNewAssignmentPermissionSetCreated(): PermSet: ' + workRampReadOnlyAssignmentPermissionSet);
        List<PermissionSetAssignment> permSetAssignments = [
            SELECT AssigneeId, Id, PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :user.Id
                AND PermissionSetId = :workRampReadOnlyAssignmentPermissionSet.Id
        ];

        System.assertEquals(true, permSetAssignments.isEmpty());

        // Create PermSetAssignment for User
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = user.Id,
            PermissionSetId = workRampReadOnlyAssignmentPermissionSet.Id
        );
        insert psa;

        // Attempt to insert new PermSetAssignment for User
        Map<Id, List<Id>> assignmentIdsByUserId = new Map<Id, List<Id>>();
        List<Id> assignmentIds = new List<Id>();
        assignmentIdsByUserId.put(user.Id, assignmentIds);
        WRReadOnlyPermSetAssnJobHandler handler = new WRReadOnlyPermSetAssnJobHandler(assignmentIdsByUserId);
        handler.execute(null);
        
        Test.stopTest();

        permSetAssignments = [
            SELECT AssigneeId, Id, PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :user.Id
                AND PermissionSetId = :workRampReadOnlyAssignmentPermissionSet.Id
        ];
        
        System.assertEquals(1, permSetAssignments.size());

        PermissionSetAssignment queriedPsa = permSetAssignments.get(0);

        // Ensure 2nd attempt to insert PSA for User fails
        System.assertEquals(psa.Id, queriedPsa.Id);
    }

    @isTest static void testNewOwnerTransferJobEnqueued(){
        // Starting the test context
        Test.startTest();
        
        // Creating test data
        Profile profile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'Minimum Access - Salesforce'
                             LIMIT 1];
        
        User user = new User(
            Email = 'user1@workramp.com',
            Username = 'user1@workramp.com',
            LastName = 'Er',
            Alias = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;

        String wrAssignmentPermSetName = 'WorkRamp_Assignments_Read_Only_Permissions';
		PermissionSet workRampReadOnlyAssignmentPermissionSet = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = :wrAssignmentPermSetName
            LIMIT 1
        ];
        system.debug('testNewAssignmentPermissionSetCreated(): PermSet: ' + workRampReadOnlyAssignmentPermissionSet);
        List<PermissionSetAssignment> permSetAssignments = [
            SELECT AssigneeId, Id, PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :user.Id
                AND PermissionSetId = :workRampReadOnlyAssignmentPermissionSet.Id
        ];

        System.assertEquals(true, permSetAssignments.isEmpty());

        // Create PermSetAssignment for User
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = user.Id,
            PermissionSetId = workRampReadOnlyAssignmentPermissionSet.Id
        );
        insert psa;

        Map<Id, List<Id>> assignmentIdsByUserId = new Map<Id, List<Id>>();
        List<Id> assignmentIds = new List<Id>();
        assignmentIdsByUserId.put(user.Id, assignmentIds);
        WRReadOnlyPermSetAssnJobHandler handler = new WRReadOnlyPermSetAssnJobHandler(assignmentIdsByUserId);

        permSetAssignments = [
            SELECT AssigneeId, Id, PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :user.Id
                AND PermissionSetId = :workRampReadOnlyAssignmentPermissionSet.Id
        ];
        
        System.assertEquals(false, permSetAssignments.isEmpty());

        PermissionSetAssignment newPsa = permSetAssignments.get(0);
        Id jobId = handler.createOwnershipTransferJob(new List<Id>{newPsa.Id});
        System.assertNotEquals(null, jobId);

        Test.stopTest();
    }

    @isTest static void testGetAssignmentsRequiringOwnerUpdate(){
        // Starting the test context
        Test.startTest();
        
        // Creating test data
        Profile profile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'Minimum Access - Salesforce'
                             LIMIT 1];
        
        User user = new User(
            Email = 'user1@workramp.com',
            Username = 'user1@workramp.com',
            LastName = 'Er',
            Alias = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;

        WorkRamp_Assignment__c assignment = new WorkRamp_Assignment__c(
            Assignee__c = 'user1@workramp.com',
            WorkRampId__c = 'workamp_id_user1',
            PercentComplete__c = 100,
            AssignedDate__c = date.newinstance(2021, 2, 20),
            WorkRampTrainingType__c = 'guide',
            WorkRampTrainingId__c = 'guide1'
        );
        insert assignment;

        Map<Id, List<Id>> assignmentIdsByUserId = new Map<Id, List<Id>>();
        List<Id> assignmentIds = new List<Id>{assignment.Id};
        assignmentIdsByUserId.put(user.Id, assignmentIds);
        WRAssnOwnerTransferJobHandler handler = new WRAssnOwnerTransferJobHandler(assignmentIdsByUserId);
        List<WorkRamp_Assignment__c> assignmentsRequiringUpdate = handler.getAssignmentsRequiringOwnerUpdate();
        
        System.assertEquals(1, assignmentsRequiringUpdate.size());

        WorkRamp_Assignment__c retrievedAssignment = assignmentsRequiringUpdate.get(0);
        System.assertEquals(assignment.Id, retrievedAssignment.Id);

        Test.stopTest();
    }

    @isTest static void testAssignmentOwnerUpdate(){
        // Starting the test context
        Test.startTest();
        
        // Creating test data
        Profile profile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'Minimum Access - Salesforce'
                             LIMIT 1];
        
        User user = new User(
            Email = 'user1@workramp.com',
            Username = 'user1@workramp.com',
            LastName = 'Er',
            Alias = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;

        WorkRamp_Assignment__c assignment = new WorkRamp_Assignment__c(
            Assignee__c = 'user1@workramp.com',
            WorkRampId__c = 'workamp_id_user1',
            PercentComplete__c = 100,
            AssignedDate__c = date.newinstance(2021, 2, 20),
            WorkRampTrainingType__c = 'guide',
            WorkRampTrainingId__c = 'guide1'
        );
        insert assignment;

        WorkRamp_Assignment__c reloadedAssignment = [
            SELECT Id, OwnerId
            FROM WorkRamp_Assignment__c
            WHERE Id = :assignment.Id
            LIMIT 1
        ];

        Id oauthUserId = UserInfo.getUserId();
        System.assertEquals(oauthUserId, reloadedAssignment.OwnerId);

        Test.stopTest();

        Map<Id, List<Id>> assignmentIdsByUserId = new Map<Id, List<Id>>();
        List<Id> assignmentIds = new List<Id>{reloadedAssignment.Id};
        assignmentIdsByUserId.put(user.Id, assignmentIds);

        WRAssnOwnerTransferJobHandler handler = new WRAssnOwnerTransferJobHandler(assignmentIdsByUserId);
        handler.transferOwnershipForAssignments(new List<WorkRamp_Assignment__c>{reloadedAssignment});
        reloadedAssignment = [
            SELECT Id, OwnerId
            FROM WorkRamp_Assignment__c
            WHERE Id = :assignment.Id
            LIMIT 1
        ];

        System.assertEquals(user.Id, reloadedAssignment.OwnerId);
    }

    @isTest static void testSameAssignmentOwnerNoUpdate(){
        // Starting the test context
        Test.startTest();

        Id oauthUserId = UserInfo.getUserId();
        User user = [
            SELECT Id, Email
            FROM User
            WHERE Id = :oauthUserId
            LIMIT 1
        ];

        WorkRamp_Assignment__c assignment = new WorkRamp_Assignment__c(
            Assignee__c = user.Email,
            WorkRampId__c = 'workamp_id_user1',
            PercentComplete__c = 100,
            AssignedDate__c = date.newinstance(2021, 2, 20),
            WorkRampTrainingType__c = 'guide',
            WorkRampTrainingId__c = 'guide1'
        );
        insert assignment;

        WorkRamp_Assignment__c reloadedAssignment = [
            SELECT Id, OwnerId
            FROM WorkRamp_Assignment__c
            WHERE Id = :assignment.Id
            LIMIT 1
        ];

        System.assertEquals(oauthUserId, reloadedAssignment.OwnerId);

        Test.stopTest();

        Map<Id, List<Id>> assignmentIdsByUserId = new Map<Id, List<Id>>();
        List<Id> assignmentIds = new List<Id>{reloadedAssignment.Id};
        assignmentIdsByUserId.put(user.Id, assignmentIds);

        WRAssnOwnerTransferJobHandler handler = new WRAssnOwnerTransferJobHandler(assignmentIdsByUserId);
        List<Id> assignmentIdsWithUpdatedOwnerId = handler.transferOwnershipForAssignments(new List<WorkRamp_Assignment__c>{reloadedAssignment});

        System.assertEquals(true, assignmentIdsWithUpdatedOwnerId.isEmpty());
    }

    @isTest static void testNewAssignmentPermissionSetCreatedIntegration(){
        // Starting the test context
        Test.startTest();
        
        // Creating test data
        Profile profile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'Minimum Access - Salesforce'
                             LIMIT 1];
        
        User user = new User(
            Email = 'user1@workramp.com',
            Username = 'user1@workramp.com',
            LastName = 'Er',
            Alias = 'user1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;

        String wrAssignmentPermSetName = 'WorkRamp_Assignments_Read_Only_Permissions';
		PermissionSet workRampReadOnlyAssignmentPermissionSet = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = :wrAssignmentPermSetName
            LIMIT 1
        ];
        List<PermissionSetAssignment> permSetAssignments = [
            SELECT AssigneeId, Id, PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :user.Id
                AND PermissionSetId = :workRampReadOnlyAssignmentPermissionSet.Id
        ];

        System.assertEquals(true, permSetAssignments.isEmpty());

        WorkRamp_Assignment__c assignment = new WorkRamp_Assignment__c(
            Assignee__c = 'user1@workramp.com',
            WorkRampId__c = 'workamp_id_user1',
            PercentComplete__c = 100,
            AssignedDate__c = date.newinstance(2021, 2, 20),
            WorkRampTrainingType__c = 'guide',
            WorkRampTrainingId__c = 'guide1'
        );
        insert assignment;
        
        Test.stopTest();

        permSetAssignments = [
            SELECT AssigneeId, Id, PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId = :user.Id
                AND PermissionSetId = :workRampReadOnlyAssignmentPermissionSet.Id
        ];
        
        System.assertEquals(false, permSetAssignments.isEmpty());
    }

    /**
        Ensure that logErrorMessage method
        writes log to WR Assignment Log
        custom object
     */
    @isTest static void testLogErrorMessage(){
        // Starting the test context
        Test.startTest();
        
        // Creating test data
        String permSetJobHandlerClassName = 'WRReadOnlyPermSetAssnJobHandler';
        String expectedLogLevel = 'Error';
        String errorMessage = 'Error: Could not find WorkRamp Read-Only Permission Set in Org. Unable to automate permission set assignment.';
        List<String> errorMessages = new List<String>{errorMessage};

        WorkrampAssignmentLogHandler logger = new WorkrampAssignmentLogHandler(permSetJobHandlerClassName);
        logger.logErrorMessages(errorMessages);
        
        List<WorkRamp_Assignment_Log__c> assnLogs = [
            SELECT Message__c, Log_Level__c, Apex_Class__c
            FROM WorkRamp_Assignment_Log__c
            WHERE Apex_Class__c = :permSetJobHandlerClassName
        ];

        Boolean errorLogCreated = false;
        for (WorkRamp_Assignment_Log__c log : assnLogs) {
            Boolean messagesMatch = log.Message__c == errorMessage;
            Boolean levelsMatch = log.Log_Level__c == expectedLogLevel;

            if (messagesMatch && levelsMatch) {
                errorLogCreated = true;
            }
        }

        System.assertEquals(true, errorLogCreated);

        Test.stopTest();
    }

    /**
        Ensure that LogSaveResultErrorMessages method
        writes logs to WR Assignment Log
        custom object

        NOTE: This is a pretty weak test as it relies
        on Salesforce to continue to not allow 
        Chatter External Users to own records...
        Without a great way to mock Database.SaveResult,
        this is likely the best we can do for now.
     */
    @isTest static void testLogSaveResultErrorMessages(){
        // Starting the test context
        Test.startTest();
        String handlerClassName = 'WorkrampAssignmentTriggerTest';

        List<WorkRamp_Assignment_Log__c> assnLogs = [
            SELECT Message__c, Log_Level__c, Apex_Class__c
            FROM WorkRamp_Assignment_Log__c
            WHERE Apex_Class__c = :handlerClassName
        ];

        System.assertEquals(true, assnLogs.isEmpty());
        
        // Creating test data
        Profile profile = [SELECT Id 
                             FROM Profile
                             WHERE Name = 'Chatter External User'
                             LIMIT 1];
        
        User user = new User(
            Email = 'chatterexternaluser@workramp.com',
            Username = 'chatterexternaluser@workramp.com',
            LastName = 'Er',
            Alias = 'chaeu',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;

        WorkRamp_Assignment__c assignment = new WorkRamp_Assignment__c(
            Assignee__c = 'chatterexternaluser@workramp.com',
            WorkRampId__c = 'workamp_id_userchatter',
            PercentComplete__c = 100,
            AssignedDate__c = date.newinstance(2021, 2, 20),
            WorkRampTrainingType__c = 'guide',
            WorkRampTrainingId__c = 'guide1',
            OwnerId = user.Id
        );
        List<WorkRamp_Assignment__c> assnList = new List<WorkRamp_Assignment__c>{assignment};

        // Insert should fail as Chatter external user cannot own records
        Database.SaveResult[] srList = Database.insert(assnList, false);

        WorkrampAssignmentLogHandler logger = new WorkrampAssignmentLogHandler(handlerClassName);
        logger.logSaveResultErrorMessages(srList);

        assnLogs = [
            SELECT Message__c, Log_Level__c, Apex_Class__c
            FROM WorkRamp_Assignment_Log__c
            WHERE Apex_Class__c = :handlerClassName AND Log_Level__c = 'Error'
        ];

        System.assertEquals(false, assnLogs.isEmpty());

        Test.stopTest();
    }
}