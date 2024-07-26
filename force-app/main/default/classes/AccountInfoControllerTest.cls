@isTest
public with sharing class AccountInfoControllerTest {
	
	@isTest static void unitTest() {

	

        Account acc=new Account();
        acc.Is_Unit_Test__c = true;
        acc.Name='test';
        acc.Shared_Partner_Account__c = false;
        insert acc;

        Account acc2=new Account();
        acc2.Is_Unit_Test__c = true;
        acc2.Name='test2';
        acc2.Shared_Partner_Account__c = false;
        insert acc2;

       
        Test.startTest();
        String acctname = AccountInfoController.getAccountInfo(acc.id).name;
        System.assertEquals('test', acctname);

        String apiName = AccountInfoController.getBosUrl()[0].DeveloperName;
        System.assertEquals('BOS_Partner_Account', apiName);

        String result = '{"status":1,"bos_account_id":null,"message":"Success"}';
        AccountInfoController.updateSharedPartnerAccount(acc.id, result);
        Account a = [Select Id, Shared_Partner_Account__c From Account Where Id =: acc.id];
        System.assert(a.Shared_Partner_Account__c);

        String result2 = '{"status":0,"bos_account_id":null,"message":"Error"}';
        AccountInfoController.updateSharedPartnerAccount(acc.id, result2);
        Account a2 = [Select Id, Shared_Partner_Account__c From Account Where Id =: acc2.id];
        System.assert(!a2.Shared_Partner_Account__c);
        
        Map<Id,String> AccStringMap =new Map<Id,String>();
        AccStringMap.put(acc.id,result2);
        AccountInfoController.updateSharedPartnerAccount(AccStringMap);
        Test.stopTest();

    }
}