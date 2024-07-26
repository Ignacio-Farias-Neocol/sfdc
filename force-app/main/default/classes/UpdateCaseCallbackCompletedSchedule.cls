global class UpdateCaseCallbackCompletedSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        SearchAndReplace batch = new SearchAndReplace(); 
        batch.query = 'Select Id, Callback_Completed__c from Case where Callback_Completed__c = false and Callback_Date__c < YESTERDAY and DAY_ONLY(CreatedDate) >= 2022-05-09';
        batch.fieldType = 'BOOLEAN';
        batch.Entity = 'Case';
        batch.Value = 'true';
        batch.Field = 'Callback_Completed__c';
        database.executebatch(batch);
    }
}