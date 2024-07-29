/**
 * @description       : Test Class for NEO_TriggerUtils
 * @author            : Ignacio F.
 * @group             : Neocol
 * @last modified on  : 07-29-2024
 * @last modified by  : Ignacio F.
**/
@isTest
public class NEO_TriggerUtilsTest {
    @testSetup
    static void setup() {
        // Create test data
        Account acc1 = new Account(Name = 'Test Account 1');
        insert acc1;
        
        Account acc2 = new Account(Name = 'Test Account 2');
        insert acc2;
    }

    @isTest
    static void testCheckChangedFields() {
        // Retrieve test data
        Account acc1 = [SELECT Id, Name FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Account acc1Updated = acc1.clone();
        acc1Updated.Name = 'Updated Test Account 1';
        
        Account acc2 = [SELECT Id, Name FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        
        // Test for new record
        Boolean isChanged = NEO_TriggerUtils.checkChangedFields(acc1, null, new List<Schema.SObjectField>{Account.Name});
        System.assertEquals(true, isChanged, 'Expected true when old record is null');

        // Test for unchanged fields
        isChanged = NEO_TriggerUtils.checkChangedFields(acc1, acc1, new List<Schema.SObjectField>{Account.Name});
        System.assertEquals(false, isChanged, 'Expected false when fields are unchanged');

        // Test for changed fields
        isChanged = NEO_TriggerUtils.checkChangedFields(acc1Updated, acc1, new List<Schema.SObjectField>{Account.Name});
        System.assertEquals(true, isChanged, 'Expected true when fields are changed');

        // Test for different records
        isChanged = NEO_TriggerUtils.checkChangedFields(acc1, acc2, new List<Schema.SObjectField>{Account.Name});
        System.assertEquals(true, isChanged, 'Expected true when comparing different records');
    }

    @isTest
    static void testGetRecordFromMap() {
        // Create a map with one record
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Map<Id, SObject> recordsMap = new Map<Id, SObject>{acc1.Id => acc1};
        
        // Test for existing record
        SObject record = NEO_TriggerUtils.getRecordFromMap(recordsMap, acc1.Id);
        System.assertEquals(acc1.Id, record.Id, 'Expected to retrieve existing record from map');
        
        // Test for new record
        Account acc2 = [SELECT Id FROM Account WHERE Name = 'Test Account 2' LIMIT 1];
        record = NEO_TriggerUtils.getRecordFromMap(recordsMap, acc2.Id);
        System.assertEquals(acc2.Id, record.Id, 'Expected to create and retrieve new record in map');
        System.assertEquals(2, recordsMap.size(), 'Expected map size to be 2 after adding new record');
    }
}
