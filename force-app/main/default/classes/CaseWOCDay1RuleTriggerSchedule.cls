global class CaseWOCDay1RuleTriggerSchedule implements schedulable
{
    global void execute(SchedulableContext sc)
    {
        CaseWOCDay1RuleTriggerBatch b = new CaseWOCDay1RuleTriggerBatch(); 
        database.executebatch(b,1);
    }
}