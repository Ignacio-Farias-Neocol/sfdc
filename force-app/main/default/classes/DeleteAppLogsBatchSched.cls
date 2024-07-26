global class DeleteAppLogsBatchSched implements Schedulable {
    global void execute(SchedulableContext sc) {
      DeleteAppLogDetailsBatch d = new DeleteAppLogDetailsBatch();
      database.executebatch(d, d.defaultBatchSize);
    }
  }