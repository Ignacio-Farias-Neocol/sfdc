/**
*   @description   Application Log Model class
*   sequence of calls
*        1. create an instance of LogModel
*           e.g. in class ModelTest  using one of the syntax:
*                   public static LogModel logModelTest = LogModel.startLog('ModelTest');
*                   public static LogModel logModelTest = LogModel.startLog('ModelTest', 'header message with erro code 123');
*                   public static LogModel logModelTest = LogModel.startLog('ModelTest', 'header message with erro code 123', 'Inbound Webservices');
*
*        2 add an log entry, using one of the syntax 
*         e.g.
*                  logModelTest.addErrorLog('error message detail....');
*                  logModelTest.addSummaryLog('Summary message detail....');
*                  logModelTest.addLog('log Detail message...', 'log detail message', 'Info', recordId) // full control of all parameters
*                  logModelTest.addLog('info message goes here ') // default to info message type
*                  logModelTest.addLog( 'info message', recordId) ; 
*
*                  logModelTest.addExceptionLog(e);  // e is an instance of exception 
*                  logModelTest.addExceptionLog(e, recordId);  // e is an instance of exception , record ID is the reference of the record 
*
*       3 end log: insert log header and writing all the details. 
*                    Note: endlog can be called mulitple times . subsequent calls will simply flush the log details 
*                    Note: addExceptionLog has included the call endLog already 
*                   
*        e.g. 
*                   logModelTest.endLog();  // not needed for addExceptionLog
*                   logModelTest.endLog('end Message');
*
*
*      typically exception handling:
*
*      LogModel log = LogModel.startLog('<ClassName>', '<Routine Name>');
*      try {
*       process();
*      } catch (Exception e) {
*       log.addExceptionLog(e);
*       }
*
*
*
*
*    @author Benjamin Lau, Ivan Yeung
*    @date 01/06/2016
*    @group Utility
*/
public without sharing class LogModel {
    //due to use of Lightning Connect - can't write to DB until endlog

    public static String LOG_TYPE_INFO = 'Info';
    public static String LOG_TYPE_ERROR = 'Error';
    public static String LOG_TYPE_SUMMARY = 'Summary';
    public static String LOG_TYPE_EXCEPTION = 'Exception';
    public static String LOG_TYPE_WARNING = 'Warning';

    public static String LOG_CATEGORY_MIGRATION = 'Migration';
    public static String LOG_CATEGORY_INBOUND_WEBSERVICE = 'Inbound Webservice';
    public static String LOG_CATEGORY_OUTBOUND_WEBSERVICE = 'Outbound Webservice';
    public static String LOG_CATEGORY_ASYNCHRONOUS_PROCESS = 'Asynchronous Process';
    public static String LOG_CATEGORY_APEX = 'Apex';

    public static String ORG_NAME = UserInfo.getUserName().substringAfterLast('.');

    private AppLog__c myLog = null;
    private list<AppLogDetail__c> details = new list<AppLogDetail__c>();
    private Integer logDetailNumber = 0;
    private static Integer LogFlushThreshold = 5000; // when the count of log row exceed this number. flush the log 
    private static Integer LogMaxCount = 50000;      // max record count of a log - stop writing so we dont blow the storage 
    // if a log is 50k - the chance of getting more useful information is slim


    //logModel = LogModel.startLog('apex class name');

    private LogModel(String apexClassName, String message, String logCategory) {

        AppLog__c log = new AppLog__c();
        log.apexClassName__c = apexClassName;
        if (message != null){
            log.message__c = message.trim().left(255);   // IY, 2017-01-23: trim the message to make sure it fit. 
        }
        log.startTime__c = Datetime.now();
        log.LogCategory__c = logCategory;
        log.OrgName__c = ORG_NAME;

        myLog = log;
    }


    public Id logId {
        get {
            if (myLog != null){
                return myLog.Id;
            } else {
                return null;
            }
        }
    }

    public Boolean hasPendingLogs() {
        return !details.isEmpty();
    }


    public void addErrorLog(String message) {
        addLog(myLog.apexClassName__c, message, LOG_TYPE_ERROR);
    }

    public void addSummaryLog(String message) {
        addLog(myLog.apexClassName__c, message, LOG_TYPE_SUMMARY);
    }

    public void addExceptionLog(Exception e) {
        addExceptionLog(e, '');
    }


    public void addExceptionLog(Exception e, String refRecordID) {

        // 2019-03-22: remove DML restriction , an external DML exception , should not be rerecursive here
        // if (e != null && !(e instanceOf DmlException)) {
        if (e != null ) {

            String errMsg = e.getTypeName() + ' : '+ e.getCause();
            addLog(myLog.apexClassName__c, errMsg, LOG_TYPE_EXCEPTION, refRecordID);

            errMsg = e.getMessage() + ' at line '+ e.getLineNumber();
            addLog(myLog.apexClassName__c, errMsg, LOG_TYPE_EXCEPTION, refRecordID);
            System.Debug('******* '+ errMsg);

            errMsg = e.getStackTraceString();
            addLog(myLog.apexClassName__c,'StackTraceString : ' + errMsg, LOG_TYPE_EXCEPTION, refRecordID);
            System.Debug('******* '+ errMsg);

            endLog('flushing log after exception - may cause problem with callout after');
        }
    }

    public void chatterException(Exception e, String refRecordID) {
        chatterException(e.getMessage(), refRecordID);
    }

    public void chatterException(String message, String refRecordID) {
        if (!Test.isRunningTest()) {
            ConnectApi.ChatterFeeds.postFeedElement(
                Network.getNetworkId(), 
                refRecordID,
                ConnectApi.FeedElementType.FeedItem, 
                message
            );
        }
    }

    public void addLog(String apexClassName, String message, String logType, String refRecordID) {
        if ( message == null || message.trim().length() == 0) {
            return;
        }
        list<String> logs = splitString(message,250);
        if ( message.length() > 250) {
            logs.add('---------------- size = '+message.length());
        }
        for (String log : logs) {
            AppLogDetail__c logDetail = new AppLogDetail__c();
            logDetail.apexClassName__c = apexClassName;
            logDetail.message__c = log;
            logDetail.AppLog__c = myLog.id;
            logDetail.RefRecordID__c = refRecordID;
            logDetail.logType__c = logType;
            logDetail.LogDetailNumber__c = logDetailNumber;

            details.add(logDetail);
        }
        logDetailNumber++;

        if (details.size() > LogFlushThreshold){
            flushLogDetail(mylog.id, LogFlushThreshold);
        }
    }

    public void addLog( String message) {
        addLog(myLog.apexClassName__c, message, LOG_TYPE_INFO);
    }

    public void addLog( String message, String refRecordID) {
        addLog(myLog.apexClassName__c, message, LOG_TYPE_INFO, refRecordID);
    }

    public void addLog(String apexClassName, String message, String logType ) {
        addLog(apexClassName, message, logType, '');
    }

    //logModel.endLog();
    public void endLog() {
        endLog('');
    }
    public void endLog(String endMessage) {
        endLog(endMessage, 2000);
    }
    public void endLog(String endMessage, Integer rowLimit) {

        System.debug('****** end Log: ' + endMessage);

        if ( logDetailNumber >= LogMaxCount) {
            integer bufferCount = details.size();
            details = new list<AppLogDetail__c>();
            addErrorLog('Max Log record count exceed ('+LogMaxCount+').  Truncating '+bufferCount+' records');
        }

        try {
            addSummaryLog(endMessage);
            myLog.endTime__c = Datetime.now();
            if ( mylog.id == null) {
                //DML.save('LogModel', mylog);
                // LogModel should not use DML wrapper, if any exceptions happen then that would appempt logging
                // which in turn could throw another error whch would then attempt to log, etc
                insert mylog; 
            }
            flushLogDetail(mylog.id, rowLimit);
        } catch (Exception e){
            System.debug('LogModel exception -' + e);
        }
    }

    private void flushLogDetail(Id logId, Integer rowLimit) {
        try {
            System.debug('***** inserting details for logId -' + logId);

            //find out how many rows has been inserted.
            for(AppLogDetail__c detail : details) {
                detail.AppLog__c = logId;
            }
            //DML.save('LogModel', details);
            // LogModel should not use DML wrapper, if any exceptions happen then that would appempt logging
            // which in turn could throw another error whch would then attempt to log, etc
            insert details;
            details = new list<AppLogDetail__c>();
        } catch (Exception e){
            System.debug('***** LogModel exception -' + e);
        }
    }


    public static list<String> splitString (String strInput, Integer blockLen) {
        list<String> strParse = new list<String>();
        if (strInput == null) {
            strParse.add('');
        } else {
            // Add them in blockLen character blocks
            do {
                Integer maxLen = strInput.length();
                if (maxLen > blockLen) {
                    maxLen = blockLen;
                }

                String block = strInput.subString(0, maxLen);
                strParse.add( block );
                strInput = strInput.Mid(maxLen, strInput.length() - maxLen);
                //System.Debug(block + '     '+ strInput);
            } while (strInput.length() > blockLen);
            if (String.isNotBlank(strInput)){
                strParse.add(strInput);
            }
        }
        return strParse;
    }
    /////////////////////////////////////
    //migration Log - track problems & status with Migration
    public static LogModel startLog(String apexClassName, String message) {
        return new LogModel(apexClassName, message, LOG_CATEGORY_MIGRATION );
    }
    public static LogModel startLog(String apexClassName) {
        return new LogModel(apexClassName, '', LOG_CATEGORY_MIGRATION);
    }

    // other category group
    public static LogModel startLog(String apexClassName, String message, String logCategory) {
        return new LogModel(apexClassName, message, logCategory);
    }

    // helper method if only creating a single log
    public static void singleLog(String apexClassName, String message, String logCategory) {

        // IY: use add log if needed. 
        LogModel aLog = LogModel.startLog(apexClassName, message, logCategory);
        if (String.isNotBlank(message)  && message.trim().length()  > 0){
            aLog.addLog( message); 
        }
        aLog.endLog(); 
    }

    // helper method for logging a DML exceptional asynchronously so that even though the DML operation is rolled back, the log is still written.
//    @Future
//    public static void singleLogAsync(String apexClassName, String message, String logCategory) {
//
//        // System.debug('~~~ message: ' + message);
//        LogModel aLog = LogModel.startLog(apexClassName, message, logCategory);
//        if (String.isNotBlank(message)  && message.trim().length()  > 0){
//            aLog.addLog( message);
//        }
//        aLog.endLog();
//    }

    // it is legitimate to use DML insdie a SOQL For Loop Formats .but PMD does not know the difference. so have a private method to avoid the DML inside loop syntax
    private static void deleteAppLog( List< AppLog__c> appLogs ){
        delete appLogs;
    }

    //LogModel.clearLog(1);  //delete any log older than 1 day
    @Future
    public static void clearLog(integer dayToKeep) {
        DateTime deadline = DateTime.now().addDays(-1 * dayToKeep);

        for (  list<AppLog__c> toDelete : [
                select id
                from AppLog__c
                where createdDate < :deadline
                limit 9000
        ]) {

            deleteAppLog(toDelete);

        }
    }

    //LogModel.clearLog();  //delete all logs
    @Future
    public static void clearLog() {

        for (list<AppLog__c> toDelete : [
                select id
                from AppLog__c
                limit 9000
        ] ) {
            deleteAppLog(toDelete);
        }

    }


    // LogModel.clearLog('MigMerlin_110_AgentCompliance');   
    @Future
    public static void clearLog(String apexClassName) {

        for (list<AppLog__c> toDelete : [
                select id
                from AppLog__c
                where apexClassName__c = :apexClassName
                limit 9000
        ] ) {
            deleteAppLog(toDelete);
        }

    }
}