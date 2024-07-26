global class MWInactiveOMDeleteBatchSched implements Schedulable {
	global void execute(SchedulableContext sc) {
		MWInactiveOMDeleteBatch b = new MWInactiveOMDeleteBatch();
		database.executebatch(b);
	}
}