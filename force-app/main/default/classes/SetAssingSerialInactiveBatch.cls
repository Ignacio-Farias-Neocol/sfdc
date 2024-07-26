/**
 * Created by Rajesh Wani on 10/25/2023.
 *  @Date 10/25/2023
 *
 *  Description:
 *  Set Assign serial status to Inactive if related subscrioption expired in last 30 days
 *  
 *  Added as a part of SFDC-19052
 */
global class SetAssingSerialInactiveBatch implements Database.Batchable<SObject>{
    public String StatusActive = 'Active';
    public String StatusInActive = 'Inactive';
    public Date DateFilter ;
   
    /**
     * START Method:
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        DateFilter = system.today()-30;
        StatusActive = 'Active';
        StatusInActive = 'Inactive';
        String query ='SELECT id,Serial__c,Status__c, Data_Reporting_Field__c,Exclude_From_Update__c,  Subscription__c,Subscription__r.SBQQ__EndDate__c,Subscription__r.SBQQ__TerminatedDate__c, Subscription__r.SBQQ__SubscriptionEndDate__c, Asset__c,Subscription__r.SBCF_Serial_Number__c, Asset__r.SBCF_Serial_Number__c,Subscription__r.SBQQ__Account__c,External_ID__c from Assigned_Serial__c where (Subscription__r.SBQQ__EndDate__c<:DateFilter OR Subscription__r.SBQQ__TerminatedDate__c!=null)AND Status__c=:StatusActive';
        return Database.getQueryLocator(query);
    }
    /**
     * Execute Method:
     */
    global void execute(Database.BatchableContext BC, List<Assigned_Serial__c> AssignSerialList){
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('SetAssingSerialInactiveBatch', 'executeMethod', LogModel.LOG_CATEGORY_APEX);
        List<Assigned_Serial__c> lstAssignedSerialUpdate = new List<Assigned_Serial__c>();
        Map<ID, Assigned_Serial__c> errors = new Map<ID, Assigned_Serial__c>();
        Map<Id, Assigned_Serial__c> mapAssignedSerial = new Map<id, Assigned_Serial__c>();
        Set<Id> oppIds = new Set<Id>();
        List<Assigned_Serial__c> lstErrorAssignedSerialUpdate = new List<Assigned_Serial__c>();
        List<Assigned_Serial__c> lstSuccessAssignedSerialUpdate = new List<Assigned_Serial__c>();
        String dataReportText ='Status to Inactive if related sub expired in last 30 days -SetAssingSerialInactiveBatch';
        try{
           
            for(Assigned_Serial__c asr : AssignSerialList){
                asr.Status__c = StatusInActive;
                asr.Exclude_From_Update__c= TRUE;
                asr.Data_Reporting_Field__c =asr.Data_Reporting_Field__c!=null?asr.Data_Reporting_Field__c+','+dataReportText:dataReportText;
                lstAssignedSerialUpdate.add(asr);
            }
            
            if(!lstAssignedSerialUpdate.isEmpty()){
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.allowFieldTruncation = true;
                Database.SaveResult[] srList = Database.update(lstAssignedSerialUpdate, false);
                
                for (Integer i = 0; i < srList.size(); i++) {
                    Assigned_Serial__c asr = new Assigned_Serial__c(ID = lstAssignedSerialUpdate[i].Id);

                    Database.SaveResult sr = srList[i];
                    if (!sr.isSuccess()) {
                        String errorMsg = '';
                        for(Database.Error err : sr.getErrors()) {
                            errorMsg = errorMsg + err.getMessage() + '\n';
                        }
                        System.Debug('*** Error ' + asr.Id);
                        asr.setOptions(dml);
                        errors.put(asr.Id, asr);
                    } else {
                        System.Debug('*** success contract ' + asr.Id);
                    }
                }
                if (errors.size() > 0)
                    //System.Debug('*** Error exists');
                    Database.update(errors.values(), false);
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    }
    /**
     * Finish Method:
     */
    global void finish(Database.BatchableContext BC){}

}