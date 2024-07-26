global class CaseFutureClass {
    
    @future
    public static void updateCompletedMilestoneStatus(String caseIdSetString){ 
        System.debug('###caseIdSetString::: ' + caseIdSetString);
        List<Case> caseList = new List<Case>();
        Set<Id> caseIdSet = (Set<Id>) JSON.deserialize(caseIdSetString, Set<Id>.class);
        Map<Id, Case> caseMap = new Map<Id, Case>([Select Id, CaseNumber, (Select Id, isViolated from CaseMilestones where IsCompleted = true order by CreatedDate desc limit 1) from Case where Id =: caseIdSet]); 
        System.debug('###@@caseMap:: ' + JSON.serialize(caseMap));
        for(Id caseId: caseIdSet){
            Case caseRecord = new Case();
            caseRecord.Id = caseId;
            if(!caseMap.get(caseId).caseMilestones.isEmpty() && !caseMap.get(caseId).caseMilestones[0].IsViolated){
                caseRecord.Completed_Milestone_Status__c = 'Compliant';
            } else if(!caseMap.get(caseId).caseMilestones.isEmpty() && caseMap.get(caseId).caseMilestones[0].IsViolated) {
                caseRecord.Completed_Milestone_Status__c = 'Violation';
            }            
            caseList.add(caseRecord);
        }
        
        System.debug('###caseList::: ' + JSON.serialize(caseList));
        // for this particular update we don't want the triggers to run
        TriggerContextVariables.RUN_CASE_TRIGGER = false;
        if(!caseList.isEmpty()) update caseList;
    }   
}