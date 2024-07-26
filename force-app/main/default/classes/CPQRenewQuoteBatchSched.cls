global class CPQRenewQuoteBatchSched implements Schedulable {
	global void execute(SchedulableContext sc) {
		CPQRenewQuoteBatch b = new CPQRenewQuoteBatch();
		database.executebatch(b, b.defaultBatchSize);
	}
}