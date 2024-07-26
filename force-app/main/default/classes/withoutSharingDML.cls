/**
* Wrapper class to automate the logging of DML statements (errors only)
*
* @Author Scott Will
* @Date 2015/09/15
* @group Utility
*/
public without sharing class withoutSharingDML {

    //
    // Intended to replace raw insert/update/upsert/delete/undelete DML calls, so that error
    // logging can automatically occur.
    //
    // insert records;   => DML.save(records, [this]); or DML.save(records, ['NameOfStaticClass']);
    // update records;   => DML.save(records, [this]); or DML.save(records, ['NameOfStaticClass']);
    // delete records;   => DML.remove(records, [this]); or DML.remove(records, ['NameOfStaticClass']);
    // undelete records; => DML.restore(records, [this]); or DML.restore(records, ['NameOfStaticClass']);
    //
    // Look at methods below for overloading options.
    //
    // NOTE: Upserts are not supported due to a system limitation, specifically that
    // generic SObjects cannot be used in an upsert call. as a workaround you can use the following:
    //
    // DML.evaluateResults(Database.upsert(records, false), [this]);
    //
    // or
    //
    // try {
    //     DML.evaluateResults(Database.upsert(records), [this]);
    // }
    // catch(System.DmlException de) {
    //     DML.logDmlException(de, [this]);
    // }
    //
    enum CallType { SAVE, REMOVE, RESTORE }

    final static Boolean DEFAULT_ALLORNONE = true;

    // whether or not the logs are immediately committed
    private static Boolean deferLogs = false;
    private static LogModel errorLogs;
    private static LogModel getErrorLogs() {
        if (errorLogs == null) {
            errorLogs = LogModel.startLog('DML', 'DML Exception', LogModel.LOG_CATEGORY_APEX);
        }
        return errorLogs;
    }
    // are there pending logs to be committed?
    public static Boolean hasLogs { get { return getErrorLogs().hasPendingLogs(); }}

    ///////////////////////
    //// LOG DEFERMENT ////
    ///////////////////////
    public static void deferLogs() {
        deferLogs(true);
    }
    public static void deferLogs(Boolean defer) {
        deferLogs = defer;
    }

    public static void log(String apexClassName, String message, String refRecordID) {
        getErrorLogs().addLog(apexClassName, message, LogModel.LOG_TYPE_EXCEPTION, refRecordID);
    }

    public static void flushLogs() {
        flushLogs(deferLogs);
    }

    public static void flushLogs(Boolean deferNext) {
        deferLogs(deferNext);
        if (hasLogs) {
            getErrorLogs().endLog();
            errorLogs = null;
        }
    }

    //////////////////////
    //// Save methods ////
    //////////////////////
    public static Database.SaveResult save(SObject record) {
        return save(record, (Object)null);
    }

    public static Database.SaveResult save(SObject record, Object instance) {
        return save(record, DEFAULT_ALLORNONE, instance);
    }

    public static Database.SaveResult save(SObject record, Boolean allowException) {
        return save(new List<SObject> { record }, allowException, null)[0];
    }

    public static Database.SaveResult save(SObject record, Boolean allowException, Object instance) {
        return save(new List<SObject> { record }, allowException, instance)[0];
    }

    public static List<Database.SaveResult> save(List<SObject> records) {
        return save(records, null);
    }

    public static List<Database.SaveResult> save(List<SObject> records, Object instance) {
        return save(records, DEFAULT_ALLORNONE, instance);
    }

    public static List<Database.SaveResult> save(List<SObject> records, Boolean allOrNone, Object instance) {
        return (List<Database.SaveResult>)call(CallType.SAVE, instance, records, allOrNone);
    }

    ////////////////////////
    //// Remove methods ////
    ////////////////////////
    public static Database.DeleteResult remove(SObject record) {
        return remove(record, (Object)null);
    }

    public static Database.DeleteResult remove(SObject record, Object instance) {
        return remove(record, DEFAULT_ALLORNONE, instance);
    }

    public static Database.DeleteResult remove(SObject record, Boolean allowException) {
        return remove(new List<SObject> { record }, allowException, null)[0];
    }

    public static Database.DeleteResult remove(SObject record, Boolean allowException, Object instance) {
        return remove(new List<SObject> { record }, allowException, instance)[0];
    }

    public static List<Database.DeleteResult> remove(List<SObject> records) {
        return remove(records, null);
    }

    public static List<Database.DeleteResult> remove(List<SObject> records, Object instance) {
        return remove(records, DEFAULT_ALLORNONE, instance);
    }

    public static List<Database.DeleteResult> remove(List<SObject> records, Boolean allOrNone, Object instance) {
        return (List<Database.DeleteResult>)call(CallType.REMOVE, instance, records, allOrNone);
    }


    /////////////////////////
    //// Restore methods ////
    /////////////////////////
    public static Database.UndeleteResult restore(SObject record) {
        return restore(record, (Object)null);
    }

    public static Database.UndeleteResult restore(SObject record, Object instance) {
        return restore(record, DEFAULT_ALLORNONE, instance);
    }

    public static Database.UndeleteResult restore(SObject record, Boolean allowException) {
        return restore(new List<SObject> { record }, allowException, null)[0];
    }

    public static Database.UndeleteResult restore(SObject record, Boolean allowException, Object instance) {
        return restore(new List<SObject> { record }, allowException, instance)[0];
    }

    public static List<Database.UndeleteResult> restore(List<SObject> records) {
        return restore(records, null);
    }

    public static List<Database.UndeleteResult> restore(List<SObject> records, Object instance) {
        return restore(records, DEFAULT_ALLORNONE, instance);
    }

    public static List<Database.UndeleteResult> restore(List<SObject> records, Boolean allOrNone, Object instance) {
        return (List<Database.UndeleteResult>)call(CallType.RESTORE, instance, records, allOrNone);
    }

    ///////////////////////////
    //// Result Evaluation ////
    ///////////////////////////
    public static void evaluateResult(Object result) {
        evaluateResult(result, null);
    }

    public static void evaluateResult(Object result, Object instance) {
        evaluateResults(new List<Object> { result }, instance);
    }

    public static void evaluateResults(List<Object> results) {
        evaluateResults(results, null);
    }

    public static void evaluateResults(List<Object> results, Object instance) {

        String className = getClassName(instance);

        for (Object result : results) {

            List<Database.Error> errMsgs;
            Id recId;

            // grab error details if one occurred.  unfortunately since each type of
            // DML statement returns a different type of result they have to be created
            // separately.
            if (result instanceOf Database.DeleteResult) {
                Database.DeleteResult dr = (Database.DeleteResult)result;
                if (!dr.isSuccess()) {
                    recId = dr.getId();
                    errMsgs = dr.getErrors();
                }
            }
            else if (result instanceOf Database.SaveResult) {
                Database.SaveResult dr = (Database.SaveResult)result;
                if (!dr.isSuccess()) {
                    recId = dr.getId();
                    errMsgs = dr.getErrors();
                }
            }
            else if (result instanceOf Database.UndeleteResult) {
                Database.UndeleteResult dr = (Database.UndeleteResult)result;
                if (!dr.isSuccess()) {
                    recId = dr.getId();
                    errMsgs = dr.getErrors();
                }
            }
            else if (result instanceOf Database.UpsertResult) {
                Database.UpsertResult dr = (Database.UpsertResult)result;
                if (!dr.isSuccess()) {
                    recId = dr.getId();
                    errMsgs = dr.getErrors();
                }
            }

            if (errMsgs != null) {

                for (Database.Error errMsg : errMsgs) {
                    // logger activities
                    log(className, errMsg.getMessage(), recId);
                }
                
            }

        }

    }

    public static void logDmlException(Object instance, System.DmlException de) {

        // retrieve the name of the caller
        String className = getClassName(instance);

        for (Integer i = 0; i < de.getNumDml(); i++) {
            log(className, de.getDmlMessage(i), de.getDmlId(i));
        }

    }

    ////////////////////////
    //// Database Call ////
    ///////////////////////
    private static List<Object> call(CallType type, Object instance, List<SObject> records, Boolean allOrNone) {

        List<Object> results;

        if (records != null && !records.isEmpty()) {

            try {

                if (type == CallType.REMOVE) {
                    results = Database.delete(records, allOrNone);
                }
                else if (type == CallType.RESTORE) {
                    results = Database.undelete(records, allOrNone);
                }
                else if (type == CallType.SAVE) {
                    if (records[0].Id == null) {
                        results = Database.insert(records, allOrNone);
                    }
                    else {
                        results = Database.update(records, allOrNone);
                    }
                }

            }
            catch(System.DmlException de) {

                // log errors
                logDmlException(instance, de);

                // re-throw error for the caller to handle
                throw de;

            }

            // check results
            if (!allOrNone) {
                evaluateResults(results, instance);
            }

        }

        return results;

    }

    private static String getClassName(Object instance) {
        // retrieve the name of the caller
        String className = String.valueOf(instance == null ? '' : instance);
        if (!(instance instanceOf String)) {
            className = className.split(':')[0];
        }
        return className;
    }

}