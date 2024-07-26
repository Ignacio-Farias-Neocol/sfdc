global class CPQCloseOpportunityBatchSched implements Schedulable {
	global void execute(SchedulableContext sc) {
		CPQCloseOpportunityBatch b = new CPQCloseOpportunityBatch();
		database.executebatch(b, b.defaultBatchSize);
	}
}