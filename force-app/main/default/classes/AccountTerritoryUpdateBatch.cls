/**
 * Created by iyeung on 1/2/19.
 *
 *
 * @description
 * https://bugs.cudaops.com/browse/SFDC-1849
 * https://success.salesforce.com/ideaview?id=08730000000BqRXAA0
 *
 *  *  There are four ways to run this match
 *  1. run this batch immediately from dev console (Database.executeBatch): AccountTerritoryUpdateBatch.executeBatch(null);
 *  2. run this batch x mins from dev console (System.scheduleBatch):   AccountTerritoryUpdateBatch.scheduleBatch(null, null);
 *  3. run this batch x mins from now, using scheduler (System.schedule) : AccountTerritoryUpdateBatchSch.runOnce(minuteAfter);
 *  4. run this batch every weekly/monthly at specifc time using UI (but the code will limit to only once): AccountTerritoryUpdateBatchSch
 *
 *  For Cuda, only option 1 and 4 is setup
 *
 *  @Date 2019/1/2
 *  @group Batchable
 */
global with sharing  class AccountTerritoryUpdateBatch implements Database.Batchable<SObject>, Database.Stateful {

//    private List<string> messages = new List<String>();
//    protected DateTime startTime = DateTime.Now();
//    protected string env = System.URL.getSalesforceBaseUrl().getHost();
//    protected integer successCount = 0;
//    protected integer failureCount = 0;
    private static Integer defaultBatchSize = 100;
    private static Integer defaultHour = 24;
    protected string batchName;
    protected Database.BatchableContext batchableContext;

    // note in order to retain the same SOQL statement between run, Database.Stateful interface is used.
    // only instance member variables retain their values between transactions
    // Static member variables don’t retain their values and are reset between transactions.
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_batch_interface.htm
    public String SOQL = 'select AssociationCause, Id, LastModifiedDate, ObjectId, SobjectType, Territory2Id from ObjectTerritory2Association  where object.Type = \'Account\' and LastModifiedDate > ';


    public AccountTerritoryUpdateBatch(Integer modifiedWithinHours) {

        if (modifiedWithinHours == null){
            modifiedWithinHours = defaultHour;
        }

        Datetime yesterday = DateTime.now().addHours( -(modifiedWithinHours));
        String dateTimeFormat = yesterday.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        SOQL = SOQL + dateTimeFormat;


        if ( Test.isRunningTest()){
            SOQL = SOQL + ' limit 10';
        }

        System.debug('~~#@~~ SOQL at constructor ' + SOQL);

    }


    global Database.QueryLocator start(Database.BatchableContext BC) {
        batchableContext = BC;
        batchName = 'AccountTerritoryUpdateBatch';
        System.debug('~~#@~~ SOQL at start ' + SOQL);
        return Database.getQueryLocator(SOQL);
    }


    global void execute(Database.BatchableContext BC, List<ObjectTerritory2Association> associateList){

        Set <String> objectIds = new Set <String>();
        for (ObjectTerritory2Association o: associateList ){
            objectIds.add(o.ObjectId);
        }


        DynamicBusinessRuleLeadTerr.TerritoryField t = DynamicBusinessRuleLeadTerr.TerritoryFieldMap.get('Account');
        String soql = 'select id , ' + t.stateCode + ', ' + t.countryCode + ', ' + t.terrLocation + ', ' + t.terrSubTerritory + ', ' + t.territory + ', ' + t.terrRegion + ', ' + t.terrSubTheater + ', ' + t.terrTheater  + ', ' + t.alignmentRun + ' from Account where id in :objectIds ';

        System.debug('~~#@~~ soql: ' +soql );
        List<sObject> accountList = Database.query(soql);

        // 2019-01-30 just alignment Run field
        // DynamicBusinessRuleLeadTerr rule = new DynamicBusinessRuleLeadTerr();
        // rule.processRecords(null, null, accountList, '', '', '');
        for (sObject o: accountList ){
            if (o.get(t.alignmentRun) != null){
                o.put(t.alignmentRun, (decimal) o.get(t.alignmentRun) + 1);
            } else {
                o.put(t.alignmentRun, 1);
            }

        }


        // process Records work in pre trigger context and does not save
        DML.save(accountList);
    }

    global void finish(Database.BatchableContext BC){
    }

    //AccountTerritoryUpdateBatch.executeBatch(120, null); // 5 days ago
    //AccountTerritoryUpdateBatch.executeBatch(24, null);
    // global static void executeBatch( Integer modifiedWithinHours, Integer batchSize){
    global static void executeBatch( ){

        List <Territory_Update_Setting__mdt> settings = [select Batch_Size__c, Log_Hour__c, DeveloperName, Id, Label, Language, Object_Name__c
        from Territory_Update_Setting__mdt where Object_Name__c = 'Account'];

        Integer modifiedWithinHours = AccountTerritoryUpdateBatch.defaultHour;
        Integer batchSize = AccountTerritoryUpdateBatch.defaultBatchSize;

        if (settings.size() > 0 ){
            modifiedWithinHours =  Integer.valueOf( settings[0].Log_Hour__c);
            batchSize =  Integer.valueOf( settings[0].Batch_Size__c);
        }

        AccountTerritoryUpdateBatch batch = new AccountTerritoryUpdateBatch(modifiedWithinHours);
        Database.executeBatch(batch, batchSize);
    }

    /* 2019-01-05 this method is not used
    //AccountTerritoryUpdateBatch.scheduleBatch(24, null, null);
    private Integer defaultScheduleMinFromNow = 10;
    global static void scheduleBatch( Integer modifiedWithinHours, Integer minFromNow, Integer batchSize){
        AccountTerritoryUpdateBatch batch = new AccountTerritoryUpdateBatch(modifiedWithinHours );
        if (batchSize == null){
            batchSize = batch.defaultBatchSize;
        }
        if (minFromNow == null){
            minFromNow = batch.defaultScheduleMinFromNow;
        }
        String jobName = 'AccountTerritoryUpdateBatch ' + String.valueOf(Datetime.now());
        System.scheduleBatch(batch, jobName, minFromNow, batchSize);
    }
    */


}