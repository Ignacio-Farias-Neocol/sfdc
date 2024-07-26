@isTest
private  class   OpptySharingResellerBatchTest {
    
    @TestSetup
    static void setup() {        
      
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
    }

    @IsTest
    static void DistributorResellerNotBlank(){

        Test.startTest();
        OpptySharingResellerBatch os= new  OpptySharingResellerBatch();

        Account dist = TestDataFactory.partnersDistributor[0];     
        Account act = [Select id from Account limit 1];
        Opportunity testOpp = TestDataFactory.createOpportunity(act);
        insert testOpp;             

        testOpp.Distributor__c=dist.Id;
        testOpp.Reseller__c =act.Id;
        update testOpp;      

        Id jobid= Database.executeBatch(os);

        Test.stopTest();
    }
}