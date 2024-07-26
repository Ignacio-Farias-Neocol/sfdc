global class ScheduleOrderYTDResetBatch implements schedulable{
	global void execute(SchedulableContext sc){
        OrderYTDResetBatch b = new OrderYTDResetBatch();
        database.executebatch(b,200);
    }
}