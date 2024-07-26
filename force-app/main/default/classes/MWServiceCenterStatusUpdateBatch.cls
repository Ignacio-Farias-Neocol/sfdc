/**
 * Created by Abi A on 6/29/19.
 *
 *  @Date 2019/6/2
 *  @group Batchable
 */
global with sharing  class MWServiceCenterStatusUpdateBatch implements Database.Batchable<SObject>, Database.Stateful {

    // private List<string> messages = new List<String>();
    // protected DateTime startTime = DateTime.Now();
    // protected string env = System.URL.getSalesforceBaseUrl().getHost();
    // protected integer successCount = 0;
    // protected integer failureCount = 0;
    private Integer defaultBatchSize = 1;
    protected string batchName;
    protected Database.BatchableContext batchableContext;

    // note in order to retain the same SOQL statement between run, Database.Stateful interface is used.
    // only instance member variables retain their values between transactions
    // Static member variables don’t retain their values and are reset between transactions.
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_batch_interface.htm
    public String SOQL = 'Select Id, Status__c from MW_Service_Center__c where Status__c = \'Active\' and Last_Checkin_Time_Stamp__c < LAST_N_DAYS:7';


    public MWServiceCenterStatusUpdateBatch() {

    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        batchableContext = BC;
        batchName = 'MWServiceCenterStatusUpdateBatch';
        System.Debug(SOQL);
        return Database.getQueryLocator(SOQL);
    }


    global void execute(Database.BatchableContext BC, List<MW_Service_Center__c> sList){
        System.Debug('~~~~MW Service Center List: '+sList);
        for (MW_Service_Center__c s: sList){
            s.Status__c = 'Cancelled';
        }
        DML.save(sList);
    }

    global void finish(Database.BatchableContext BC){
    }

    global static void executeBatch(){
        MWServiceCenterStatusUpdateBatch batch = new MWServiceCenterStatusUpdateBatch();
        Integer batchSize = batch.defaultBatchSize;
        Database.executeBatch(batch, batchSize);
    }

}