@isTest
public with sharing class UpdateCommContactOnUserDisabledTest {

@testSetup
    static void setup() {

       Account testAccountC = new Account();
        testAccountC.Name='Customer Test';
        testAccountC.Type='Customer';
        testAccountC.recordTypeId  = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        insert testAccountC;
        
        Contract testContractC=new Contract();
        testContractC.StartDate=Date.today();
        testContractC.ContractTerm=12;
        testContractC.AccountId=testAccountC.Id;
        testContractC.Status='Draft';
        insert testContractC;
        
        Contact commCont=new Contact();
        commCont.Contact_Status__c='Active';
        commCont.AccountId=testAccountC.Id;
        commCont.firstName ='Test Contact FName';
        commCont.LastName='Test Contact LName';
        commCont.Email='testcontact@gmail.com.invalid';
        insert commCont;
        
        User commUser= new User();
        commUser.username = 'testcontact@gmail.com.invalidtest';
        commUser.firstName = commCont.firstName;
        commUser.lastName = commCont.lastName;
        commUser.email= commCont.email;
        String alias =  commCont.firstName + commCont.lastName;
         if(alias.length() > 8) {
                  alias = alias.substring(0, 8);
             }
             commUser.alias = alias;
             commUser.emailEncodingKey = 'UTF-8';
             commUser.languagelocalekey='en_US';
             commUser.localeSidKey='en_US';
             commUser.isactive=true;
             commUser.communityNickname=commCont.firstName + commCont.lastName;
             commUser.currencyIsoCode='USD';
             commUser.profileId='00ef20000025A2w';  //00e5x000001nrE4AAI
             commUser.timeZoneSidKey ='America/Los_Angeles';
             
             insert commUser;
 
}

 @isTest static void isCommUserDisabled() {

  contact c=[select email from Contact];
  User u=[select Id from User where username='testcontact@gmail.com.invalidtest' limit 1];
        
    Test.startTest();
    Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
      User u2 = new User(Alias = 'newUser', Email='newusertest@testorg.com',
         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
         LocaleSidKey='en_US', ProfileId = p.Id,
         TimeZoneSidKey='America/Los_Angeles', UserName='newuser@testorgtest.com');
         System.runAs(u2) {
                  u.IsPortalEnabled=false;
                  update u;
                  Test.stopTest();
                          }
                          
 Contact con=[Select id,name , Community_Enabled__c from Contact limit 1];
 System.assertEquals(con.Community_Enabled__c, null);
    

}

}