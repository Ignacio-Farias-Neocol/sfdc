global class WebMessageCleanUpScheduler implements schedulable {

    global void execute(SchedulableContext sc){
        String query='Select Id, Status from Case where RecordType.DeveloperName=\'Web_Case\' AND Status IN (\'New\',\'Waiting for Customer\',\'Waiting for Customer Response\') AND createddate<:beforeForteenDays';
        CaseClosureBatch caseClouser=new CaseClosureBatch(query);
        Database.executeBatch(caseClouser,200);
    }
}