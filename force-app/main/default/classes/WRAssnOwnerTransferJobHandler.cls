public class WRAssnOwnerTransferJobHandler implements Queueable {
        Map<Id, List<Id>> assignmentIdsByUserId;
    WorkrampAssignmentLogHandler logger;
    List<Database.SaveResult> failedSaveResults;

        public WRAssnOwnerTransferJobHandler(
      Map<Id, List<Id>> assignmentIdsByUserId,
      List<Database.SaveResult> previouslyFailedSaveResults
    ) {
                this.assignmentIdsByUserId = assignmentIdsByUserId;
        this.logger = new WorkrampAssignmentLogHandler('WRAssnOwnerTransferJobHandler');
        this.failedSaveResults = new List<Database.SaveResult>(previouslyFailedSaveResults);
        }

    public WRAssnOwnerTransferJobHandler(Map<Id, List<Id>> assignmentIdsByUserId) {
                this.assignmentIdsByUserId = assignmentIdsByUserId;
        this.logger = new WorkrampAssignmentLogHandler('WRAssnOwnerTransferJobHandler');
        this.failedSaveResults = new List<Database.SaveResult>();
        }

    public void execute(QueueableContext context) {
        List<WorkRamp_Assignment__c> assignmentsToUpdate = getAssignmentsRequiringOwnerUpdate();

        transferOwnershipForAssignments(assignmentsToUpdate);

        logger.logSaveResultErrorMessages(failedSaveResults);
    }

    @TestVisible
    private List<Id> transferOwnershipForAssignments(List<WorkRamp_Assignment__c> assignments) {
        List<WorkRamp_Assignment__c> assignmentsToUpdate = new List<WorkRamp_Assignment__c>();
        Map<Id, Id> userIdsByAssignmentId = getUserIdsByAssignmentId();
        for (WorkRamp_Assignment__c assn : assignments) {
            Id proposedOwnerId = userIdsByAssignmentId.get(assn.Id);
            if (proposedOwnerId == assn.OwnerId) {
              continue;
            }

            assignmentsToUpdate.add(
              new WorkRamp_Assignment__c(
                Id = assn.Id,
                OwnerId = proposedOwnerId
              )
            );
        }

        Database.SaveResult[] srList = Database.update(assignmentsToUpdate, false);

        List<Id> updatedWRAssnIds = new List<Id>();
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                            updatedWRAssnIds.add(sr.getId());
                        } else {
                            failedSaveResults.add(sr);
                        }
        }

        return updatedWRAssnIds;
    }

    private Map<Id, Id> getUserIdsByAssignmentId() {
        Map<Id, Id> userIdsByAssignmentId = new Map<Id, Id>();
        for (Id userId : assignmentIdsByUserId.keyset()) {
            List<Id> userAssignmentIds = assignmentIdsByUserId.get(userId);
            for (Id assignmentId : userAssignmentIds) {
              userIdsByAssignmentId.put(assignmentId, userId);
            }
        }

        return userIdsByAssignmentId;
    }

    @TestVisible
    private List<WorkRamp_Assignment__c> getAssignmentsRequiringOwnerUpdate() {
        List<Id> assignmentIds = getAssignmentIdsRequiringOwnerUpdate();

        return [
          SELECT Id, OwnerId
          FROM WorkRamp_Assignment__c
          WHERE Id IN :assignmentIds
        ]; 
    }

    private List<Id> getAssignmentIdsRequiringOwnerUpdate() {
        List<Id> assignmentIds = new List<Id>();
        for (List<Id> assignmentIdList : assignmentIdsByUserId.values()) {
            for (Id assignmentId : assignmentIdList) {
              assignmentIds.add(assignmentId);
            }
        }

        return assignmentIds;
    }
}