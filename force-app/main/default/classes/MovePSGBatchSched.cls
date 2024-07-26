global class MovePSGBatchSched implements Schedulable {
    global void execute(SchedulableContext sc) {
        MovePSGBatch d = new MovePSGBatch();
        database.executebatch(d, d.defaultBatchSize);
    }
  }