@isTest
private  class DynamicValidationOpptyPartnerStageTest {
  
    @TestSetup
    static void setup() {

    Opportunity testOpp = TestDataFactory.opportunities[0];  

  }

  @isTest
  public static void test1(){

   Opportunity testOpp=[Select Id, AccountId,StageName,Bill_To_Account__c from Opportunity];

   System.debug('Billing Account::' + testOpp.Bill_To_Account__c);
   System.debug('StageName::' + testOpp.StageName);

   Contact con=[Select Id from Contact where AccountId =: testOpp.Bill_To_Account__c];

   User u = new User(
        ProfileId = [SELECT Id FROM Profile WHERE Name = 'Barracuda Partner Core Admin'].Id,
        ContactId=con.Id,
        LastName = 'PartnerUser',
        Email = 'PartnerUser.Test@gmail.com.invalid',
        UserName = 'CPQ.PartnerUser.' + DateTime.now().getTime() + '@PartnerUser.Test.com',
        Alias = 'alias',
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US'
      );
   
    insert u;
    
    User uu= [Select Id , Contact.accountId from User where Id=:u.Id] ;

    System.debug('	User:Contact.Account 1::' + uu.Contact.accountId);
    System.runAs(u){

    Test.startTest();
      
    testOpp.Stagename='Discovery';

    Database.SaveResult result = Database.update(testOpp, false);

    Test.stopTest();

    System.debug('result.isSuccess()::' +result.isSuccess());
   
    System.assert(!result.isSuccess());   

    //System.assertEquals('ERROR: Whoops! The opportunity stage cannot be updated from the Community. Please contact the opportunity owner.',
      //                  result.getErrors()[0].getMessage());

    }
  }

    
}