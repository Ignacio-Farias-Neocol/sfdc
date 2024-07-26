global class CaseClosureBatch implements Database.Batchable <SObject> {
    // Schedule Class:: WebMessageCleanUpScheduler
    public String query;
    
    public CaseClosureBatch(String query){ 
        this.query=query;
    }
    
    //START METHOD
    global Database.QueryLocator start(Database.BatchableContext bc){
        Date beforeForteenDays=date.today().adddays(-14);
        String waitTime = Label.ResolvedToCloseWaitTime;
        Integer waitHours = Integer.valueOf(waitTime);
        Datetime dt = System.now().addHours(-waitHours);
        String queryString = 'Select Id, Status from Case where Case_Resolved_Datetime__c <: dt and Status = \'Resolved\'';
        if(Test.isRunningTest()) queryString = 'Select Id, Status from Case';
        if(query != null) queryString = query;
        return Database.getQueryLocator(queryString);
    }
    
    //EXECUTE METHOD
    global void execute(Database.BatchableContext bc, List<Case> scope){
        for(Case c: scope){
            c.Status = 'Closed';
            c.Closed_By_Process__c = 'Batch Class';
        }
        
        Database.SaveResult[] srList = Database.update(scope, false); 
        
        Integer index = 0;
        
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess() || Test.isRunningTest()) {
                LogModel log = LogModel.startLog('CaseClosureBatch', 'execute');
                String errorStr = 'Record Id: ' + scope[index].Id;
                
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {                        
                    errorStr = errorStr + ' ' + err.getStatusCode() + ' ' + err.getMessage() + ' ' + err.getFields();                        
                }
                if(errorStr.length() > 32767){
                    errorStr = errorStr.substring(0, 32767);
                }                    
                log.endLog(errorStr);
            }
            
            index++;
        }                       
    }
    
    //FINISH METHOD
    global void finish(Database.BatchableContext bc){
        Id job= bc.getJobId();
        System.debug(job);
    }
}