@isTest
public with sharing class BCCAccountCreateUtilTest{
  
  @isTest static void unitTest() {

    Test.startTest();

        Account acc=new Account();
        acc.Is_Unit_Test__c = true;
        acc.Name='test';
        acc.Shared_Partner_Account__c = false;
        insert acc;
        
        Contact customerContact = new Contact(Email='test@test.com',LastName ='testCon',AccountId = acc.Id);
        insert customerContact;
        
        acc.Initial_BCC_Admin__c = customerContact.Id;
        update acc;
        
        BCCAccountCreateUtil.BCCAPIRequest request = new BCCAccountCreateUtil.BCCAPIRequest();
        request.oAccount = acc;
        
        
        BCCAccountCreateUtil.publicAccountdetails(new List<BCCAccountCreateUtil.BCCAPIRequest>{request});
        Test.stopTest();
    }
    
    @isTest static void unitTestError() {

    Test.startTest();
        try{
        Account acc=new Account();
        acc.Is_Unit_Test__c = true;
        acc.Name='test';
        acc.Shared_Partner_Account__c = false;
        insert acc;
        
        Contact customerContact = new Contact(Email='test@test.com',LastName ='testCon',AccountId = acc.Id);
        insert customerContact;
                        
        BCCAccountCreateUtil.BCCAPIRequest request = new BCCAccountCreateUtil.BCCAPIRequest();
        //request.oAccount = acc;
                
        BCCAccountCreateUtil.publicAccountdetails(new List<BCCAccountCreateUtil.BCCAPIRequest>{request});
        }catch (Exception E){}
        Test.stopTest();
    }
    }