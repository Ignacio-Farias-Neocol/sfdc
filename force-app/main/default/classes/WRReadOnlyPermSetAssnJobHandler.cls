public class WRReadOnlyPermSetAssnJobHandler implements Queueable {
        Map<Id, List<Id>> assignmentIdsByUserId;
        WorkrampAssignmentLogHandler logger;
        List<Database.SaveResult> failedSaveResults;

        public WRReadOnlyPermSetAssnJobHandler(Map<Id, List<Id>> assignmentIdsByUserId) {
                this.assignmentIdsByUserId = assignmentIdsByUserId;
                this.logger = new WorkrampAssignmentLogHandler('WRReadOnlyPermSetAssnJobHandler');
                this.failedSaveResults = new List<Database.SaveResult>();
        }

        public void execute(QueueableContext context) {
                PermissionSet workRampReadOnlyAssignmentPermissionSet = getWorkRampAssignmentPermissionSet();
                if (workRampReadOnlyAssignmentPermissionSet == null) {
            logger.logErrorMessages(
                new List<String>{'WRReadOnlyPermSetAssnJobHandler(): Error: Could not find WorkRamp Read-Only Permission Set in Org. Unable to automate permission set assignment.'}
            );
            return;
        }

                List<Id> createdPermSetAssnIds = createPermissionSetAssignmentsForUsers(workRampReadOnlyAssignmentPermissionSet);

                // See "Chaining Jobs" section here: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm
                if (!Test.isRunningTest()) {
                        createOwnershipTransferJob(createdPermSetAssnIds);
                }
        }

        /**
            Create job to transfer ownership of WRAssignment records for all Users
            who had a PermissionSetAssignment created in this job.
         */
        @TestVisible private Id createOwnershipTransferJob(List<Id> createdPermSetAssnIds) {
                Map<Id, List<Id>> assignmentIdsToTransferOwnerByUserId = getWrAssnIdsToTransferOwnerByUserId(createdPermSetAssnIds);
        WRAssnOwnerTransferJobHandler handler = new WRAssnOwnerTransferJobHandler(
            assignmentIdsToTransferOwnerByUserId,
                        failedSaveResults
        );

        return System.enqueueJob(handler);
    }

        @TestVisible private Map<Id, List<Id>> getWrAssnIdsToTransferOwnerByUserId(List<Id> createdPermSetAssnIds) {
            Map<Id, List<Id>> wrAssnIdsByUserId = new Map<Id, List<Id>>();
            List<PermissionSetAssignment> createdPsas = [
                    SELECT AssigneeId
                    FROM PermissionSetAssignment
                    WHERE Id IN :createdPermSetAssnIds
            ];
            for (PermissionSetAssignment psa : createdPsas) {
                List<Id> wrAssignmentIds = assignmentIdsByUserId.get(psa.AssigneeId);
                wrAssnIdsByUserId.put(psa.AssigneeId, wrAssignmentIds);
            }

            return wrAssnIdsByUserId;
        }

        /**
            Attempts to create PermissionSetAssignments to the WR Read Only Permission Set
            for all Users who still do not have the permission set.

            Returns a List of all the PermissionSetAssignment IDs that were created.
         */
        private List<Id> createPermissionSetAssignmentsForUsers(PermissionSet wrReadOnlyPermSet) {
                List<PermissionSetAssignment> newPermissionSetAssns = new List<PermissionSetAssignment>();
                Set<Id> userIdsWithPermSetAssn = getUserIdsWithPermSetAssn(wrReadOnlyPermSet);
                
                for (Id userId : assignmentIdsByUserId.keyset()) {
                        if (userIdsWithPermSetAssn.contains(userId)) {
                                continue;
                        }

                        newPermissionSetAssns.add(
                                new PermissionSetAssignment(
                                        PermissionSetId = wrReadOnlyPermSet.Id,
                                        AssigneeId = userId
                                )
                        );
                }

                Database.SaveResult[] srList = Database.insert(newPermissionSetAssns, false);

                List<Id> insertedPsaIds = new List<Id>();
                for (Database.SaveResult sr : srList) {
                        if (sr.isSuccess()) {
                            insertedPsaIds.add(sr.getId());
                        } else {
                            failedSaveResults.add(sr);
                        }
                }

                return insertedPsaIds;
        }

        private Set<Id> getUserIdsWithPermSetAssn(PermissionSet wrReadOnlyPermSet) {
            Set<Id> userIdSet = new Set<Id>();
            List<PermissionSetAssignment> psas = [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSetId = :wrReadOnlyPermSet.Id
                                AND AssigneeId = :assignmentIdsByUserId.keyset()
        ];

            for (PermissionSetAssignment psa : psas) {
                userIdSet.add(psa.AssigneeId);
            }

            return userIdSet;
        }

        public static PermissionSet getWorkRampAssignmentPermissionSet(){
                String wrAssignmentPermSetName = 'WorkRamp_Assignments_Read_Only_Permissions';
                PermissionSet workRampReadOnlyAssignmentPermissionSet = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name = :wrAssignmentPermSetName
                        LIMIT 1
        ];

                return workRampReadOnlyAssignmentPermissionSet;
        }
}