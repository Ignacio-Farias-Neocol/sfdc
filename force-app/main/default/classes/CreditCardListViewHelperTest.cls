@isTest
public with sharing class CreditCardListViewHelperTest {

	public static User testUser;
	public static Contract testContract;
	public static Opportunity testOppt;
	public static Account testAcc;
	public static Contact testContact;
	//Test data set up
  @testSetup static void setup() {

		//Account
		Account testAcc = new Account();
		testAcc.Is_Unit_Test__c  = true;
		testAcc.Name = 'Customer';
		testAcc.billingStreet = '415 Mission Street';
		testAcc.billingCity = 'San Francisco';
		testAcc.BillingCountryCode = 'US';
		testAcc.billingStateCode = 'CA';
		testAcc.billingPostalCode = '94105'; 
		testAcc.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
		testAcc.Status__c = 'Active';
		testAcc.Territory_ID__c = '123';
		testAcc.AccountSource = 'Renewal';
		testAcc.Terr_Theater__c = 'APAC';

		insert testAcc;
		
		testContact = new Contact();
		testContact.LastName = 'Doe';
		testContact.FirstName = 'Mary';
		testContact.Email = 'Mary.Doe@test.com.Distributor';
		testContact.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
		testContact.AccountId = testAcc.Id;
		testContact.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
		testContact.LeadSource = 'Renewal';

		insert testContact;

		Credit_Card__c cc1 = new Credit_Card__c();
		cc1.Account__c = testAcc.Id;
		cc1.Last_4_of_CC__c = '1234';
		cc1.Card_Type__c = 	Credit_Card__c.Card_Type__c.getDescribe().getPicklistValues()[0].getValue();
		cc1.Expiration__c = '01/23';

		insert cc1;

		Country__c testCountry = new Country__c(Name = 'TEST_COUNTRY');
    insert testCountry;

    State__c testState = new State__c(Name = 'TEST_STATE',
                                      Country__c = testCountry.Id
                                     );
    insert testState;

		Id testContactId = testContact.Id;
	
		User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ]; 
		System.runAs ( thisUser ) {  
					//User
			testUser = new User(
				ProfileId = [SELECT Id FROM Profile WHERE Name = 'Barracuda Partner Core'].Id,
				LastName = 'last',
				Email = 'puser000@barracuda.com', // required domain for user barracuda.com, barracudamsp.com
				Username = 'puser000@barracuda.com' + System.currentTimeMillis(),
				CompanyName = 'TEST',
				Title = 'title',
				Alias = 'alias',
				TimeZoneSidKey = 'America/Los_Angeles',
				EmailEncodingKey = 'UTF-8',
				LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US'
				);
			testUser.ContactId = testContactId;
			insert testUser;
		}
  }

	@isTest static void test_shouldGetCreditCards() {

		User user = [SELECT Id from User WHERE email = 'puser000@barracuda.com'];

		CreditCardListViewHelper.CreditCardsAddressDetail ccAddressDetail = CreditCardListViewHelper.getCreditCards(user.Id);

		System.assertEquals(1, ccAddressDetail.creditCards.size());
		System.assertEquals('415 Mission Street', ccAddressDetail.address.street);
	}
}