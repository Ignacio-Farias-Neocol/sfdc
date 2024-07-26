/**
* @author         Benjamin Lau    
* @date           01/06/2016
* @description    Unit test class for LogModel
* @group          Test
**/
@IsTest
private class LogModelTest {

    @IsTest
    public static void unitTest_Basic() {

        LogModel log = LogModel.startLog('LogModelTest', 'Unit Test');
        System.assertEquals(null, log.logId);

        log.addErrorLog('Error Message');
        log.addSummaryLog('Summary Message');
        log.addLog('A long.......................................................................................................................................................................................................................................................................... Message'); // long message

        Account acc;
        // acc =  new Account();
        // acc.Name = 'Test Acct';
        // insert acc;
        acc = TestDataFactory.customers[0]; 

        log.addLog('New Account added', acc.Id);

        log.endLog();

        System.assertNotEquals(null, log.logId);

        LogModel.clearLog();

    }

    @IsTest
    public static void unitTest_Exception() {
        LogModel log = LogModel.startLog('ModelTest');
        List <AppLogDetail__c> logDetails1 = [select id from AppLogDetail__c];
        Integer logInitCount1 = logDetails1.size();
        Account a;
        try {
            a = new Account(); // AccountBuilder.buildAccount().get();  // IY: remove depenency of logModel to AccountBuilder
            a.Is_Unit_Test__c = true;
            a.Name = 'test Account';
            insert a;

            a.id = '1111111';
            update a;

        } catch (Exception e){
            System.debug('exception: ' +e);
            log.addExceptionLog(e);
            log.chatterException(e, a.id);
        }
        List <AppLogDetail__c> logDetails2 = [select id from AppLogDetail__c];
        Integer logInitCount2 = logDetails2.size();
        System.debug('log count: ' + logInitCount2);
        LogModel.clearLog(1);

        List <AppLogDetail__c> logDetails3 = [select id from AppLogDetail__c];
        Integer logInitCount3 = logDetails3.size();
        

    }

    @IsTest
    public static void unitTest_Advance() {
        LogModel log = LogModel.startLog('LogModelTest', 'Unit Test',  LogModel.LOG_CATEGORY_INBOUND_WEBSERVICE);
        System.assertEquals(null, log.logId);
        log.addLog('LogModelTest', 'Test Error Message2', LogModel.LOG_TYPE_ERROR) ;
        LogModel.clearLog('LogModelTest');
    }

    @isTest 
    public static void  unitTest_SingleLog(){
        LogModel.singleLog('unitTest Class', 'This is a very long................................................................................................................................................................................................................................................Test Message', LogModel.LOG_CATEGORY_APEX);
        List <AppLogDetail__c> logDetails1 = [select id from AppLogDetail__c];
        Integer logInitCount1 = logDetails1.size();
        System.debug('~~~ log size: ' + logInitCount1 );
        System.assert(logInitCount1 > 0, 'No log added');

    }



}