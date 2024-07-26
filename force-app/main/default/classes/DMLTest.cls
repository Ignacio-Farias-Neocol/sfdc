/**
* Wrapper class to automate the logging of DML statements (errors only)
*
* @Author Scott Will
* @Date 2015/09/15
* @group Test
*/
@IsTest(SeeAllData=false)
private class DMLTest {

    static final String acctName = 'Account Name';
    static final String acctName2 = 'Account Name 2';
    static final String acctRecordName = 'Customer';
    

    static testMethod void test_All() {

        Account acct = new Account(); // AccountBuilder.buildAccount().withName(acctName).get();
        acct.Is_Unit_Test__c = true;
        acct.Name = acctName; 
        acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(acctRecordName).getRecordTypeId();  // avoid speicifc logic for default account type

        DML.deferLogs();

        // insert test
        DML.save(acct);


        // assert that record has been saved
        acct = [select Name from Account where Id = :acct.Id];
        System.assertEquals(acctName, acct.Name);

        // update test
        acct.Name = acctName2;
        DML.save(acct);

        // assert that name has been updated
        acct = [select Name from Account where Id = :acct.Id];
        System.assertEquals(acctName2, acct.Name);

        // delete test
        DML.remove(acct);

        // assert that record has been deleted
        List<Account> accts = [select Id from Account where Id = :acct.Id];
        System.assert(accts.isEmpty());

        // undelete test
        DML.restore(acct);

        // assert that record is restored
        accts = [select Id from Account where Id = :acct.Id];
        System.assert(!accts.isEmpty());

        // delete test again,
        DML.remove(acct, true);

        // assert that record has been deleted
        List<Account> accts2 = [select Id from Account where Id = :acct.Id];
        System.assert(accts2.isEmpty());

        // undelete test again
        DML.restore(acct, true);

        // assert that record is restored
        accts = [select Id from Account where Id = :acct.Id];
        System.assert(!accts.isEmpty());

        // add a dummy log to flush
        DML.log('apexClassName', 'message', null);
        DML.flushLogs();

    }

    static testMethod void test_All2() {

        Account acct =   new Account(); // AccountBuilder.buildAccount().withName(acctName).get();
        acct.Is_Unit_Test__c = true;
        acct.Name = acctName;
        acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(acctRecordName).getRecordTypeId();  // avoid speicifc logic for default account type

        // insert test
        DML.save(new List<Account> { acct });

        // assert that record has been saved
        acct = [select Name from Account where Id = :acct.Id];
        System.assertEquals(acctName, acct.Name);

        // update test
        acct.Name = acctName2;
        DML.save(new List<Account> { acct });

        // assert that name has been updated
        acct = [select Name from Account where Id = :acct.Id];
        System.assertEquals(acctName2, acct.Name);

        // delete test
        DML.remove(new List<Account> { acct });

        // assert that record has been deleted
        List<Account> accts = [select Id from Account where Id = :acct.Id];
        System.assert(accts.isEmpty());

        // undelete test
        DML.restore(new List<Account> { acct });

        // assert that record is restored
        accts = [select Id from Account where Id = :acct.Id];
        System.assert(!accts.isEmpty());

        DML.evaluateResult(null);
        DML.evaluateResults(new List<Object>());

    }

    /*static testMethod void test_Insert_Bad_AllowException() {

        // purposely omit requried field like name
        Account acct = new Account(); // AccountBuilder.buildAccount().get();
        acct.Is_Unit_Test__c = true;

        try {

            DML.save(acct);
            System.assert(false); //this proves that it is unreachable
        }
        catch(System.DmlException de) {
            System.assert(true);
        }

    }*/

    static testMethod void test_Insert_Bad_SuppressException() {

        Account acct = new Account(); // AccountBuilder.buildAccount().get();
        acct.Is_Unit_Test__c = true;
        acct.Name = acctName;
        acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(acctRecordName).getRecordTypeId();  // avoid speicifc logic for default account type

        try {

            DML.save(acct);
            System.assert(true);
        }
        catch(System.DmlException de) {
            System.assert(false);
        }

    }

    /*static testMethod void test_Update_Bad_AllowException() {

        Account acct = new Account(); // AccountBuilder.buildAccount().withName(acctName).get();
        acct.Is_Unit_Test__c = true;
        acct.Name = acctName;
        acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(acctRecordName).getRecordTypeId();  // avoid speicifc logic for default account type

        DML.save(acct, true);

        try {

            acct.Name = ''; // required field

            DML.save(acct, true); // true flag allows exception
            System.assert(false); //this proves that it is unreachable
        }
        catch(System.DmlException de) {
            System.assert(true);
        }

    }*/

   /* static testMethod void test_Update_Bad_SuppressException() {

        Account acct = new Account(); // AccountBuilder.buildAccount().withName(acctName).get();
        acct.Name = acctName;
        acct.Is_Unit_Test__c = true;
        acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(acctRecordName).getRecordTypeId();  // avoid speicifc logic for default account type

        DML.save(acct, true);

        try {

            acct.Name = ''; // required field

            DML.save(acct, false); // false flag supresses exception
            System.assert(true);
        }
        catch(System.DmlException de) {
            System.assert(false);
        }

    }*/

}