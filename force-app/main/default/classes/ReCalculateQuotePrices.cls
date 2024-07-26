global class ReCalculateQuotePrices implements Database.Batchable <SObject> {
    
    private static Integer defaultBatchSize = 1;
    protected Database.BatchableContext batchableContext;
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        
        System.debug('start');
        String getAutoRenewalOpsQuery='Select Id, Name,ReCalToggle__c,SBQQ__Opportunity2__r.Name from SBQQ__Quote__c where SBQQ__Primary__c =true'+
           ' and Auto_Renew__c=true and SBQQ__Opportunity2__r.Auto_Renewal_Eligible_Core__c =true and SBQQ__Opportunity2__r.isClosed!=true';
        return Database.getQueryLocator(getAutoRenewalOpsQuery);
    }
    
    //EXECUTE METHOD
    global void execute(Database.BatchableContext bc, List<SBQQ__Quote__c> scope){
    
      System.debug('execute');
        for(SBQQ__Quote__c q: scope){
         if (q.ReCalToggle__c==false)
               q.ReCalToggle__c = true;
         else if (q.ReCalToggle__c==true)
               q.ReCalToggle__c = false;
        }
         Database.update(scope, false);
    }
    
    //FINISH METHOD
    global void finish(Database.BatchableContext bc){
      System.debug('finish');
    
        Id job= bc.getJobId();
        System.debug(job);
    }
}