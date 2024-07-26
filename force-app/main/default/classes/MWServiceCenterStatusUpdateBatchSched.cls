global class MWServiceCenterStatusUpdateBatchSched implements Schedulable {
	global void execute(SchedulableContext sc) {
		MWServiceCenterStatusUpdateBatch b = new MWServiceCenterStatusUpdateBatch();
		database.executebatch(b);
	}
}