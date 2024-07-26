global class CPQPlaceOrderBatchSched implements Schedulable {
    global void execute(SchedulableContext sc) {
        CPQPlaceOrderBatch batch = new CPQPlaceOrderBatch();
        if (batch.defaultBatchSize == null)
            Database.executeBatch(batch);
        else {
            Database.executeBatch(batch, batch.defaultBatchSize);
        }
    }
}