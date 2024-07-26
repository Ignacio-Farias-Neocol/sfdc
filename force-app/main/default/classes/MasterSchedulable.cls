/**
* @author        Scott Will/salesforce services       
* @date          2016-09-29
* @description   Master Schedulable for executing Daily batches w/o the need to individually schedule
*       To use this master class :
*       1. create  apex that implement Database.Batchable<SObject>. This apex should have a standard constructor without parameter
*       2. update the custom setting with Schedulable_Batch__c with the frequency
*       3. from the developer console , start the perpetual, hourly cron 'Master Schedule - Hourly' job by
*                     MasterSchedulable.createHourlySchedule();
* @group         Schedulable
*
*/
global class MasterSchedulable implements Schedulable {

    // Schedule Name
    final static String CRONJOB_NAME = 'Master Schedule - Hourly';
    final static Integer QUEUE_LIMIT = 100; // flex queue limit

    /**
    * @description Sets up the class to run hourly
    * @author Scott Will
    * @date 2016-09-29
    * @return void
    */
    // start the master scheduler by
    // MasterSchedulable.createHourlySchedule();
    public static Id createHourlySchedule() {

        List<CronTrigger> jobs = new List<CronTrigger>([
                select Id
                from CronTrigger
                where CronJobDetail.Name = :CRONJOB_NAME
        ]);

        Id scheduleId;

        if (jobs.isEmpty()) {
            // create a schedule to run hourly
            scheduleId = System.schedule(CRONJOB_NAME, '0 0 * * * ?', new MasterSchedulable());
            System.debug('Cron Job scheduled: ' + scheduleId);

        }
        else {
            // schedule is already active
            scheduleId = jobs[0].Id;
            System.debug('Cron Job already scheduled:' + scheduleId);
        }

        return scheduleId;

    }

    /**
    * @description Entry Point for Schedulable service
    * @author Scott Will
    * @date 2016-09-29
    * @param SchedulableContext
    * @return void
    */
    global void execute(SchedulableContext sc) {
        processBatches();
    }

    /**
    * @description Processess batches that are stored in the {TODO} custom metadata.
    * @author Scott Will
    * @date 2016-09-29
    * @return void
    */
    private void processBatches() {

        LogModel logModel = LogModel.startLog(
                'MasterSchedulable',
                'Processing Daily Batches',
                LogModel.LOG_CATEGORY_ASYNCHRONOUS_PROCESS
        );

        // check how many jobs are currently running/queued
        Set<String> runningStatuses = new Set<String> { 'Holding', 'Preparing', 'Processing', 'Queued' };
        Integer holdingCount = 0;
        Set<String> runningJobs = new Set<String>();
        for (AsyncApexJob job : [
                select
                        ApexClass.Name,
                        Status
                from AsyncApexJob
                where Status in :runningStatuses
        ]) {

            runningJobs.add(job.ApexClass.Name);
            if (job.Status == 'Holding') {
                holdingCount++;
            }

        }

        // nothing more can be added at this time
        if (holdingCount >= QUEUE_LIMIT) {
            logModel.endLog('Too many jobs already queued.');
            return;
        }

        Integer queuedCount = 0;
        Integer maxInterval = 0;

        // set the hourly field that is being evaluated
        Integer currentHourGmt = DateTime.now().hourGmt();
        String fieldName = String.format('X{0}00__c', new List<String> { String.valueOf(currentHourGmt).leftPad(2).replaceAll(' ', '0') });

        // get the configured batches
        Map<String,Schedulable_Batch__c> batchesMap = new Map<String,Schedulable_Batch__c>();
        for (Schedulable_Batch__c schedulableBatch : Schedulable_Batch__c.getAll().values()) {

            Object obj = schedulableBatch.get(fieldName);
            Boolean isWindowOpen = Boolean.valueOf(String.valueOf(obj == null ? false : obj));

            // filter out any running, inactive, or ineligable batches
            if (!runningJobs.contains(schedulableBatch.Name) && schedulableBatch.Is_Active__c && isWindowOpen) {

                batchesMap.put(schedulableBatch.Name, schedulableBatch);
                // keep track of longest interval to help limit soql
                maxInterval = schedulableBatch.Interval__c > maxInterval
                        ? schedulableBatch.Interval__c.intValue()
                        : maxInterval;
            }

        }
        maxInterval++; // tack on an additional hour

        // how far back to look in the historical apex job records
        DateTime lookback = DateTime.now().addHours(-maxInterval);

        // jobs that are ready to run again, using a list to preserve order
        List<String> readyJobs = new List<String>();
        Set<String> uniqueNames = new Set<String>();

        // any batches that have never ran, they will get top priority
        Set<String> unranBatches = batchesMap.keySet().clone();

        Set<String> finishedStatuses = new Set<String> { 'Aborted', 'Completed', 'Failed' };

        // get last run from AsyncApexJobs object
        for (AsyncApexJob job : [
                select
                        ApexClass.Name,
                        CreatedDate
                from AsyncApexJob
                where JobType in ('BatchApex', 'BatchApexWorker')
                and Status in :finishedStatuses
                and ApexClass.Name in :batchesMap.keySet()
                and CreatedDate >= :lookback
                order by CreatedDate desc // order desc to get latest ran
        ]) {

            String className = job.ApexClass.Name;

            // batch has at least been ran, remove it so that it doesnt get automatically added after the loop
            unranBatches.remove(className);

            if (!runningJobs.contains(className) && uniqueNames.add(className)) {

                // difference in hours
                Long delta = (DateTime.now().getTime() - job.CreatedDate.getTime()) / 3600000;
                Schedulable_Batch__c batchInfo = batchesMap.get(className);

                // if the job was completed over its interval ago
                if (delta >= batchInfo.Interval__c) {
                    // queue the batch
                    readyJobs.add(className);
                }
                else {
                    logModel.addLog(className + ' has not met elapsed interval');
                    System.debug(className + ' has not met elapsed interval');
                }

            }

        }

        // add any virgin batches to the list so they will run asap
        readyJobs.addAll(unranBatches);

        // execute as many of the queued batches as possible.  the next schedule 
        // will continue to execute any batches that are not touched here
        while (holdingCount < QUEUE_LIMIT && !readyJobs.isEmpty()) {

            // remove the last element as it's either never been ran or has been waiting the longest
            String batchName = readyJobs.remove(readyJobs.size() - 1);

            // create an instance of the batch
            Type t = Type.forName(batchName);
            if (t == null) {
                logModel.addErrorLog('Cannot find ' + batchName);
                System.debug('Cannot find ' + batchName);
            }
            else {

                Object objbatch = t.newInstance();
                if (objbatch instanceof Database.Batchable<SOBject>) {

                    // queue the batch and increment
                    Schedulable_Batch__c batchInfo = batchesMap.get(batchName);
                    Database.executeBatch((Database.Batchable<SOBject>)objbatch, batchInfo.Scope__c.intValue());
                    queuedCount++;
                    holdingCount++;

                    System.debug(batchName + ' enqueued');
                    logModel.addLog(batchName + ' enqueued');

                }
                else {
                    // create exception log
                    logModel.addErrorLog(batchName + ' is not an instance of Database.Batchable<SOBject>');
                    System.debug(batchName + ' is not an instance of Database.Batchable<SOBject>');
                }

            }

        }

        logModel.endLog('Queued ' + queuedCount + ' job(s)');

    }

}