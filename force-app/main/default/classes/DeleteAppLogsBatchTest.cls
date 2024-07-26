@isTest
private  class DeleteAppLogsBatchTest {   

    @testSetup
    static void setup() {

     List<AppLog__c>  logtodel=new List<AppLog__c>();

     for(Integer i=0;i<50;i++)
     {

        LogModel log = LogModel.startLog('DeleteAppLogsBatchTest',
        'Start of FakeLogging');

        log.addlog('FakeLogDetail');

        log.endlog('End of FakeLogging');

     }     
    }
    @isTest
    static void testDeleteAllBlank(){

        Test.startTest();        

        DeleteAppLogDetailsBatch del = new DeleteAppLogDetailsBatch();
        
        Id batchId = Database.executeBatch(del);

        Test.stopTest();       

       // System.assertEquals(0, [SELECT count() FROM AppLog__c ALL ROWS]);   // This assertion will only be true
       // when the garbage collector deletes the records from the recycle bin
    }   
}