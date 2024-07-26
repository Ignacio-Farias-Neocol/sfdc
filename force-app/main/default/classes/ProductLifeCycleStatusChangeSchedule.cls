global class ProductLifeCycleStatusChangeSchedule implements schedulable
{
    global void execute(SchedulableContext sc)
    {
        ProductLifeCycleStatusChangeBatch b = new ProductLifeCycleStatusChangeBatch(); 
        database.executebatch(b, 20);
    }
}