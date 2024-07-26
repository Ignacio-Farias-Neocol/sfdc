public class WorkrampAssignmentUserHandler {
    public static void setUserFieldsAfterInsert(List<WorkRamp_Assignment__c> assignments){
        bulkUpdateUserIds(assignments);
        bulkUpdateOwnerIds(assignments);
    }
    
    public static void setUserFieldsAfterUpdate(List<WorkRamp_Assignment__c> assignments){
        bulkUpdateUserIds(assignments);
        bulkUpdateOwnerIds(assignments);
    }
    
    private static void bulkUpdateOwnerIds(List<WorkRamp_Assignment__c> assignments){
        WorkrampAssignmentLogHandler logger = new WorkrampAssignmentLogHandler('WorkrampAssignmentUserHandler');
        Map<String, Id> userIdsByEmail = getUserIdsByEmailFromAssignments(assignments);

        Set<Id> userIdsRequiringPermSetAssignment = getUserIdsRequiringReadOnlyPermissionSet(userIdsByEmail.values());

        List<WorkRamp_Assignment__c> assignmentsToUpdate = new List<WorkRamp_Assignment__c>();
        Id assignmentUserId;
        Map<Id, List<Id>> assnIdsRequiringPermSetAssnByUserId = new Map<Id, List<Id>>();
        for (WorkRamp_Assignment__c workrampAssignment : assignments) {
            assignmentUserId = userIdsByEmail.get(workrampAssignment.Assignee__c);
            if (assignmentUserId == null) {
                continue;
            }
            
            Boolean assignmentOwnerIdShouldChange = assignmentUserId != workrampAssignment.OwnerId;
            if (assignmentOwnerIdShouldChange && userIdsRequiringPermSetAssignment.contains(assignmentUserId)) {
                addAssnIdToIdsRequiringPermSetAssignment(
                    workrampAssignment.Id,
                    assignmentUserId,
                    assnIdsRequiringPermSetAssnByUserId
                );
                continue;
            }

            if (assignmentOwnerIdShouldChange) {
                assignmentsToUpdate.add(
                    new WorkRamp_Assignment__c(
                            Id = workrampAssignment.Id,
                            OwnerId = assignmentUserId
                        )
                );
            }  
        }
    
        Database.SaveResult[] srList = Database.update(assignmentsToUpdate, false);
        logger.logSaveResultErrorMessages(srList);

        if (!assnIdsRequiringPermSetAssnByUserId.isEmpty()) {
            createPermissionAssignmentJob(assnIdsRequiringPermSetAssnByUserId);
        }
    }

    /**
        Adds the WR Assignment ID to the referenced Map by making an in place
        update
     */
    private static void addAssnIdToIdsRequiringPermSetAssignment(
        Id wrAssnId,
        Id userId,
        Map<Id, List<Id>> assnIdsRequiringPermSetAssnByUserId
    ) {
            List<Id> existingAssnIds = assnIdsRequiringPermSetAssnByUserId.get(userId);
            if (existingAssnIds == null) {
                assnIdsRequiringPermSetAssnByUserId.put(userId, new List<Id>{wrAssnId});
            } else {
                existingAssnIds.add(wrAssnId);
                assnIdsRequiringPermSetAssnByUserId.put(userId, existingAssnIds);
            }
    }

    private static void createPermissionAssignmentJob(
        Map<Id, List<Id>> assnIdsRequiringPermSetAssnByUserId
    ){
        WRReadOnlyPermSetAssnJobHandler handler = new WRReadOnlyPermSetAssnJobHandler(
            assnIdsRequiringPermSetAssnByUserId
        );
        System.enqueueJob(handler);
    }

    /**
        Returns the set of IDs of Users who have not been assigned
        either the Admin Permission set or the Read-Only permission set
     */
    private static Set<Id> getUserIdsRequiringReadOnlyPermissionSet(List<Id> userIds){
        WorkrampAssignmentLogHandler logger = new WorkrampAssignmentLogHandler('WorkrampAssignmentUserHandler');
        Set<Id> userIdsRequiringReadOnlyPermSet = new Set<Id>();

        String wrAssignmentPermSetName = 'WorkRamp_Assignments_Read_Only_Permissions';
        List<String> workRampAssignmentPermissionSetNames = new List<String>{
            'WorkRamp_Permissions',
            wrAssignmentPermSetName
        };

        List<PermissionSet> workRampAssignmentPermissionSets = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name IN :workRampAssignmentPermissionSetNames
        ];

        Id readOnlyPermSetId = null;
        for(PermissionSet permSet : workRampAssignmentPermissionSets) {
            if (permSet.Name == wrAssignmentPermSetName) {
                readOnlyPermSetId = permSet.Id;
            }
        }

        if (readOnlyPermSetId == null) {
            logger.logErrorMessages(
                new List<String>{'Error: Could not find WorkRamp Read-Only Permission Set in Org. Unable to automate permission set assignment.'}
            );
            return userIdsRequiringReadOnlyPermSet;
        }

        Map<Id, List<PermissionSetAssignment>> workRampPermissionSetAssnsByUserId = groupPermissionSetAssignmentsByUserId(
            workRampAssignmentPermissionSets,
            userIds
        );

        for(Id userId : userIds) {
            List<PermissionSetAssignment> existingAssns = workRampPermissionSetAssnsByUserId.get(userId);
            if (existingAssns == null) {
                userIdsRequiringReadOnlyPermSet.add(userId);
            }
        }

        return userIdsRequiringReadOnlyPermSet;
    }

    private static Map<Id, List<PermissionSetAssignment>> groupPermissionSetAssignmentsByUserId(
        List<PermissionSet> permissionSets,
        List<Id> userIds
    ){
        Map<Id, List<PermissionSetAssignment>> assnsByUserId = new Map<Id, List<PermissionSetAssignment>>();
        List<Id> permSetIds = new List<Id>();
        for(PermissionSet permSet : permissionSets) {
            permSetIds.add(permSet.Id);
        }

        List<PermissionSetAssignment> permSetAssignments = [
            SELECT AssigneeId, Id, PermissionSetId
            FROM PermissionSetAssignment
            WHERE AssigneeId IN :userIds
                AND PermissionSetId IN :permSetIds
        ];

        for(PermissionSetAssignment permSetAssn : permSetAssignments) {
            Id assigneeId = permSetAssn.AssigneeId;
            List<PermissionSetAssignment> userPermAssns = assnsByUserId.get(assigneeId);
            if (userPermAssns == null) {
                assnsByUserId.put(assigneeId, new List<PermissionSetAssignment>{permSetAssn});
                continue;
            }

            userPermAssns.add(permSetAssn);
            assnsByUserId.put(assigneeId, userPermAssns);
        }

        return assnsByUserId;
    }
    
    private static void bulkUpdateUserIds(List<WorkRamp_Assignment__c> assignments){
        WorkrampAssignmentLogHandler logger = new WorkrampAssignmentLogHandler('WorkrampAssignmentUserHandler');
        Map<String, Id> userIdsByEmail = getUserIdsByEmailFromAssignments(assignments);
        
        List<WorkRamp_Assignment__c> assignmentsToUpdate = new List<WorkRamp_Assignment__c>();
        for (WorkRamp_Assignment__c workrampAssignment : assignments) {
            if (userIdsByEmail.get(workrampAssignment.Assignee__c) == null) {
                continue;
            }
            
            Boolean assignmentUserIdChanged = userIdsByEmail.get(workrampAssignment.Assignee__c) != workrampAssignment.WorkRampApp_User__c;
            if (assignmentUserIdChanged) {
                assignmentsToUpdate.add(
                    new WorkRamp_Assignment__c(
                            Id = workrampAssignment.Id,
                            WorkRampApp_User__c = userIdsByEmail.get(workrampAssignment.Assignee__c)
                        )
                );
            }  
        }
    
        try {
            update assignmentsToUpdate;
        } catch (DmlException e) {
            logger.logErrorMessages(
                new List<String>{'Error bulk updating User ID for assignments: ' + e.getMessage()}
            );
        }
    }
    
    private static Map<String, Id> getUserIdsByEmailFromAssignments(List<WorkRamp_Assignment__c> assignments){
        Set<String> assignmentRecordEmails = new Set<String>();
        for (WorkRamp_Assignment__c workrampAssignment : assignments) {
            assignmentRecordEmails.add(workrampAssignment.Assignee__c);
        }
    
        List<User> users = [SELECT Id, Email
                            FROM User
                            WHERE Email IN :assignmentRecordEmails];
                            
        Map<String, Id> userIdsByEmail = new Map<String, Id>();                   
        for (User user : users) {
            userIdsByEmail.put(user.Email, user.Id);
        }
        
        return userIdsByEmail;
    }
}