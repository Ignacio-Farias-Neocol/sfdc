/**
 * Created by iyeung on 1/2/19.
 *
 *
 * @description  run the scheduled job only once
 * https://help.salesforce.com/articleView?id=000002809&type=1
 * https://help.salesforce.com/articleView?id=000004725&type=1  - assignment rule via SOAP API
 * https://help.salesforce.com/articleView?id=000228299&language=en_US&type=1 - mass assign via data loader
 * https://bugs.cudaops.com/browse/SFDC-1849
 *
 *  @Date 2018/12/01
 *  @group Schedulable
 */
global with sharing class LeadTerritoryUpdateBatchSchedulable implements Schedulable{


// Seconds:0–59, Minutes:0-59, Hours:0-23, Day_of_month: 1-31, Month: 1-12, Day_of_week:1-7  , year: null or 1970–2099
// public static String sched_00_After = '0 00 * * * ?';


//LeadTerritoryUpdateBatchSchedulable.runOnce();
// 2019-01-05 . this scheduling method is not used
/*
public static Integer defaultMinAfter = 60;
global static void runOnce(Integer minuteAfter) {

String suffix = '';
if ( Test.isRunningTest()){
suffix = 'test';
}

Integer minAfter = 0;
if (minuteAfter == null){
minAfter = defaultMinAfter; //
}

Datetime refDatetime = Datetime.now().addMinutes(minAfter);

String hour = String.valueOf(refDatetime.hour());
String min = String.valueOf(refDatetime.minute() );
String ss = String.valueOf(refDatetime.second());

//parse to cron expression
String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';

LeadTerritoryUpdateBatchSchedulable s = new LeadTerritoryUpdateBatchSchedulable();
System.schedule('AccountTerritoryUpdateByLeadBatch ' + suffix + String.valueOf(Datetime.now()) + ' ' +  min, nextFireTime, s);
}
*/


//LeadTerritoryUpdateBatchSchedulable.schedule();
/**
*
*
* @return
*/
/*
    global static String schedule() {

    LeadTerritoryUpdateBatchSchedulable tbs = new LeadTerritoryUpdateBatchSchedulable();
    return System.schedule('Lead Territory Update Batch ', sched_01_After, tbs);
}
*/


/**
 * start to update the Lead Territory refresh
 *
 * @param sc
 */
global void execute(SchedulableContext sc) {
    LeadTerritoryUpdateBatch.executeBatch();
}

global void finish(Database.BatchableContext BC)
{
// kill the active job after finish : i.e. make this scheduler only run once.

// Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.
// Query the AsyncApexJob object to retrieve the current job's information.
AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id =  :BC.getJobId()];

//then use the active job id and abort it
system.abortJob(a.id);
}


}