@isTest
public  class ContactSelectorTest {

    @testSetup
    static void setup() {

        Account testAccount = new Account();
        testAccount.Name = 'Test Company';
        testAccount.Website = 'www.test.com';       
        insert testAccount;

        Contact testContact = new Contact();
        testContact.LastName = 'Test LName';   
        testContact.email='testcontact@gmail.com.invalid';
        testContact.AccountId= testAccount.Id;
        insert testContact;
    }

    @isTest
    static void getContactsByEmailTest() {

        Contact con=[Select id , LastName ,Account.Name from Contact];

        String emailString='testcontact@gmail.com.invalid';

        Test.startTest();

        List<Contact> conList= new ContactSelector.ContactSelectorWithoutSharing().getContactsByEmail(emailString);

        Test.stopTest();

        System.assertNotEquals(null, conList);   
        System.assertEquals(conList[0].Account.Name, 'Test Company');
    }
   
}