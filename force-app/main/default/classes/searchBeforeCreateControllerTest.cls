@isTest
public class searchBeforeCreateControllerTest {

    static MockHttpResponseGenerator mockedHttpResponse = MockHttpResponseGenerator.getDnbSearchApiResponse();

@isTest
private static void getMatchResultsTest(){

  Account testAccount = [SELECT Id, Name, Website FROM Account LIMIT 1];

  Test.setMock(HttpCalloutMock.class, mockedHttpResponse);
  Test.startTest();

  List<Account> res = searchBeforeCreateController.getMatchResults( JSON.serialize(testAccount));

  Test.stopTest();
  System.assertNotEquals(0, res.size());
  System.assertEquals(res[0].D_B_DUNS_Number__c, '123456789');

}

@isTest
private static void getDnBDataBlocksInfoTest(){

  Test.setMock(HttpCalloutMock.class, mockedHttpResponse);

  Test.startTest();
  String  duns = '12345';
  Account acc = searchBeforeCreateController.getDnBDataBlocksInfo(duns);

  Test.stopTest();
  System.assertEquals(acc.Industry, null);

}

    @testSetup
    static void setup() {
        Account testAccount = new Account();
        testAccount.Name = 'Test Company';
        testAccount.Website = 'www.test.com';
        testAccount.billingStreet = '415 Mission Street';
        testAccount.billingCity = 'San Francisco';
        testAccount.billingStateCode = 'CA';
        testAccount.billingPostalCode = '94105';
        testAccount.BillingCountryCode = 'US';
        insert testAccount;

        Account testOrigAccount = new Account();
        testOrigAccount.Name = 'Test Orig Company';
        testOrigAccount.Website = 'www.testOrig.com';
        testOrigAccount.ParentId=testAccount.Id;
        insert testOrigAccount;


        Contact testContact = new Contact();
        testContact.LastName = 'Test LName';
        testContact.email='testcontact@gmail.com.invalid';
        testContact.AccountId= testAccount.Id;
        insert testContact;

        Opportunity testOppty = new Opportunity();
        testOppty.Name='Test Oppty';
        testOppty.AccountId =  testAccount.Id;
        testOppty.Primary_Contact__c=testContact.Id;
        testOppty.StageName='Accepted';
        testOppty.CloseDate=Date.today();

        insert testOppty;

        Lead testLead = new Lead();
        testLead.LastName='Test Lead';
        testLead.LeadSource =  'Account Mapping';
        testLead.email='testleademail@gmail.com.invalid';
        testLead.Company='Test Company';


        insert testLead;
    }

    @isTest
    static void testFindAccountByName() {
        Test.startTest();
        // Uncomment below code.
        Account testAccount = [SELECT Id, Name, Website/*,DNBoptimizer__DNB_D_U_N_S_Number__c,BillingCountryCode*/ FROM Account LIMIT 1];

        // Prepare input in JSON format
        Map<String, String> accountMap = new Map<String, String>{
            'Company' => testAccount.Name,
                //'DNBoptimizer__DNB_D_U_N_S_Number__c' => test.DNBoptimizer__DNB_D_U_N_S_Number__c,
                //'BillingCountryCode' => test.BillingCountryCode,
                'Website' => testAccount.Website
                };
                    String jsonString = JSON.serialize(accountMap);

        // Invoke method
        List<Account> returnedAccounts = searchBeforeCreateController.findAccountByName(jsonString);

        // Asserts
        System.assertNotEquals(null, returnedAccounts, 'Returned Accounts should not be null.');
        System.assertEquals(0, returnedAccounts.size(), 'Size of returnedAccounts should be 0.');
        Test.stopTest();
    }

    @isTest
    static void findAccountSBCByNameTest() {

      // Uncomment below code.
      Account testAccount = [SELECT Id, Name, Website, BillingCountryCode FROM Account LIMIT 1];

      // Prepare input in JSON format
      Map<String, String> accountMap =
        new Map<String, String>{
          'Company' => testAccount.Name,
          'BillingCountryCode' => testAccount.BillingCountryCode,
          'Website' => testAccount.Website
        };
      String jsonString = JSON.serialize(accountMap);

      Test.startTest();
        List<Account> returnedAccounts = searchBeforeCreateController.findAccountSBCByName(jsonString);
      Test.stopTest();

      System.assertNotEquals(null, returnedAccounts, 'Returned Accounts should not be null.');
      System.assertEquals(0, returnedAccounts.size(), 'Size of returnedAccounts should be 0.');

    }

    @isTest
    private static void getCountryListTest(){

      Test.startTest();
      String conList=  searchBeforeCreateController.getCountryList();
      Test.stopTest();

      System.assertNotEquals(null, conList);
    }

