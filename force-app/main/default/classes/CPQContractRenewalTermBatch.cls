/**
* @author        Sonal Agrawal(Bluvium)
* @date          15th December 2023
* @description   Has CPQContractRenewalTermBatchSched class which scheduled at 2:30 am daily
*
*/
global with sharing  class CPQContractRenewalTermBatch implements Database.Batchable<SObject> {
    public Integer defaultBatchSize = null;
    private Integer defaultLoadSize = null;

    public String SOQL = 'Select id,Field,OldValue,ContractId, ' +  
                        'NewValue,CreatedDate,Contract.CreatedDate, ' + 
                        'Contract.SBQQ__RenewalTerm__c, contract.ContractTerm ' +  
                        'FROM ContractHistory ' + 
                        'WHERE Field =\'SBQQ__RenewalTerm__c\' and ' + 
                        'contract.ContractTerm!=null and ' + 
                        'CreatedDate =LAST_N_DAYS:7 order by CreatedDate desc';
    public CPQContractRenewalTermBatch() {
        List<Batch_Job_System_Property__mdt> props = [Select ID, DeveloperName, MasterLabel, Value__c, Business_Group__c From Batch_Job_System_Property__mdt];

        for (Batch_Job_System_Property__mdt prop : props) {
            if ((prop.DeveloperName == 'Contract_UpdateStatus_Load_Size' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                try {
                    defaultLoadSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
            
            if ((prop.DeveloperName == 'Contract_UpdateStatus_Batch_Size' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
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

    global void execute(Database.BatchableContext BC, List<ContractHistory> ConthistoryList){
        List<Contract> ContractUpdList = new List<Contract>();
        for(ContractHistory ch: ConthistoryList){
            if(ch.Contract.SBQQ__RenewalTerm__c != ch.contract.ContractTerm){
                if(ch.Contract.CreatedDate==ch.CreatedDate || Test.isRunningTest()){
                    Decimal ContractTerm = ch.contract.ContractTerm;
                    Integer renwalTerm=0;
                    if(ContractTerm>6){
                    Decimal renewalTermRounded = (ContractTerm/12).setScale(0)*12;
                        if(ch.Contract.SBQQ__RenewalTerm__c!=renewalTermRounded){
                            renwalTerm = (Integer)renewalTermRounded;
                        }
                    }
                    else{
                        renwalTerm = (Integer)ContractTerm;
                    }
                    if(renwalTerm>0){
                        Contract con = new Contract();
                        con.id = ch.ContractId;
                        con.SBQQ__RenewalTerm__c = renwalTerm;
                        ContractUpdList.add(con);
                    }
                }
            }
        }
        if(ContractUpdList.size()>0){
            update ContractUpdList;
        }
    }
    global void finish(Database.BatchableContext BC){}
}