trigger WorkrampAssignmentTrigger on WorkRamp_Assignment__c (after insert, after update) {
    switch on Trigger.operationType
    {
        when AFTER_INSERT
        {
            WorkrampAssignmentUserHandler.setUserFieldsAfterInsert(Trigger.new);
        }
        when AFTER_UPDATE
        {
            WorkrampAssignmentUserHandler.setUserFieldsAfterUpdate(Trigger.new);
        }
    }
}