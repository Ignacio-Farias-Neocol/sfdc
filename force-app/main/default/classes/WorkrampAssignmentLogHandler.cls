public class WorkrampAssignmentLogHandler {
    String apexClassName;

    public WorkrampAssignmentLogHandler(String apexClassName) {
        this.apexClassName = apexClassName;
    }

    public void logSaveResultErrorMessages(Database.SaveResult[] srList) {
        List<WorkRamp_Assignment_Log__c> logs = new List<WorkRamp_Assignment_Log__c>();
        List<WorkRamp_Assignment_Log__c> saveResultAssnLogs;
        for (Database.SaveResult sr : srList) {
            saveResultAssnLogs = getAssnLogsFromSaveResult(sr);
            logs.addAll(saveResultAssnLogs);
        }

        writeLogsToObject(logs);
    }

    /**
        Given a list of error message strings,
        builds a list of WorkRamp_Assignment_Log
        objects and bulk inserts them
     */
    public void logErrorMessages(List<String> errorMessages){
        List<WorkRamp_Assignment_Log__c> logs = new List<WorkRamp_Assignment_Log__c>();
        WorkRamp_Assignment_Log__c newLog;
        for (String errorMessage : errorMessages) {
            newLog = buildWRAssignmentLogFromError(errorMessage);
            if (newLog == null) {
                continue;
            }

            logs.add(newLog);
        }

        writeLogsToObject(logs);
    }

    private static void writeLogsToObject(List<WorkRamp_Assignment_Log__c> logs) {
        try {
            insert logs;
        } catch (DmlException e) {
            system.debug('WorkrampAssignmentLogHandler.writeLogsToObject(): error on log insert: ' + e.getMessage());
        }
    }

    /**
        Given an error message, returns
        a WorkRamp_Assignment_Log__c object
     */
    private WorkRamp_Assignment_Log__c buildWRAssignmentLogFromError(String errorMessage) {
        WorkRamp_Assignment_Log__c newLog;
        if (errorMessage == null) {
            return null;
        }

        newLog = new WorkRamp_Assignment_Log__c(
            Message__c = errorMessage,
            Log_Level__c = 'Error',
            Apex_Class__c = apexClassName
        );

        system.debug('logErrorMessgaes(): newLog: ' + newLog);

        return newLog;
    }
    
    private List<WorkRamp_Assignment_Log__c> getAssnLogsFromSaveResult(Database.SaveResult sr){
        List<WorkRamp_Assignment_Log__c> errorLogs = new List<WorkRamp_Assignment_Log__c>();
        if (sr.isSuccess()) {
            return errorLogs;
        }

        WorkRamp_Assignment_Log__c newLog;
        for(Database.Error err : sr.getErrors()) {
            newLog = buildWRAssignmentLogFromError(err.getMessage());
            if (newLog == null) {
                continue;
            }

            errorLogs.add(newLog);
        }
    
        return errorLogs;
    }
}