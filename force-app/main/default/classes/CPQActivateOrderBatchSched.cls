global class CPQActivateOrderBatchSched implements Schedulable {
	global void execute(SchedulableContext sc) {
		CPQActivateOrderBatch b = new CPQActivateOrderBatch();
		database.executebatch(b, b.defaultBatchSize);
	}
}