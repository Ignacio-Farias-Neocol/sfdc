global class ContractSerialSubscriptionBatchSched implements Schedulable {

    global void execute(SchedulableContext sc) {
        ContractSerialSubscriptionBatch batch = new ContractSerialSubscriptionBatch();
        if (batch.defaultBatchSize == null)
            Database.executeBatch(batch);
        else {
            Database.executeBatch(batch, batch.defaultBatchSize);
        }
    }
}