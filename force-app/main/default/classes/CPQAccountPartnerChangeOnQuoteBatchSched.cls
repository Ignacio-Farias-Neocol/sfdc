public class CPQAccountPartnerChangeOnQuoteBatchSched implements Schedulable {
  public void execute(SchedulableContext sc) {
    CPQAccountPartnerChangeOnQuoteBatch b = new CPQAccountPartnerChangeOnQuoteBatch();
    database.executebatch(b, b.defaultBatchSize);
  }
}