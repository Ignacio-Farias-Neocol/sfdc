public without sharing class CreditCardListViewHelper {
    
	@AuraEnabled(cacheable=true)
  public static CreditCardsAddressDetail getCreditCards(String userId) {
		User currUser = [
                    SELECT
                    Id,
                    ContactId
                    FROM User 
                    WHERE Id = :userId
                    LIMIT 1];

		String contactId = currUser.ContactId;

		Contact currContact = [
                          SELECT 
                          Id,
                          AccountId
                          FROM Contact
                          WHERE Id = :contactId
                          LIMIT 1
                          ];

		String accountId = currContact.AccountId;

		List<CCDetail> data = new List<CCDetail>();

		List<Credit_Card__c> ccs = [
                                SELECT
																Last_4_of_CC__c,
																Card_Type__c,
																Expiration__c
																FROM Credit_Card__c
																WHERE Credit_Card__c.Account__c = :accountId
															 ];

		//Does not need date filters
		// //Get Year and Month to filter out expired credit cards
		// Date today = System.today();
		// String month = String.valueof(today.month());
		// month = month.leftPad(2, '0');
		// String year = String.valueof(today.year());
		// year = year.substring(2);

		for(Credit_Card__c cc: ccs) {
			CCDetail newCC = new CCDetail();
			newCC.last4OfCC = cc.Last_4_of_CC__c;
			newCC.expiration = cc.Expiration__c;
			newCC.type = cc.Card_Type__c;

			//Do not need date filters
			// String cardMonth = newCC.expiration.substringBefore('/');
			// String cardYear = newCC.expiration.substringAfter('/');

			// if(cardYear < year) {
			// 	continue;
			// } else if ((cardYear == year) && (cardMonth < month)) {
			// 	continue;
			// } else {
			// 	data.add(newCC);
			// }
			data.add(newCC);
		}

		CreditCardsAddressDetail ccAddressDetail = new CreditCardsAddressDetail();
		ccAddressDetail.address = getBillingAddress(accountId);
		ccAddressDetail.creditCards = data;

		return ccAddressDetail;
	}

	@AuraEnabled(cacheable=true)
  public static AddressDetail getBillingAddress(String accountId) {
		Address__c billingAddress = [
                                 SELECT 
																 Street__c,
																 State__r.Name,
																 City__c,
																 Zip_Postal_Code__c,
																 Country__r.Name
																 FROM Address__c
																 WHERE Primary__c = TRUE
																 AND Type__c = 'Billing'
																 AND Account__c = :accountId
																 LIMIT 1
 																 ];

		AddressDetail address = new AddressDetail();
		address.street = billingAddress.Street__c;
		address.state = billingAddress.State__r.Name;
		address.city = billingAddress.City__c;
		address.zip = billingAddress.Zip_Postal_Code__c;
		address.country = billingAddress.Country__r.Name;
		return address;
	}

	public class CreditCardsAddressDetail {
		@AuraEnabled
		public AddressDetail address {get; set;}

		@AuraEnabled
		public List<CCDetail> creditCards {get; set;}
		
		public CreditCardsAddressDetail(){}
	}

	public class AddressDetail {
		
		@AuraEnabled
		public String street {get; set;}

		@AuraEnabled
		public String state {get; set;}

		@AuraEnabled
		public String city {get; set;}

		@AuraEnabled
		public String zip {get; set;}

		@AuraEnabled
		public String country {get; set;}

		public AddressDetail(){}
	}

	public class CCDetail {
		
		@AuraEnabled
		public String last4OfCC {get; set;}

		@AuraEnabled
		public String type {get; set;}

		@AuraEnabled
		public String expiration {get; set;}

		public CCDetail(){}
	}
}