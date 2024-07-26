/**
 * @description       : Test Class for OpportunityBusinessTypeHandler
 * @author            : Ignacio F.
 * @group             : 
 * @last modified on  : 07-11-2024
 * @last modified by  : Ignacio F.
**/
@isTest
public class NEO_OpportunityBusinessTypeHandlerTest {

    @TestSetup
    public static void setupTestData(){

        Account testaccount = NEO_TestDataFactory.getPartnerAccounts(1)[0];
        insert testAccount;

        Contact contact = NEO_TestDataFactory.getRelatedContacts(1, testAccount.Id)[0];
        insert contact;

        List<Opportunity> opps = NEO_TestDataFactory.getOpportunities(1, testAccount.Id, contact.Id);
        insert opps;    

        SBQQ__Subscription__c sub = new SBQQ__Subscription__c(SBQQ__Account__c = testAccount.Id, SBQQ__SubscriptionStartDate__c = Date.today().addYears(-4), SBQQ__SubscriptionEndDate__c = Date.today().addMonths(-34) , SBQQ__Quantity__c = 1);
        insert sub;
    }
    
    @isTest
    public static void testType_PositiveScenario() {
        List<Opportunity> opportunities = [SELECT Id, AccountId, CloseDate, StageName, Migration__c, Type, RecordType_Name__c, SBQQ__AmendedContract__c, SBQQ__RenewedContract__c, Type_Alignment_Run__c FROM Opportunity Where Type_Alignment_Run__c != 1] ;
        
        List<Opportunity> updatedOpportunities = new List<Opportunity>();
        
        for(Opportunity opp : opportunities){
            opp.Type_Alignment_Run__c = 1;
            updatedOpportunities.add(opp);
        }
        
        // Measure execution time
        Datetime startTime = Datetime.now();

        Test.startTest();
            update updatedOpportunities;
        Test.stopTest();
        
        Datetime endTime = Datetime.now();
        Long executionTimeInMillis = endTime.getTime() - startTime.getTime();

        System.debug('Execution time: ' + executionTimeInMillis + ' ms');

        // Validate results
        for (Opportunity opp : [SELECT Id, Type FROM Opportunity]) {
            System.assertNotEquals(null, opp.Type, 'Opportunity Type should not be null');
        }
    }

    @isTest
    static void testStageName_PositiveScenario() {
        List<Opportunity> opportunities = [SELECT Id, AccountId, CloseDate, StageName, Migration__c, Type, RecordType_Name__c, SBQQ__AmendedContract__c, SBQQ__RenewedContract__c, Type_Alignment_Run__c FROM Opportunity Where StageName = 'Accepted' LIMIT 10] ;

        List<Opportunity> updatedOpportunities = new List<Opportunity>();
        
        for(Opportunity opp : opportunities){
            opp.Type_Alignment_Run__c = 1;
            updatedOpportunities.add(opp);
        }
        
        Datetime startTime = Datetime.now();
        
        Test.startTest();
            update updatedOpportunities;
        Test.stopTest();
        
        Datetime endTime = Datetime.now();
        Long executionTimeInMillis = endTime.getTime() - startTime.getTime();

        System.debug('Execution time: ' + executionTimeInMillis + ' ms');

        for (Opportunity opp : [SELECT Id, Type FROM Opportunity]) {
            Boolean typeChanged = false;

            System.assertNotEquals(null, opp.Type, 'Opportunity Type should not be null');
        }
    }
    
    @isTest
    static void test_NegativeScenario() {
        List<Opportunity> opportunities = [SELECT Id, AccountId, CloseDate, StageName, Type FROM Opportunity WHERE AccountId = null LIMIT 200];
        Map<Id, SObject> newRecordMap = new Map<Id, SObject>(opportunities);

        Datetime startTime = Datetime.now();
        
        OpportunityBusinessTypeHandler handler = new OpportunityBusinessTypeHandler();
        handler.processRecords(newRecordMap, new Map<Id, SObject>(), opportunities, null, null, null);
        
        Datetime endTime = Datetime.now();
        Long executionTimeInMillis = endTime.getTime() - startTime.getTime();

        System.debug('Execution time: ' + executionTimeInMillis + ' ms');

        // Validate results
        for (Opportunity opp : [SELECT Id, Type FROM Opportunity WHERE AccountId = null]) {
            System.assertEquals(null, opp.Type, 'Opportunity Type should be null for opportunities without an Account');
        }
    }


    @isTest
    public static void testType_CreateOpportunityNew() {
        Account acc = [SELECT Id From Account LIMIT 1] ;

        List<Opportunity> oppList = new List<Opportunity>();
        for(Integer i = 0; i < 1 ; i++){    
            Opportunity newOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = acc.Id,
                CloseDate = Date.today().addMonths(1),
                StageName = 'Accepted',
                Migration__c = false,
                SBQQ__AmendedContract__c = null,
                SBQQ__RenewedContract__c = null,
                Type_Alignment_Run__c = 0
            );
            oppList.add(newOpportunity);
        }
                
