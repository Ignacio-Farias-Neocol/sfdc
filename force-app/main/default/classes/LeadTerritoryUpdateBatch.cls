/**
 * Created by iyeung on 1/2/19.
 *
 *
 * @description
 * https://bugs.cudaops.com/browse/SFDC-1849
 * https://success.salesforce.com/ideaview?id=08730000000BqRXAA0
 *
 *  *  In theory, there are four ways to run this match
 *  1. run this batch immediately from dev console (Database.executeBatch): LeadTerritoryUpdateBatch.executeBatch(null);
 *  2. run this batch x mins from dev console (System.scheduleBatch):   LeadTerritoryUpdateBatch.scheduleBatch(null, null);
 *  3. run this batch x mins from now, using scheduler (System.schedule) : LeadTerritoryUpdateBatchSch.runOnce(minuteAfter);
 *  4. run this batch every weekly/monthly at specifc time using UI (but the code will limit to only once): LeadTerritoryUpdateBatchSch
 *  5. run this batch based upon a cron file using scheduler (System.schedule):  LeadTerritoryUpdateBatchSch.schedule();
 *
 *  For Cuda, only option 1 and 4 is setup
 *
 *  @Date 2019/1/2
 *  @group Batchable
 */
global with sharing  class LeadTerritoryUpdateBatch implements Database.Batchable<SObject>, Database.Stateful {

//    private List<string> messages = new List<String>();
//    protected DateTime startTime = DateTime.Now();
//    protected string env = System.URL.getSalesforceBaseUrl().getHost();
//    protected integer successCount = 0;
//    protected integer failureCount = 0;
private Integer defaultBatchSize = 100;
protected string batchName;
protected Database.BatchableContext batchableContext;

    // note in order to retain the same SOQL statement between run, Database.Stateful interface is used.
    // only instance member variables retain their values between transactions
    // Static member variables don’t retain their values and are reset between transactions.
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_batch_interface.htm
public String SOQL = 'select StateCode, Status,  id, State_Code__c, CountryCode, Terr_Location__c, Terr_Sub_Territory__c, Territory__c, Terr_Region__c, Terr_Sub_Theater__c, Terr_Theater__c from Lead where isConverted = false and status in (\'Marketing Qualified Lead\', \'Sales Accepted Lead\')';


public LeadTerritoryUpdateBatch() {
    if ( Test.isRunningTest()){
        SOQL = SOQL + ' limit 10';
    }
}

global Database.QueryLocator start(Database.BatchableContext BC) {
    batchableContext = BC;
    batchName = 'LeadTerritoryUpdateBatch';
    System.Debug(SOQL);
    return Database.getQueryLocator(SOQL);
}


global void execute(Database.BatchableContext BC, List<Lead> leadList){

DynamicBusinessRuleLeadTerr rule = new DynamicBusinessRuleLeadTerr();
rule.processRecords(null, null, leadList, '', '', '');
// process Records work in pre trigger context and does not save
DML.save(leadList);
}

global void finish(Database.BatchableContext BC){
}

//LeadTerritoryUpdateBatch.executeBatch(null);
global static void executeBatch(){
    LeadTerritoryUpdateBatch batch = new LeadTerritoryUpdateBatch();

    List <Territory_Update_Setting__mdt> settings = [select Batch_Size__c, Log_Hour__c, DeveloperName, Id, Label, Language, Object_Name__c
    from Territory_Update_Setting__mdt where Object_Name__c = 'Lead'];

    Integer batchSize = batch.defaultBatchSize;
    if ( settings.size() > 0 ){
        batchSize = Integer.valueOf(settings[0].Batch_Size__c);
    }
    Database.executeBatch(batch, batchSize);
}

//LeadTerritoryUpdateBatch.scheduleBatch(null, null);
// this scheduling method is not needed.
/*
private Integer defaultScheduleMinFromNow = 10;
global static void scheduleBatch( Integer minFromNow, Integer batchSize){
LeadTerritoryUpdateBatch batch = new LeadTerritoryUpdateBatch();
if (batchSize == null){
batchSize = batch.defaultBatchSize;
}
if (minFromNow == null){
minFromNow = batch.defaultScheduleMinFromNow;
}
String jobName = 'LeadTerritoryUpdateBatch ' + String.valueOf(Datetime.now());
System.scheduleBatch(batch, jobName, minFromNow, batchSize);
}
*/

}