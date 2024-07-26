global class CPQApproveQuoteBatchSched implements Schedulable {
	global void execute(SchedulableContext sc) {
		CPQApproveQuoteBatch batch = new CPQApproveQuoteBatch();
		if (batch.defaultBatchSize == null)
			Database.executeBatch(batch);
		else {
			Integer batchSize = batch.defaultBatchSize;
			Database.executeBatch(batch, batchSize);
		}
	}
}