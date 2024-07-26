/** 
 * Test methods for ChangeRecordType invocable class
 * 
 * @author Micah Gerger
 * @date 2018/11/06
 * @group Test
 */


@isTest
public class ChangeRecordTypeTests {

    private static final String OBJECT_NAME = 'Account';
    private static final String SOURCE_RECORD_TYPE_DEVELOPER_NAME = 'Customer ';
    private static final String TARGET_RECORD_TYPE_DEVELOPER_NAME = 'Partner';
    
    @isTest
    // test for scenario in which record type is found and updated successfully
    public static void ChangeRecordType_Success(){
        
        // arrange inputs
        ChangeRecordType.Request request = new ChangeRecordType.Request();
        request.objectName = OBJECT_NAME;
        request.developerName = TARGET_RECORD_TYPE_DEVELOPER_NAME;
        request.recordId = getRecordId();
        
        // change the record type
        List<ChangeRecordType.Response> responses = ChangeRecordType.execute(new List<ChangeRecordType.Request> {request});
        
        // assert some results
        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].success);
    }
    
    @isTest
    //test for scenario in which no record type is found and exception must be thrown
    public static void ChangeRecordType_NoRecordTypeFoundException(){
        
        // arrange inputs
        ChangeRecordType.Request request = new ChangeRecordType.Request();
        request.objectName = OBJECT_NAME;
        request.developerName = 'DummyName';
        request.recordId = getRecordId();
        
        // change the record type
        List<ChangeRecordType.Response> responses = ChangeRecordType.execute(new List<ChangeRecordType.Request> {request});
        
        // assert some results
        System.assertEquals(1, responses.size());
        System.assertEquals(false, responses[0].success);
    }
    
    @isTest
    // test for scenario in which no record is found and exception must be thrown
    public static void ChangeRecordType_NoRecordFoundException(){
        
        // arrange inputs
        ChangeRecordType.Request request = new ChangeRecordType.Request();
        request.objectName = OBJECT_NAME;
        request.developerName = TARGET_RECORD_TYPE_DEVELOPER_NAME;
        request.recordId = '100000000000abc';
        
        // change the record type
        List<ChangeRecordType.Response> responses = ChangeRecordType.execute(new List<ChangeRecordType.Request> {request});
        
        // assert some results
        System.assertEquals(1, responses.size());
        System.assertEquals(false, responses[0].success);
    }
    
    private static Id getRecordId(){
        Account account = new Account();
        account.Name = 'Test Acct';
        account.Is_Unit_Test__c = true;
        DML.save(account);
        
        return account.Id;
    }
    
    private static Id getRecordTypeId(String objectName, String developerName){
        return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
    }
}