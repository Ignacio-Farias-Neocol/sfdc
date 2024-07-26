public class CPQReContractedOrderBatchSched  implements Schedulable {
  public void execute(SchedulableContext sc) {
    CPQReContractedOrderBatch b = new CPQReContractedOrderBatch();
    database.executebatch(b, b.defaultBatchSize);
  }
}