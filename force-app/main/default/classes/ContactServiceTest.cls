@isTest
public  class ContactServiceTest {

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

        String emailString='testcontact@gmail.com.invalid';

        Test.startTest();

        List<Contact> conList=ContactService.getContactsByEmail(emailString);

        Test.stopTest();

        System.assertNotEquals(null, conList);   
        System.assertEquals(conList[0].Account.Name, 'Test Company');

    }
   
}