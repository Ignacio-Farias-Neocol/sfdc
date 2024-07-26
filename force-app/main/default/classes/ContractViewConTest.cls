/**
 * @author            : BJHA
 * @group             : BarracudaCore
 * @last modified on  : 09-17-2020
 * @last modified by  : BJHA
**/
@isTest
public with sharing class ContractViewConTest {

    @TestSetup static void makeData(){

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');

        Profile pf= [Select Id from profile where Name='Barracuda Partner Core Admin']; 
        
        String orgId=UserInfo.getOrganizationId(); 
        String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
        Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName=RandomId+orgId+dateString; 

        User usr = [Select id from User where Id = :UserInfo.getUserId()];

        List <Account> accounts = TestDataFactory.partners;

        Account customerAccount = TestDataFactory.customers[0];
		
        Contact customerContact = new Contact(Email='test@test.com',LastName ='testCon',AccountId = customerAccount.Id);
        insert customerContact;

        System.RunAs(usr){

            Test.startTest();

            User user = new User(alias = 'TestUser', email='test123@test.com',
                    emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                    localesidkey='en_US', profileid = pf.id, country='United States',IsActive =true,
                    ContactId = customerContact.Id,
                    timezonesidkey='America/Los_Angeles', username=uniqueName+'tester@123.com');
            insert user;

            Test.stopTest();

        }

		System.debug('acc id...'+customerAccount.id);
        Contract testContract = new Contract(AccountId = customerAccount.id, Business_Group__c = 'Core', StartDate = System.Today().addDays(-10),EndDate=System.Today().addDays(-10),ContractTerm = 1);
        insert testContract;

        Asset testAsset = TestDataFactory.assets[0];
        testAsset.Appliance_Line_Type__c = 'Hardware only (pool)';
        update testAsset;

        List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__RootId__c = testAsset.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), SBCF_Serial_Number__c = '123'),
            new SBQQ__Subscription__c(SBQQ__RootId__c = testAsset.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), SBCF_Serial_Number__c = '321', Cuda_Subscription_Type__c = '321')
        }; 
        insert testSubs;


        TriggerHandler.clearAllBypasses();
    }
    
    @isTest public  static void unitTest() {
        User partnerUser = [Select id from User Where alias = 'TestUser' LIMIT 1];
        System.RunAs(partnerUser){
        Test.startTest();
        ContractViewCon.getContractList();
        ContractViewCon.prepareSerialReport(JSON.serialize(ContractViewCon.getContractList()));
        Test.stopTest();
        }
    }
}