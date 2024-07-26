global class ProductLifeCycleStatusChangeBatch2 implements Database.Batchable <SObject> {    
    //START METHOD
    global Database.QueryLocator start(Database.BatchableContext bc){
        Date todayDate = System.today();
        String query = 'Select Id, Lifecycle_status__c, Release_date__c, EOS__c, EOR__c, EOL__c from Product2';        
        return Database.getQueryLocator(query);
    }
    
    //EXECUTE METHOD
    global void execute(Database.BatchableContext bc, List<Product2> scope){
        for(Product2 prod: scope){                        
            // 1
            if(prod.EOS__c != null && prod.EOS__c == System.today() && prod.Lifecycle_status__c == 'Released'){
                prod.Lifecycle_status__c = 'Renewal Only';
            }
            
            // 2
            if(prod.EOR__c != null && prod.EOR__c == System.today() && (prod.Lifecycle_status__c == 'Renewal Only' || prod.Lifecycle_status__c == 'Released')){
                prod.Lifecycle_status__c = 'End of Sale';
            }      
            
            // 2.a
            if(prod.EOR__c != null && prod.EOS__c != null && prod.EOR__c == prod.EOS__c && prod.Lifecycle_status__c != 'End of Sale'){
                prod.Lifecycle_status__c = 'End of Sale';
            }     
            
            // 3
            if(prod.EOL__c != null && prod.EOL__c == System.today() && (prod.Lifecycle_status__c == 'Renewal Only' || prod.Lifecycle_status__c == 'End of Sale')){
                prod.Lifecycle_status__c = 'End of Life';
            }             
        }
        
        Database.SaveResult[] srList = Database.update(scope, false); 
        
        Integer index = 0;
        
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess() || Test.isRunningTest()) {
                LogModel log = LogModel.startLog('ProductLifeCycleStatusChangeBatch2', 'execute');
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