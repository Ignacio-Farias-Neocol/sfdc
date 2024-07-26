@isTest
private class DynamicValidationOpptyCCExpiryCheckTest {
    
    @testSetup
    static void setup() {
        Opportunity testOpp = TestDataFactory.opportunities[0];
    }
    
    static testMethod void testEvaluateRule() {
        // Setup test data
        String stageName;
        String accountId;
        List<SObject> testOpp = [SELECT Id, Stagename, Bill_To_Credit_Card__c,Bill_To_Account__c FROM Opportunity];
        for (SObject record : testOpp) {
            Opportunity opp = (Opportunity) record; 
            stageName = opp.StageName;
            accountId = opp.Bill_To_Account__c; 
        }
        Contact con=[Select Id from Contact where AccountId =: accountId];
        
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
        
        DynamicValidationOpptyCCExpiryCheck validation = new DynamicValidationOpptyCCExpiryCheck();
        System.runAs(u){
            Test.startTest();
            for (SObject record : testOpp) {
                Opportunity opp = (Opportunity) record;
                opp.StageName = 'Order in Process';           
            }
            Map<SObject, Boolean> result = validation.evaluateRule(testOpp);
            Test.stopTest();
            
            System.assertEquals(0, result.size(), 'Expected number of results to be returned');
        }
    }
    
}