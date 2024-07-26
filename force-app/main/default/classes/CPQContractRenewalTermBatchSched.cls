/**
* @author        Sonal Agrawal(Bluvium)
* @date          15th December 2023
* @description   Calling CPQContractRenewalTermBatch class and scheduled at 2:30 am daily
*
*/
global class CPQContractRenewalTermBatchSched implements Schedulable {
    global void execute(SchedulableContext sc) {
        CPQContractRenewalTermBatch batch = new CPQContractRenewalTermBatch();
        if (batch.defaultBatchSize == null)
            Database.executeBatch(batch);
        else {
            Database.executeBatch(batch, batch.defaultBatchSize);
        }
    }
}