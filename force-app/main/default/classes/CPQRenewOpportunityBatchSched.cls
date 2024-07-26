global class CPQRenewOpportunityBatchSched implements Schedulable {
	global void execute(SchedulableContext sc) {
		CPQRenewOpportunityBatch b = new CPQRenewOpportunityBatch();
		database.executebatch(b, b.defaultBatchSize);
	}
}