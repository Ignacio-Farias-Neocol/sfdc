@isTest
public with sharing class OrderListViewHelperTest {
	
	static User testUser;
	static Contract testContract;
	static Opportunity testOppt;
	static Account testAcc;
    //Test data set up
  @testSetup static void setup() {
		//Account
		testAcc = TestDataFactory.customers[0];
		System.debug('Test Account: ' + testAcc);

		testOppt = TestDataFactory.opportunities[0];

		Id testContactId = testOppt.Primary_Contact__c;
		Contact testContact = new Contact();
		testContact.Id = testContactId;
		testContact.AccountId = testAcc.Id;
		update testContact;

		//Quote
		SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
																			SBQQ__Opportunity2__c = testOppt.Id,
																			SBQQ__Primary__c      = true);
		insert testQuote;

		//Order.Contact
		//Order.Contract.Account
		testContract = new Contract(
													AccountId            = testAcc.Id, 
													Business_Group__c    = 'Core', 
													SBQQ__Quote__c       = testQuote.Id, 
													StartDate            = System.today(),
													Reseller__c          = testAcc.Id,
													SBQQ__RenewalTerm__c = 12);
    insert testContract;
		
		Order rec1 = new Order();
		rec1.AccountId = testAcc.Id;
		rec1.Bill_To_Account__c = testAcc.Id;
		rec1.EffectiveDate = Date.today();
		rec1.Order_Fulfillment_date__c = System.today();
		rec1.description = 'Order pass';
		rec1.Status = 'Draft';
		rec1.Type = 'New'; // new order
		rec1.Active_Contract__c = testContract.Id;

		Order rec2 = new Order();
		rec2.AccountId = testAcc.Id;
		rec2.Bill_To_Account__c = testAcc.Id;
		rec2.EffectiveDate = Date.today();
		rec2.Order_Fulfillment_date__c = System.today();
		rec2.description = 'Order pass';
		rec2.Status = 'Draft';
		rec2.Type = 'New'; // new order
		rec2.Active_Contract__c = testContract.Id;

		Order rec3 = new Order();
		rec3.AccountId = testAcc.Id;
		rec3.Bill_To_Account__c = null;
		rec3.EffectiveDate = Date.today();
		rec3.Order_Fulfillment_date__c = System.today();
		rec3.description = 'Order fail';
		rec3.Status = 'Draft';
		rec3.Type = 'New'; // new order
		rec3.Active_Contract__c = testContract.Id;

		Order rec4 = new Order();
		rec4.AccountId = testAcc.Id;
		rec4.Bill_To_Account__c = testAcc.Id;
		rec4.EffectiveDate = Date.newInstance(1960, 2, 17);
		rec4.Order_Fulfillment_date__c = System.today();
		rec4.description = 'Order fail';
		rec4.Status = 'Draft';
		rec4.Type = 'New'; // new order
		rec4.Active_Contract__c = testContract.Id;

		List<Order> orders = new List<Order>{rec1, rec2, rec3, rec4};
		insert orders;

		User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ]; 
		System.runAs ( thisUser ) {  
			//User
			testUser = new User(
				ProfileId = [SELECT Id FROM Profile WHERE Name = 'Barracuda Partner Core'].Id,
				LastName = 'last',
				Email = 'testuser000@barracuda.com', // required domain for user barracuda.com, barracudamsp.com
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

	@isTest static void test_shouldGetOrders() {
        
		//get the account
		Account acc = [Select Id from Account LIMIT 1];

		//Get the inserted order
		List<Order> testOrder = [
															SELECT 
															Id,
															CreatedDate,
															Order_Fulfillment_Date__c,
															PoNumber,
															SBQQ__Quote__r.Name,
															TotalAmount,
															BillToContact.Name,
															Active_Contract__r.Reseller__r.Name,
															End_User_Contact__r.Name
															FROM Order
															WHERE Bill_To_Account__c = :acc.Id
															AND EffectiveDate >= LAST_N_MONTHS:15
														];
		// //Get the test User
		User user = [SELECT Id from User WHERE email = 'testuser000@barracuda.com' LIMIT 1];

		System.assertEquals(2, testOrder.size());
		//Arguments userId, fromDate, toDate (YYYY-MM-DD)
		Date today = Date.today();
		String fromDate = today.year() + '-' + today.month() + '-' + today.day();
		String toDate = today.year() + '-' + today.month() + '-' + (today.day() + 1);

		List<OrderListViewHelper.OrderDetail> orderDetails = OrderListViewHelper.getOrders(user.Id, fromDate, toDate);
		System.assertEquals(3, orderDetails.size());
	}
}