global class CaseClosureSchedule implements schedulable
{
    global void execute(SchedulableContext sc)
    {
        CaseClosureBatch b = new CaseClosureBatch(null); 
        database.executebatch(b, 10);
    }
}