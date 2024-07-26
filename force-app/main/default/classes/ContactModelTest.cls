@isTest
public class ContactModelTest {
	
    @isTest
    static void testMethod01(){
        Account acc = new Account();
        acc.Name = 'test acc';
        insert acc;
        
        Account acc2 = new Account();
        acc2.Name = 'test acc new';
        insert acc2;        
        
        Contact con = new Contact();
        con.LastName = 'test';
        con.AccountId = acc.Id;
        insert con;
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = acc2.Id;
        acr.ContactId = con.Id;
        insert acr;
        
        con.Security_Notice_Contact__c = true;
        update con;
        
        List<Account> accList = [Select Id, Security_Notice_Contact_Provided__c from Account];
        System.assert(true, accList[0].Security_Notice_Contact_Provided__c);
    }
}