@IsTest
public class FieldUpdateBatchTest {

    final static String OLD_ACCOUNT_NAME = 'Original Account Name';
    final static String NEW_ACCOUNT_NAME = 'Updated Account Name';

    static Map<SObjectField, Object> fieldValueMap = new Map<SObjectField, Object>{
        Account.Name => NEW_ACCOUNT_NAME
    };

    static List<String> conditionsList = new List<String>{
        'Name = \'' + OLD_ACCOUNT_NAME + '\'',
        'CreatedDate = TODAY'
    };

    @TestSetup
    static void makeData(){
        insert new Account(Name = 'Original Account Name');
    }

    @IsTest
    static void testQueryBuilder(){

        FieldUpdateBatch.QueryBuilder query = new FieldUpdateBatch.QueryBuilder(
            Account.getSObjectType(),
            fieldValueMap.keySet(),
            conditionsList,
            10
        );

        final String EXPECT_QUERY_STRING = 'SELECT Name FROM Account WHERE Name = \'' + OLD_ACCOUNT_NAME +'\' AND CreatedDate = TODAY LIMIT 10';

        Assert.areEqual(EXPECT_QUERY_STRING, query.getQuery(), 'Query string does not match');

        try {
            Database.query(query.getQuery());
        } catch(Exception ex) {
            Assert.isTrue(false, ex.getMessage());
        }
    }

    @IsTest
    static void testBatch(){

        Test.startTest();
        FieldUpdateBatch batch = new FieldUpdateBatch(fieldValueMap, conditionsList); 
        Database.executeBatch(batch);
        Test.stopTest();

        Account account = [SELECT Id, Name FROM Account WHERE Name IN (:OLD_ACCOUNT_NAME, :NEW_ACCOUNT_NAME) LIMIT 1];
        Assert.areEqual(NEW_ACCOUNT_NAME, account.Name, 'Account Name was not updated');
    }

    @IsTest
    static void testIgnoreParentContractedPricing(){
        
        Test.startTest();
        IgnoreParentContractedPricingBatch batch = new IgnoreParentContractedPricingBatch();
        Test.stopTest();

        Assert.isNotNull(batch.query);
    }
}