global class ContractUpdateStatusBatchSched implements Schedulable {
    global void execute(SchedulableContext sc) {
        ContractUpdateStatusBatch c = new ContractUpdateStatusBatch();
        database.executebatch(c, c.defaultBatchSize);
    }
  }