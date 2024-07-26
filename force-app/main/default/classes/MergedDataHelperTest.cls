/**
 * Created by iyeung on 2019-05-28.
 */

@isTest
public class MergedDataHelperTest {

    @isTest
    static void unitTest()
    {
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        List <Account> accounts = TestDataFactory.customers;
        TriggerHandler.clearAllBypasses();

        MergedDataHelper.reserveDupAccountsExternalID(accounts);
        MergedDataHelper.saveDuplicates(accounts);

    }
    
    @isTest
    static void unitTestUnmerge()
    {
        // Insert new accounts
        List<Account> ls = new List<Account>{
            new Account(name='Acme Inc.'),
                new Account(name='Acme')
                };                                        
                    insert ls;
        
        // Queries to get the inserted accounts 
        Account masterAcct = [SELECT Id, Name FROM Account WHERE Name = 'Acme Inc.' LIMIT 1];
        Account mergeAcct = [SELECT Id, Name FROM Account WHERE Name = 'Acme' LIMIT 1];
        
        try {
            merge masterAcct mergeAcct;
        } catch (DmlException e) {
            // Process exception
            System.debug('An unexpected error has occurred: ' + e.getMessage()); 
        }
        
        // Once the account is merged with the master account,
        // the related contact should be moved to the master record.
        masterAcct = [SELECT Id, Name
                      FROM Account WHERE Name = 'Acme Inc.' LIMIT 1];
        
        // Verify that the merge record got deleted
        Account[] result = [SELECT Id, Name FROM Account WHERE Id=:mergeAcct.Id];
        System.assertEquals(0, result.size());
        
        undelete mergeAcct;
		Account[] resultafterUndelete = [SELECT Id, Name FROM Account WHERE Id=:mergeAcct.Id];
        System.assertEquals(1, resultafterUndelete.size());
    }
}