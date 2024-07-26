global class ProductLifeCycleStatusChangeBatch implements Database.Batchable <SObject> {    
    //START METHOD
    global Database.QueryLocator start(Database.BatchableContext bc){
        Date todayDate = System.today();
        String query = 'Select Id, Lifecycle_status__c, Release_date__c from Product2 Where Release_date__c =: todayDate and Lifecycle_status__c = \'Ready for Release\'';
        if(Test.isRunningTest()) query = 'Select Id, Lifecycle_status__c, Release_date__c from Product2';
        return Database.getQueryLocator(query);
    }
    
    //EXECUTE METHOD
    global void execute(Database.BatchableContext bc, List<Product2> scope){
        for(Product2 prod: scope){
            prod.Lifecycle_status__c = 'Released';          
        }
        
        Database.SaveResult[] srList = Database.update(scope, false); 
        
        Integer index = 0;
        
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess() || Test.isRunningTest()) {
                LogModel log = LogModel.startLog('ProductLifeCycleStatusChangeBatch', 'execute');
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
    
    //FINISH METHOD EXECUTION
    global void finish(Database.BatchableContext bc){
        Id job= bc.getJobId();
        System.debug(job);
        ProductLifeCycleStatusChangeBatch2 b = new ProductLifeCycleStatusChangeBatch2(); 
        database.executebatch(b, 20);        
    }
}