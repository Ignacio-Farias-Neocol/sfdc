global class CaseWOCDay2RuleTriggerSchedule implements schedulable
{
    global void execute(SchedulableContext sc)
    {
        CaseWOCDay2RuleTriggerBatch b = new CaseWOCDay2RuleTriggerBatch(); 
        database.executebatch(b,1);
    }
}