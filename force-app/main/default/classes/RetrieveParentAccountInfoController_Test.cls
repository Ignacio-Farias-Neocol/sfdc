@isTest
public class RetrieveParentAccountInfoController_Test {
    @isTest
    public static void testGetParentAccount() {
        // Create test data
        Account testAccount = new Account(
            Name = 'Test Account',
            Technical_Alert__c ='just test tech alert',
            Contact_Center_Alert__c ='jst Con Center Alert'    
        );
        insert testAccount;
       
        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            LastName = 'Test Cont',
            Contact_Alert__c= 'just test rec'
        );
        insert testContact;

        Contact result = RetrieveParentAccountInfoController.getParentAccount(testContact.Id);

        System.assertEquals(testContact.Id, result.Id);
    }
}