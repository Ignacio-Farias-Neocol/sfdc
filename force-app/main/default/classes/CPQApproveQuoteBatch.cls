/**
 * Created by iyeung on 1/2/19.
 *
 *  @Date 2019/1/2
 *  @group Batchable
 *  
 *  Yuli FIntescu   11/21/2019  Redo
 */
global with sharing  class CPQApproveQuoteBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Integer defaultBatchSize = null;
    private Integer defaultLoadSize = null;

    public String SOQL = 'select Id, ' + 
                            'ApprovalStatus__c, ' + 
                            'SBQQ__Primary__c, ' + 
                            'Opportunity_Type__c, ' + 
                            'SBQQ__Status__c , ' + 
                            'Auto_Renew__c, ' + 
                            'SBQQ__Opportunity2__r.CloseDate ' + 
                        'from SBQQ__Quote__c  ' + 
                        'where SBQQ__Primary__c = TRUE and Has_Contract_Error__c = FALSE and ' +
                            'ApprovalStatus__c  != \'Approved\' and  ' + 
                            'Opportunity_Type__c = \'Renewal\' and ' + 
                            'SBQQ__Status__c != \'Customer Rejected\' and ' + 
                            'SBQQ__Status__c != \'Customer Accepted\'  and ' + 
                            /***
                            * SFDC-17285: Added extra condition as All_Subs_RMA__c  = false: START
                            * */
                            'Auto_Renew__c = true and' +
                            '(Amended_All_Subs_RMA_Contract__c  = false OR Renewed_All_Subs_RMA_Contract__c = false)';
                            /***
                            * SFDC-17285: Added extra condition as All_Subs_RMA__c  = false: END
                            * */

    public CPQApproveQuoteBatch() {
        Date today = Date.today();
        Date tomorrow = today.addDays(1);
        SOQL += ' and ( SBQQ__Opportunity2__r.CloseDate <=  ' + String.valueOf(today) + ')  ';

        List<Batch_Job_System_Property__mdt> props = [Select ID, DeveloperName, MasterLabel, Value__c, Business_Group__c From Batch_Job_System_Property__mdt];

        for (Batch_Job_System_Property__mdt prop : props) {
            if ((prop.DeveloperName == 'Approve_Quote_Load_Size' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                try {
                    defaultLoadSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
            
            if ((prop.DeveloperName == 'Approve_Quote_BatchJob_Size' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                try {
                    defaultBatchSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
        }

        if (defaultLoadSize != null)
            SOQL += ' LIMIT ' + String.valueOf(defaultLoadSize);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.Debug('*** defaultBatchSize ' + defaultBatchSize);
        System.Debug('*** SOQL ' + SOQL);
        return Database.getQueryLocator(SOQL);
    }


    global void execute(Database.BatchableContext BC, List<SBQQ__Quote__c> quoteList){
        Map<ID, SBQQ__Quote__c> errors = new Map<ID, SBQQ__Quote__c>();

        List<SBQQ__Quote__c> quotesToUpdate = new List<SBQQ__Quote__c>();
        
        for (SBQQ__Quote__c q: quoteList){
            System.Debug('*** process quote ' + q.Id);
            
            q.ApprovalStatus__c = 'Approved';
            q.SBQQ__Status__c = 'Customer Accepted';
            //q.SBQQ__Primary__c = true;

            q.Contract_Error_Check__c = null;
            q.Has_Contract_Error__c = FALSE;
            
            quotesToUpdate.add(q);
        }

        System.Debug('***  quotesToUpdate ' + quotesToUpdate);
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.allowFieldTruncation = true;

        Database.SaveResult[] srList = Database.update(quotesToUpdate, false);
        for (Integer i = 0; i < srList.size(); i++) {
            SBQQ__Quote__c q = new SBQQ__Quote__c(ID = quotesToUpdate[i].Id);

            Database.SaveResult sr = srList[i];
            if (!sr.isSuccess()) {
                String errorMsg = '';
                for(Database.Error err : sr.getErrors()) {
                    errorMsg = errorMsg + err.getMessage() + '\n';
                }

                System.Debug('*** error quote ' + q.Id + ', errorMsg ' + errorMsg);
                q.setOptions(dml);
                q.Contract_Error_Check__c = 'ApproveQuoteBatchJob Error: ' + errorMsg;
                q.Has_Contract_Error__c = TRUE;
                errors.put(q.Id, q);
            } else {
                System.Debug('*** success quote ' + q.Id);
            }
        }
        
        if (errors.size() > 0)
            Database.update(errors.values(), false);
    }

    global void finish(Database.BatchableContext BC){}
    /*
    CPQApproveQuoteBatch batch = new CPQApproveQuoteBatch();
    if (batch.defaultBatchSize == null)
        Database.executeBatch(batch);
    else {
        Integer batchSize = batch.defaultBatchSize;
        Database.executeBatch(batch, batchSize);
    }

    select Id, ApprovalStatus__c, SBQQ__Primary__c, Opportunity_Type__c, 
        SBQQ__Status__c, Auto_Renew__c, SBQQ__Opportunity2__r.CloseDate 
    from SBQQ__Quote__c 
    where Has_Contract_Error__c = FALSE and 
        ApprovalStatus__c  != 'Approved' and  
        Opportunity_Type__c = 'Renewal' and 
        SBQQ__Status__c != 'Customer Rejected' and 
        SBQQ__Status__c != 'Customer Accepted' and 
        Auto_Renew__c = true  and (SBQQ__Opportunity2__r.CloseDate <=  2019-11-21)  
    */
}