    @isTest
    private static void getContactsByEmailTest(){

        string email='testcontact@gmail.com.invalid';

      Test.startTest();
      List<Contact> contactService=  searchBeforeCreateController.getContactsByEmail(email);
      Test.stopTest();

      System.assertNotEquals(null, contactService);
      System.assertEquals('testcontact@gmail.com.invalid', contactService[0].email);
    }

    @isTest
    private static void getOpportunitiesTest(){

      Account testAccount = [SELECT Id, Name, Website FROM Account LIMIT 1];

      Test.startTest();
      List<Opportunity> opptyList=  searchBeforeCreateController.getOpportunities(testAccount.Id);
      Test.stopTest();

      System.assertNotEquals(null, opptyList);
      System.assertEquals(1, opptyList.size());
      System.assertEquals('Test Oppty', opptyList[0].Name);
    }

    @isTest
    private static void convertLeadTest(){

      Lead testLead=[SELECT Id FROM Lead  LIMIT 1];
      Account testAccount = [SELECT Id, Name, Website FROM Account LIMIT 1];
      Account testOrigAccount = [SELECT Id, Name, Website FROM Account where Name='Test Orig Company' LIMIT 1];
      Contact testContact = [SELECT Id, Name, Email,AccountId FROM Contact LIMIT 1];
      Opportunity testOppty = [SELECT Id, Name,AccountId FROM Opportunity LIMIT 1];
      String donotCreateOpp='true';

      String leadId=testLead.Id;
      String account= JSON.serialize(testAccount);

      Test.startTest();
      string res = searchBeforeCreateController.convertLead(leadId, account, JSON.serialize(testOrigAccount), JSON.serialize(testContact), JSON.serialize(testOppty), donotCreateOpp);
      Test.stopTest();
    }

    @isTest
    private static void CreateAccountTest(){

      Account testAccount = new Account();
      testAccount.Name = 'Test Company';
      testAccount.Website = 'www.test.com';

      Account testOrigAccount = [SELECT  Name,ParentId, Website FROM Account where Name='Test Orig Company' LIMIT 1];

      Test.startTest();
      string res = searchBeforeCreateController.CreateAccount( JSON.serialize(testAccount), JSON.serialize(testOrigAccount));
      Test.stopTest();

      System.assertNotEquals(null, testOrigAccount.ParentId);
    }

    @isTest
    private static void CreateAccountParentNullTest(){

      Account testAccount = new Account();
      testAccount.Name = 'Test Company';
      testAccount.Website = 'www.test.com';

      Account testOrigAccount = new Account();
      testOrigAccount.Name = 'Test Orig Company';
      testOrigAccount.Website = 'www.testOrig.com';
      insert testOrigAccount;

      Test.startTest();
      string res = searchBeforeCreateController.CreateAccount( JSON.serialize(testAccount), JSON.serialize(testOrigAccount));
      Test.stopTest();

      System.assertEquals(null, testOrigAccount.ParentId);
    }

    @isTest
    private static void activateSessionPermSetTest(){

      Test.startTest();
      searchBeforeCreateController.activateSessionPermSet();
      Test.stopTest();
    }

    @isTest
    private static void deactivateSessionPermSetTest(){

      Test.startTest();
      searchBeforeCreateController.deactivateSessionPermSet();
      Test.stopTest();
    }

    @isTest
    static void testGetCountryCode(){

      Assert.areEqual('US', searchBeforeCreateController.getIsoCodeByCountryName('United States'));
      Assert.areEqual('CA', searchBeforeCreateController.getIsoCodeByCountryName('Canada'));
      Assert.areEqual(NULL, searchBeforeCreateController.getIsoCodeByCountryName(''));
      Assert.areEqual(NULL, searchBeforeCreateController.getIsoCodeByCountryName(NULL));
      Assert.areEqual(NULL, searchBeforeCreateController.getIsoCodeByCountryName('FAKE COUNTRY NAME'));
    }

    @isTest
    static void testGetStateCode(){

      Assert.areEqual('CO', searchBeforeCreateController.getIsoCodeByStateName('cordoba'));
      Assert.areEqual('CO', searchBeforeCreateController.getIsoCodeByStateName('CORdobA'));
      Assert.areEqual(NULL, searchBeforeCreateController.getIsoCodeByStateName('córdoba'));
      
    }

    @isTest
    private static void getRecordTypeIdTest() {

      Lead testLead = [SELECT Id, Name, RecordType.Name, Website FROM Lead  LIMIT 1];

      Test.startTest();
      searchBeforeCreateController.getRecordTypeId(testLead.Id);
      Test.stopTest();
    }
}