public with sharing class AccountInfoController {

	public class ReturnValues {
    	public Integer status;
      	public String account_id;
    	public String bos_account_id;
    	public String message;
	}

	@AuraEnabled
    public static Account getAccountInfo(String id)
    {
        Account acc = [SELECT 
        				Name,
						Bill_To_Contact__c,
						Ship_To_Contact__c,
						ShippingStreet,
						ShippingCity,
						ShippingState,
						ShippingCountry,
						ShippingStateCode,
						ShippingPostalCode,
						ShippingCountryCode,
						BillingStreet,
						BillingCity,
						BillingState,
						BillingCountry,
						BillingStateCode,
						BillingPostalCode,
						BillingCountryCode,
						Bill_To_Email__c,
						Ship_To_Email__c,
						Id,
						Phone,
						Type,
						VAT_Number__c,
						Tax_Exempt_Number__c,
						Portal_Account_ID__c,
						Partner_Number__c,
						Account_Status__c,
						Payment_Terms__c,
						Strategic_Partner_Type__c
        FROM Account WHERE Id=:id];
        return acc;
       
    }

  	@AuraEnabled
	public static List<Web_Integration_Setting__mdt> getBosUrl()
	{
    	List<Web_Integration_Setting__mdt> bosSetting = [SELECT DeveloperName, Base_URL__c,Parameter1_Value__c,Parameter2_Value__c FROM Web_Integration_Setting__mdt 
                                                            WHERE QualifiedApiName = 'BOS_Partner_Account'];
    	return bosSetting;
	}

	@AuraEnabled
  	public static void updateSharedPartnerAccount(String accountId, String responseJson){

      Account acct = [SELECT Id, BOS_Account_Id__c, Shared_Partner_Account__c FROM Account WHERE Id=:accountId];

      withoutSharingDML.save(AccountInfoController.prepareAccountForUpdate(acct, responseJson), 'AccountInfoController');
    }

	//SFDC-8118 - Added this method to update multiple accounts
  	public static void updateSharedPartnerAccount(Map<Id, String> bosResponses){

		List<Account> acctsToBeUpdated = new List<Account>();

		//Get account info for the accts sent to BOS
		for(Account acct: [Select Id, 
								  BOS_Account_Id__c, 
								  Shared_Partner_Account__c 
						   From Account 
						   Where Id in :bosResponses.keyset()]){

			//Add acct to the list used for update
			acctsToBeUpdated.add(AccountInfoController.prepareAccountForUpdate(acct, bosResponses.get(acct.Id)));		
		}  

		//Update accounts
		if(acctsToBeUpdated!=null && !acctsToBeUpdated.isEmpty()){
			withoutSharingDML.save(acctsToBeUpdated, false, 'AccountInfoController');
		}
		
    }

	//SFDC-8118 Helper method to prepare account for update
	private static Account prepareAccountForUpdate(Account acct, String responseJson){
		
		ReturnValues rv = (ReturnValues)JSON.deserializeStrict(responseJson, ReturnValues.class);

		if(String.isNotBlank(rv.bos_account_id)){
			acct.BOS_Account_Id__c = rv.bos_account_id;
		}
			
		if(rv.status == 1){
			acct.Shared_Partner_Account__c = true;
		} 
			
		if(rv.status == 0) {
			LogModel logModel = LogModel.startLog('AccountInfoController',
													'Container for Partner Account Information Shared with BOS',
													LogModel.LOG_TYPE_ERROR);
			logModel.addLog(rv.message, acct.Id);
			System.debug(rv.message);
			logModel.endLog();
		}

		return acct;		
	}

}