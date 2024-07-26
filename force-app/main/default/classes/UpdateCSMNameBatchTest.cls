@IsTest
private class UpdateCSMNameBatchTest {
     @testSetup static void setup() {
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); 
        List <Account> customers = TestDataFactory.customers;
    }
    
    @IsTest
    static  void unitTest() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Apollo: Custom - Customer Success Profile']; 
        User u = new User(Alias = 'unit', Email='noonecsm@barracuda.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='noonecsm@barracuda.com.unit');
        insert u;  
        Account acc = [SELECT Id FROM Account LIMIT 1];
        AccountTeamMember atm = new AccountTeamMember();
        atm.AccountId = acc.Id;
        atm.UserId = u.Id;
        atm.TeamMemberRole = 'Customer Success Manager - High Touch';
        insert atm;
        Test.StartTest();
            UpdateCSMName_Batch obj = new UpdateCSMName_Batch();
            DataBase.executeBatch(obj); 
        Test.stopTest();
    }
}