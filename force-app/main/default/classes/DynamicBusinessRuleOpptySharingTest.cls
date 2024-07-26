@isTest
private class DynamicBusinessRuleOpptySharingTest {

    @TestSetup
    private static void testDataSetup(){
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); 
        Profile pf = [Select id,name from Profile where name ='Barracuda Partner Core Admin' limit 1];
        User usr = [Select id from User where Id = :UserInfo.getUserId()];
        
        Account act = new Account(
            Name = 'Dummy Account'   
            );
   
        Database.insert(act);

        Contact c = new Contact(
            FirstName = 'Test',
            Lastname = 'Test1',
            AccountId = act.Id,
            Email = 'testemailcuda@barracuda.com.invalid'
           );
        Database.insert(c);

        System.runAs(usr){
           
        User portalAccountOwner = new User(        
            ProfileId = pf.Id,
            Username = 'testxyz@gmail.com' + System.now().millisecond() ,
            Alias = 'testxyz',
            Email='testxyz@gmail.com',
            EmailEncodingKey='UTF-8',
            Firstname='Dummy',
            Lastname='Test',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago',
            ContactId = c.Id
            );
            Database.insert(portalAccountOwner);
           }
           TriggerHandler.clearAllBypasses(); 
    }   

    @IsTest
    static void DistributorResellerNotBlank(){

        Test.startTest();
          
        Account dist = TestDataFactory.partnersDistributor[0];
        Account act = [Select id from Account limit 1];
        Opportunity opp = TestDataFactory.createOpportunity(act);
      
        insert opp;     

        opp.Distributor__c=dist.Id;
        opp.Reseller__c =act.Id;

        update opp;

        Test.stopTest();
    }

    @IsTest
    static void DistributorNotBlankResellerBlank(){
   
      Test.startTest();

       Account dist = TestDataFactory.partnersDistributor[0];
       Account act = [Select id from Account limit 1];
       Opportunity opp = TestDataFactory.createOpportunity(act);
       opp.Distributor__c=dist.Id;
       opp.Reseller__c =act.Id;
       insert opp;     

       opp.Reseller__c=null;

       update opp;

       Test.stopTest();      
    }

    @IsTest
    static void DistributorNotBlankOldResellerBlank(){

        Test.startTest();
       
        Account dist = TestDataFactory.partnersDistributor[0];
        Account act = [Select id from Account limit 1];
        Opportunity opp = TestDataFactory.createOpportunity(act);
        opp.Reseller__c=null;
        opp.Distributor__c=dist.id;
        insert opp;   

        opp.Reseller__c =act.Id;
        update opp;

        Test.stopTest();
    }

    @IsTest
    static void DistributorBlankResellerBlank(){

        Test.startTest();

        Account dist = TestDataFactory.partnersDistributor[0];
        Account act = [Select id from Account limit 1];
        Opportunity opp = TestDataFactory.createOpportunity(act);      

        opp.Distributor__c=dist.Id;
        opp.Reseller__c =act.Id;
        insert opp;

        opp.Reseller__c=null;
        opp.Distributor__c=null;

        update opp;

        Test.stopTest();
    }
}