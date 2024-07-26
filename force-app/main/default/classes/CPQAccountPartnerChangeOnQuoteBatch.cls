/**
* @author        Sonal Agrawal(bluvium)
* @date          16th October 2023
* @description   Has a CPQAccountPartnerChangeOnQuoteBatchSched schedular class which schedule at 2 am
*
*/
public class CPQAccountPartnerChangeOnQuoteBatch implements Database.Batchable<SObject> {
    public Integer defaultBatchSize = 1;
    public Integer defaultLoadSize = null;
    
    public String SOQL = 'SELECT id,SBCF_Partner_Level__c,SBCF_Reseller__c,SBCF_Reseller__r.Partner_Level__c,SBQQ__Account__c,createddate '+ 
                        + 'FROM SBQQ__Quote__c ' 
                        + 'WHERE SBCF_Reseller__r.IsPartnerLevelChange__c =true  and SBQQ__Primary__c =true ' 
                        + 'and SBQQ__Opportunity2__r.Oppty_Status__c =\'Open\'' 
                        + ' and SBQQ__Opportunity2__r.SBQQ__Ordered__c =false '
                        + 'order by createddate desc';
    
    public CPQAccountPartnerChangeOnQuoteBatch(){
        List<Batch_Job_System_Property__mdt> props = [Select ID, DeveloperName, MasterLabel, Value__c, Business_Group__c From Batch_Job_System_Property__mdt];
        for (Batch_Job_System_Property__mdt prop : props) {
            if ((prop.DeveloperName == 'Update_Quote_Load_Size' && !String.isEmpty(prop.Value__c))) {
                try {
                    defaultLoadSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
            
            if ((prop.DeveloperName == 'Update_Quote_BatchJob_Size' && !String.isEmpty(prop.Value__c))) {
                try {
                    defaultBatchSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
        }
        if (defaultLoadSize != null)
            SOQL += ' LIMIT ' + String.valueOf(defaultLoadSize);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.Debug('*** defaultBatchSize ' + defaultBatchSize);
        System.Debug('*** SOQL ' + SOQL);
        return Database.getQueryLocator(SOQL);
    }
    public void execute(Database.BatchableContext bc, List<SBQQ__Quote__c> qlist){
        Map<ID, SBQQ__Quote__c> errors = new Map<ID, SBQQ__Quote__c>();
        Set<Account> AccountToUpdate = new Set<Account>();
        List<SBQQ__Quote__c> QuoteUpdateList = new List<SBQQ__Quote__c>();
        for (SBQQ__Quote__c q: qlist){
            Account a = new Account();
            a.Id = q.SBCF_Reseller__c;
            a.IsPartnerLevelChange__c = false;
            AccountToUpdate.add(a);
            SBQQ__Quote__c Qrecord = new SBQQ__Quote__c(id= q.id);
            Qrecord.SBCF_Partner_Level__c = q.SBCF_Reseller__r.Partner_Level__c;
            QuoteUpdateList.add(Qrecord);
        }
        System.Debug('***  QuoteUpdateList ' + QuoteUpdateList);
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.allowFieldTruncation = true;
        Database.SaveResult[] srList = Database.update(QuoteUpdateList, false);
        for (Integer i = 0; i < srList.size(); i++) {
            SBQQ__Quote__c o = new SBQQ__Quote__c(ID = QuoteUpdateList[i].Id);
            Database.SaveResult sr = srList[i];
            if (!sr.isSuccess()) {
                String errorMsg = '';
                for(Database.Error err : sr.getErrors()) {
                    errorMsg = errorMsg + err.getMessage() + '\n';
                }
                System.Debug('*** error Quote ' + o.Id + ', errorMsg ' + errorMsg);
                o.setOptions(dml);
                o.Contract_Error_Check__c = 'CPQAccountPartnerChangeOnQuoteBatch Error: ' + errorMsg;
                o.Has_Contract_Error__c = TRUE;
                errors.put(o.Id, o);
            } else {
                System.Debug('*** success Quote ' + o.Id);
            }
        }
        if (errors.size() > 0)
            Database.update(errors.values(), false);
        
        if(AccountToUpdate.size()>0){
            try{
            List<Account> AccountToUpdateList= new List<Account>(AccountToUpdate);
                Update AccountToUpdateList;
            }catch(DmlException e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }
    }
    public void finish(Database.BatchableContext BC){}
    
}