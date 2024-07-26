@isTest
private class DynamicValidationUpSellOpptyCheckTest {


@isTest static void upSellAmendOppExists()  
{

 Account testAccount = new Account();
 testAccount.Name='Test';
 insert testAccount;
 
 
 Contact testContact=new Contact();
 testContact.AccountId=testAccount.Id;
 testContact.LastName='Test Contact';
 testContact.Email='testcontact@gmail.com.invalid';
 insert testContact;
 
  Hot_List__c testHotList=new Hot_List__c();
  testHotList.Contact__c=testContact.Id;
  insert testHotList;
  
 Contract testContract=new Contract();
 testContract.status='Draft';
 testContract.StartDate=Date.today();
 testContract.ContractTerm=12;
 testContract.AccountId=testAccount.Id;
 testContract.Most_Recent_Upsell_Hot_List__c=testHotList.Id;
 insert testContract;
  
  Opportunity testOpp = TestDataFactory.createOpportunity(testAccount);
  
 
  insert testOpp;
  
  testOpp.Hot_List__c=testHotList.Id;
  testOpp.SBQQ__AmendedContract__c=testContract.Id;
 
  List<Opportunity> opps=new List<Opportunity>() ;
  opps.add(testOpp);

  
  Test.startTest();
  Database.SaveResult[] result = Database.update(opps, false);
 
  Test.stopTest();
  for (Database.SaveResult sr : result ) {
   System.assert(sr.isSuccess());
     System.assert(sr.getErrors().size() == 0);
    //  System.assertEquals('ERROR: An Upsell Opportunity has already been created from this Hot List. Please Upsell a different Hot list to the Contract and try again.',
          //                   sr.getErrors()[0].getMessage());
  }
 
  

}

@isTest static void upSellRenewalOppExists()
{

 Account testAccount = new Account();
 testAccount.Name='Test';
 insert testAccount;
 
 
 Contact testContact=new Contact();
 testContact.AccountId=testAccount.Id;
 testContact.LastName='Test Contact';
 testContact.Email='testcontact@gmail.com.invalid';
 insert testContact;
 
  Hot_List__c testHotList=new Hot_List__c();
  testHotList.Contact__c=testContact.Id;
  insert testHotList;
  
 Contract testContract=new Contract();
 testContract.status='Draft';
 testContract.StartDate=Date.today();
 testContract.ContractTerm=12;
 testContract.AccountId=testAccount.Id;
 testContract.Most_Recent_Upsell_Hot_List__c=testHotList.Id;
 insert testContract;
  
  Opportunity testOpp = TestDataFactory.createOpportunity(testAccount);
  
 
  insert testOpp;
  
  testOpp.Hot_List__c=testHotList.Id;
  testOpp.SBQQ__RenewedContract__c=testContract.Id;
 
  List<Opportunity> opps=new List<Opportunity>() ;
  opps.add(testOpp);

  
  Test.startTest();
  Database.SaveResult[] result = Database.update(opps, false);
 
  Test.stopTest();
  for (Database.SaveResult sr : result ) {
   System.assert(sr.isSuccess());
     System.assert(sr.getErrors().size() == 0);
     // System.assertEquals('ERROR: An Upsell Opportunity has already been created from this Hot List. Please Upsell a different Hot list to the Contract and try again.',
                         //    sr.getErrors()[0].getMessage());
  }//

}

}