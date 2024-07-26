/**
 * Created by rmigwani on 5/4/22.
 *
 *  @Date 2022/5/4
 *  @group Batchable
 * 
 *  
 */

global with sharing class ContractUpdateStatusBatch implements Database.Batchable<SObject> {
    public Integer defaultBatchSize = 1;
    private Integer defaultLoadSize = null;

    public String SOQL = 'Select Id, Status, All_Subs_RMA__c, (Select Id from SBQQ__Subscriptions__r)' + 
                        'from Contract ' + 
                        'where status =\'Activated\' ';
                        


public ContractUpdateStatusBatch() {

    List<Batch_Job_System_Property__mdt> props = [Select ID, DeveloperName, MasterLabel, Value__c, Business_Group__c From Batch_Job_System_Property__mdt];

    for (Batch_Job_System_Property__mdt prop : props) {
        if ((prop.DeveloperName == 'Contract_UpdateStatus_Load_Size' && !String.isEmpty(prop.Value__c))) {
            try {
                defaultLoadSize = Integer.valueOf(prop.Value__c);
            } catch (Exception e) {}
        }
        
        if ((prop.DeveloperName == 'Contract_UpdateStatus_Batch_Size' && !String.isEmpty(prop.Value__c))) {
            try {
                defaultBatchSize = Integer.valueOf(prop.Value__c);
            } catch (Exception e) {}
        }
    }

    if (defaultLoadSize != null)
            SOQL += ' LIMIT ' + String.valueOf(defaultLoadSize);
 }

 global Database.QueryLocator start(Database.BatchableContext bc) {
    System.Debug('*** defaultBatchSize ' + defaultBatchSize);
    System.Debug('*** SOQL ' + SOQL);
    return Database.getQueryLocator(SOQL);
}

global void execute(Database.BatchableContext bc, List<Contract> cList){

    Map<ID, Contract> errors = new Map<ID, Contract>();
        
    List<Contract> consToUpdate = new List<Contract>();
    Boolean flagAllInactiveSubs=true;

    for (Contract c: cList){

        System.Debug('*** processing contract ' + c.Id);

        if(c.All_Subs_RMA__c)
          c.status='InActive';

          else {

            for(SBQQ__Subscription__c s: c.SBQQ__Subscriptions__r) {
                if(s.Active__c)
                  flagAllInactiveSubs=false;
            }

            if(flagAllInactiveSubs)
              c.status='InActive';
          }

          consToUpdate.add(c);
    }

    System.Debug('***  contractsToUpdate ' + consToUpdate);

    Database.DMLOptions dml = new Database.DMLOptions();
    dml.allowFieldTruncation = true;

    Database.SaveResult[] srList = Database.update(consToUpdate, false);
    for (Integer i = 0; i < srList.size(); i++) {
        Contract o = new Contract(ID = consToUpdate[i].Id);

        Database.SaveResult sr = srList[i];
        if (!sr.isSuccess()) {
            String errorMsg = '';
            for(Database.Error err : sr.getErrors()) {
                errorMsg = errorMsg + err.getMessage() + '\n';
            }

            System.Debug('*** error contract ' + o.Id + ', errorMsg ' + errorMsg);
            o.setOptions(dml);
            o.Contract_Error_Check__c = 'ContractUpdateStatusBatch Error: ' + errorMsg;
            o.Has_Contract_Error__c = TRUE;
            errors.put(o.Id, o);
        } else {
            System.Debug('*** success contract ' + o.Id);
        }
    }

    if (errors.size() > 0)
        Database.update(errors.values(), false);
}

global void finish(Database.BatchableContext BC){}

}