global class CaseWOCDay5RuleTriggerSchedule implements schedulable
{
    global void execute(SchedulableContext sc)
    {
        CaseWOCDay5RuleTriggerBatch b = new CaseWOCDay5RuleTriggerBatch(); 
        database.executebatch(b,1);
    }
}