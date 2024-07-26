@isTest
public with sharing class CPQAmendControllerTest { 
    @testSetup
    static void setup() {
      TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
  
        Account customerAccount = TestDataFactory.customers[0];
        Opportunity testOpp = TestDataFactory.opportunities[0];
        SBQQ__Quote__c testQuote = TestDataFactory.quotes[0];

        // testQuote.SBQQ__Primary__c=true;
        // testQuote.SBQQ__Status__c='Approved';
        // testQuote.ApprovalStatus__c='Approved';
        // update  testQuote;

        // testOpp.StageName='Closed Won';
        // update testOpp;
  
       Contract testContract = new Contract(AccountId = customerAccount.id, Business_Group__c = 'Core',
       StartDate = System.Today().addDays(-10),ContractTerm = 1
       
       );
      insert testContract;

      testContract.SBQQ__RenewalOpportunity__c=testOpp.Id;
      update testContract;

      TriggerHandler.clearAllBypasses(); 
}



@isTest
static void NoCustomPermission(){

    User u = new User(
        ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
        LastName = 'Test',
        Email = 'CPQ.Test@gmail.com.invalid',
        UserName = 'CPQ.Test.' + DateTime.now().getTime() + '@CPQ.Test.com',
        Alias = 'alias',
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US'
      );

    System.runAs(u){
    
    Test.startTest();
  
    Contract testCont = [Select id from Contract  LIMIT 1];
    Opportunity testOp = [Select id from Opportunity  LIMIT 1];

  //  testOp.StageName='Closed Won';
    testOp.Business_Group__c='Core';
    update testOp;
    testCont.SBQQ__RenewalOpportunity__c=testOp.Id;
    update testCont;

    CPQAmendController.CPQAmendResult res=CPQAmendController.checkAmendEligible(testCont.id);

    System.assertEquals(true, res.result);
     
    Test.stopTest();
}
}

// @isTest
// static void checkAmendEligibleTestWithoutPermission(){

//     User u = new User(
//         ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
//         LastName = 'Test',
//         Email = 'CPQ.Test@gmail.com.invalid',
//         UserName = 'CPQ.Test.' + DateTime.now().getTime() + '@CPQ.Test.com',
//         Alias = 'alias',
//         TimeZoneSidKey = 'America/Los_Angeles',
//         EmailEncodingKey = 'UTF-8',
//         LanguageLocaleKey = 'en_US',
//         LocaleSidKey = 'en_US'
//       );
   
//       insert u;
      
//     System.runAs(u){
    
        
//     Test.startTest();
  
//     Contract testCont = [Select id from Contract  LIMIT 1];
//     Opportunity testOp = [Select id from Opportunity  LIMIT 1];

//     testOp.StageName='Closed Won';
//     testOp.Business_Group__c='Core';
//     update testOp;
//     testCont.SBQQ__RenewalOpportunity__c=testOp.Id;
//     update testCont;

//     CPQAmendController.CPQAmendResult res=CPQAmendController.checkAmendEligible(testCont.id);

//     System.assertEquals(false, res.result);
//     System.assertEquals(System.Label.CPQAmend_Renew_Validation, res.message);
     
//     Test.stopTest();
// }
// }


@isTest
static void checkAmendEligibleTestWithPermission(){

  User u = new User(
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
      LastName = 'Test',
      Email = 'CPQ.Test@gmail.com.invalid',
      UserName = 'CPQ.Test.' + DateTime.now().getTime() + '@CPQ.Test.com',
      Alias = 'alias',
      TimeZoneSidKey = 'America/Los_Angeles',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US'
    );
 
    insert u;
    PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'By_Pass_Renewal_and_Amendment_Opp_Validation'];

      PermissionSetAssignment psa = new PermissionSetAssignment(
      AssigneeId = u.Id,
      PermissionSetId = ps.Id
    );
    insert psa;
  System.runAs(u){
  
      
  Test.startTest();

  Contract testCont = [Select id from Contract  LIMIT 1];
  Opportunity testOp = [Select id from Opportunity  LIMIT 1];

  testOp.StageName='Accepted';
  testOp.Business_Group__c='Core';
  update testOp;
  testCont.SBQQ__RenewalOpportunity__c=testOp.Id;
  update testCont;

  CPQAmendController.CPQAmendResult res=CPQAmendController.checkAmendEligible(testCont.id);

  System.assertEquals(true, res.result);
  System.assertEquals('', res.message);
   
  Test.stopTest();
}
}

}