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
global with sharing class AccountTerritoryUpdateBatchSchedulable implements Schedulable{

    
/**
 * start to update the Lead Territory refresh
 *
 * @param sc
 */
global void execute(SchedulableContext sc) {
    AccountTerritoryUpdateBatch.executeBatch();
}

global void finish(Database.BatchableContext BC)
{
// kill the active job after finish : i.e. make this scheduler only run once.

// Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.
// Query the AsyncApexJob object to retrieve the current job's information.
String jobId = (BC == null ? '': BC.getJobId());
List <AsyncApexJob> job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id =  :jobId];

//then use the active job id and abort it
if (job != null && job.size() > 0 ) {
    system.abortJob(job[0].id);
}
    
}


}