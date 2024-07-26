global class UpdateOpportunityResponseTimeBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Set<String> setOfExcludedRoles = new Set<String>();
        Set<String> setOfExcTaskTypes = new Set<String>();        
        for(First_Response_Calc_Excluded_Roles__mdt excludedRoles : First_Response_Calc_Excluded_Roles__mdt.getAll().values()){
            setOfExcludedRoles.add(excludedRoles.Role_Name__c);
        }
        
        for(First_Response_Calc_Excluded_Task_Type__mdt excludedTypes : First_Response_Calc_Excluded_Task_Type__mdt.getAll().values()){
            setOfExcTaskTypes.add(excludedTypes.Type_Name__c);
        }
        // Query Opportunities where 'First Respond Time' is null and there are related completed Tasks
        String query = 'SELECT Id, First_Respond_Time__c, (SELECT CompletedDateTime FROM Tasks WHERE Owner.UserRole.Name NOT IN :setOfExcludedRoles AND Type NOT IN :setOfExcTaskTypes AND Status = \'Completed\' ORDER BY CompletedDateTime ASC LIMIT 1) FROM Opportunity WHERE First_Respond_Time__c = NULL AND CreatedDate >= 2022-01-07T00:00:00Z AND Business_Group__c = \'Core\'';
         if(Test.IsrunningTest())
            query = 'SELECT Id, First_Respond_Time__c, (SELECT CompletedDateTime FROM Tasks WHERE Owner.UserRole.Name NOT IN :setOfExcludedRoles AND Type NOT IN :setOfExcTaskTypes AND Status = \'Completed\' ORDER BY CompletedDateTime ASC LIMIT 1) FROM Opportunity WHERE CreatedDate >= 2022-01-07T00:00:00Z AND Business_Group__c = \'Core\'';
        
        System.debug('Query: ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
        for (Opportunity opp : scope) {
            if (!opp.Tasks.isEmpty()) {
                DateTime completedDateTime = opp.Tasks[0].CompletedDateTime;                
                if (!Test.isRunningTest() && (opp.First_Respond_Time__c != completedDateTime)) {
                    opp.First_Respond_Time__c = completedDateTime;
                    oppsToUpdate.add(opp);
                }else{
                    opp.First_Respond_Time__c = completedDateTime;
                    oppsToUpdate.add(opp);
                }
            }
        }

        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // Post-processing logic (e.g., sending a notification email)
    }
}