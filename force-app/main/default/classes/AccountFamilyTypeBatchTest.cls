@IsTest
public class AccountFamilyTypeBatchTest {
    final static String AGGREGATE_TYPE = 'Not_Transactional';
    final static String MSP_TYPE = 'Partner - MSP';
    final static String RESELLER_TYPE = 'Partner - Reseller';

    final static String HYBRID_PARENT_NAME = 'Parent Hybrid';
    final static String SAME_PARENT_NAME = 'Same Type Parent';
    final static String UNINTERESTING_PARENT_NAME = 'Uninteresting Parent';
    final static String CUSTOMER_PARTNER_PARENT_NAME = 'Customer / Partner';

    final static Map<String, String> VALIDATE_FAMILY_TYPE_MAP = new Map<String, String>{
        HYBRID_PARENT_NAME => MSP_TYPE + ' ; ' + RESELLER_TYPE,
        SAME_PARENT_NAME => RESELLER_TYPE,
        UNINTERESTING_PARENT_NAME => NULL,
        CUSTOMER_PARTNER_PARENT_NAME => RESELLER_TYPE
    };

    @TestSetup
    static void makeData(){
        Id aggregateTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = :AGGREGATE_TYPE LIMIT 1].Id;

        Account hybridParent = new Account(Name = HYBRID_PARENT_NAME, RecordTypeId = aggregateTypeId);
        Account sameParent = new Account(Name = SAME_PARENT_NAME, RecordTypeId = aggregateTypeId);
        Account uninterestingParent = new Account(Name = UNINTERESTING_PARENT_NAME, RecordTypeId = aggregateTypeId);
        Account customerPartnerParent = new Account(Name = CUSTOMER_PARTNER_PARENT_NAME, RecordTypeId = aggregateTypeId);
        insert new List<Account>{ hybridParent, sameParent, uninterestingParent };

        List<Account> childAccounts = new List<Account>{
            new Account(Name = 'Hybrid Child 1', Type = RESELLER_TYPE, ParentId = hybridParent.Id),
            new Account(Name = 'Hybrid Child 2', Type = MSP_TYPE, ParentId = hybridParent.Id),

            new Account(Name = 'Same Type Child 1', Type = RESELLER_TYPE, ParentId = sameParent.Id),
            new Account(Name = 'Same Type Child 2', Type = RESELLER_TYPE, ParentId = sameParent.Id),
            
            new Account(Name = 'Uninteresting', Type = 'MSP - End Cust', ParentId = uninterestingParent.Id),

            new Account(Name = 'Customer / Partner Child 1', Type = RESELLER_TYPE, ParentId = customerPartnerParent.Id),
            new Account(Name = 'Customer / Partner Child 2', Type = 'Customer', ParentId = customerPartnerParent.Id)
        };
        insert childAccounts;
    }

    @IsTest
    static void testBatch(){
        
        Test.startTest();
        AccountFamilyTypeBatch batch = new AccountFamilyTypeBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        List<Account> childAccountList = [SELECT Id, Parent.Name, Family_Types__c FROM Account WHERE ParentId != NULL];
        Assert.areNotEqual(0, childAccountList.size(), 'No results found');
        for(Account childAcount : childAccountList) {
            String parentName = childAcount.Parent.Name;
            Assert.areEqual(VALIDATE_FAMILY_TYPE_MAP.get(parentName), childAcount.Family_Types__c,
                'Incorrect Family Type Found for ' + parentName);
        }
    }
}