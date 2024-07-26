global class CloseOpptyAllSubsciptionsRMASchd implements Schedulable{
    global void execute(SchedulableContext sc) {
        CloseOpptyAllSubsciptionsRMA batch = new CloseOpptyAllSubsciptionsRMA();
        Database.executeBatch(batch, 1);
        CloseOpptyWithNoSubsciptions noSubBatch = new CloseOpptyWithNoSubsciptions();
        Database.executeBatch(noSubBatch, 1);
    }
}