        Datetime startTime = Datetime.now();
    
        Test.startTest();
            insert oppList;
        Test.stopTest();
        
        Datetime endTime = Datetime.now();
        Long executionTimeInMillis = endTime.getTime() - startTime.getTime();
    
        System.debug('Execution time: ' + executionTimeInMillis + ' ms');

        Map<Id, Opportunity> opportunityMap = new Map<Id,Opportunity>(oppList);
    
        List<Opportunity> insertedOpportunities = [SELECT Id, Type FROM Opportunity WHERE Id = :opportunityMap.keyset()];
        for(Opportunity insertedOpportunity : insertedOpportunities){
            System.assertNotEquals(null, insertedOpportunity.Type, 'Opportunity Type should not be null');
        }
    }

    @isTest
    public static void testType_CreateOpportunityExisting() {
        Account acc = [SELECT Id From Account LIMIT 1] ;
    

        List<Opportunity> oppList = new List<Opportunity>();
        for(Integer i = 0; i < 1 ; i++){    
            Opportunity newOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = acc.Id,
                CloseDate = Date.today().addMonths(1),
                StageName = 'Accepted',
                Migration__c = true,
                SBQQ__AmendedContract__c = null,
                SBQQ__RenewedContract__c = null,
                Type_Alignment_Run__c = 0
            );
            oppList.add(newOpportunity);
        }
                
        // Measure execution time
        Datetime startTime = Datetime.now();
    
        Test.startTest();
            insert oppList;
        Test.stopTest();
        
        Datetime endTime = Datetime.now();
        Long executionTimeInMillis = endTime.getTime() - startTime.getTime();
    
        System.debug('Execution time: ' + executionTimeInMillis + ' ms');

        Map<Id, Opportunity> opportunityMap = new Map<Id,Opportunity>(oppList);
    
        // Validate results
        List<Opportunity> insertedOpportunities = [SELECT Id, Type FROM Opportunity WHERE Id = :opportunityMap.keyset()];
        for(Opportunity insertedOpportunity : insertedOpportunities){
            System.assertNotEquals(null, insertedOpportunity.Type, 'Opportunity Type should not be null');
        }
    }

    @isTest
    public static void testType_CreateOpportunityisMigration() {
        Account acc = [SELECT Id From Account LIMIT 1] ;

        List<Opportunity> oppList = new List<Opportunity>();
        for(Integer i = 0; i < 1 ; i++){    
            Opportunity newOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = acc.Id,
                CloseDate = Date.today().addMonths(1),
                StageName = 'Accepted',
                Migration__c = true,
                SBQQ__AmendedContract__c = null,
                SBQQ__RenewedContract__c = null,
                Type_Alignment_Run__c = 0
            );
            oppList.add(newOpportunity);
        }
                
        Datetime startTime = Datetime.now();
    
        Test.startTest();
            insert oppList;
        Test.stopTest();
        
        Datetime endTime = Datetime.now();
        Long executionTimeInMillis = endTime.getTime() - startTime.getTime();
    
        System.debug('Execution time: ' + executionTimeInMillis + ' ms');

        Map<Id, Opportunity> opportunityMap = new Map<Id,Opportunity>(oppList);
    
        List<Opportunity> insertedOpportunities = [SELECT Id, Type FROM Opportunity WHERE Id = :opportunityMap.keyset()];
        for(Opportunity insertedOpportunity : insertedOpportunities){
            System.assertNotEquals(null, insertedOpportunity.Type, 'Opportunity Type should not be null');
        }
    }

    @isTest
    public static void testType_CreateOpportunityRenewal() {
        Account acc = [SELECT Id From Account LIMIT 1];
        Id renewalRT= Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('Renewal').getRecordTypeId();

        List<Opportunity> oppList = new List<Opportunity>();
        for(Integer i = 0; i < 1 ; i++){    
            Opportunity newOpportunity = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = acc.Id,
                CloseDate = Date.today().addMonths(1),
                StageName = 'Accepted',
                Migration__c = false,
                SBQQ__AmendedContract__c = null,
                SBQQ__RenewedContract__c = null,
                Type_Alignment_Run__c = 0,
                recordTypeId = renewalRT
            );
            oppList.add(newOpportunity);
        }
                
        Datetime startTime = Datetime.now();
    
        Test.startTest();
            insert oppList;
        Test.stopTest();
        
        Datetime endTime = Datetime.now();
        Long executionTimeInMillis = endTime.getTime() - startTime.getTime();
    
        System.debug('Execution time: ' + executionTimeInMillis + ' ms');

        Map<Id, Opportunity> opportunityMap = new Map<Id,Opportunity>(oppList);
    
        List<Opportunity> insertedOpportunities = [SELECT Id, Type FROM Opportunity WHERE Id = :opportunityMap.keyset()];
        for(Opportunity insertedOpportunity : insertedOpportunities){
            System.assertNotEquals(null, insertedOpportunity.Type, 'Opportunity Type should not be null');
        }
    }
}