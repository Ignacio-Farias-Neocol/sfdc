/**
* @author        salesforce services
* @date          11/04/2020
* @description   Unit Test class for OpportunityOwnership, OpportunityOwnershipBatch and OpportunityOwnershipRuleEngine class
* @group         Test
*
*/
@isTest
public with sharing class OpportunityOwnershipTest {

    //Test Data Setup
    @TestSetup
    private static void createTestData(){
        //Create a user with Apollo: Custom- Renewals Profile
        User renewalProfileUser = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Apollo: Custom- Renewals Profile'].Id,
                LastName = 'last',
                Email = 'testOppOwner@barracuda.com', // required domain for user barracuda.com, barracudamsp.com
                Username = 'testOppOwner@barracuda.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
        );

        //Create a user with Apollo: Custom- Renewals Profile
        User salesProfileUser = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Apollo: Custom- Sales Profile'].Id,
                LastName = 'last',
                Email = 'testOppOwnerSales@barracuda.com', // required domain for user barracuda.com, barracudamsp.com
                Username = 'testOppOwnerSales@barracuda.com',
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
        );

        insert new List<User>{renewalProfileUser, salesProfileUser};

        //get territory type
        List<Territory2Type> territoryType   = [SELECT id, 
                                                       DeveloperName 
                                                FROM Territory2Type 
                                                WHERE  DeveloperName = 'Territory' 
                                                LIMIT 1]; 
        
        //Create Territory model 
        // Territory2Model territoryModel = new Territory2Model(DeveloperName = 'Test_Territory_Model', 
        //                                                      Name = 'Test_Territory_Model',
        //                                                      State = 'Active');

        Territory2Model territoryModel = [Select Id from Territory2Model Limit 1];     


        //Create Territory2 record
        Territory2 testTerritory = new Territory2(DeveloperName = 'TestTerritory', 
                                                  Territory2ModelId=territoryModel.Id, 
                                                  Name='TestTerritory', 
                                                  Territory2TypeId=territoryType[0].Id);

        insert testTerritory;
    }

    //Scenario 1: Opportunity owner should change as per the Opportunity Ownership Rule
    @isTest
    private static void test_shouldAssignOwners(){
        //get the user
        User renewalUser = [Select Id from User where Profile.Name = 'Apollo: Custom- Renewals Profile' and Username = 'testOppOwner@barracuda.com'];
        User salesUser   = [Select Id from User where Profile.Name = 'Apollo: Custom- Sales Profile' and Username = 'testOppOwnerSales@barracuda.com'];

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
        //Create an Account
        Account acc = TestDataFactory.customers[0];

        Opportunity testOpp;
        SBQQ__Quote__c testQuote;

        //Get territory id
        Territory2 territory = [Select Id from Territory2 where DeveloperName = 'TestTerritory'];

        //Create an Opportunity without a ter
        testOpp = TestDataFactory.opportunities[0];
        testOpp.Ownerid = renewalUser.Id;
        testOpp.Territory2Id = territory.Id;
        testOpp.Primary_Product_Family_2__c = 'Email Security Gateway';
        update testOpp;

        //Create Quote
        testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, 
                                       SBQQ__Primary__c      = true,
                                       Ownerid = renewalUser.Id,
                                       SBQQ__SalesRep__c = renewalUser.Id);
        insert testQuote;     
        TriggerHandler.clearAllBypasses();  
        //Create Opportunity Ownership Rule
        Opportunity_Ownership_Rule__c oor = new Opportunity_Ownership_Rule__c(Active__c = true, 
                                                                            Opportunity_Owner__c = salesUser.Id,
                                                                            TerritoryID__c=territory.Id);

        insert oor;
        
        //Create Opportunity Ownership Condition
        Opportunity_Ownership_Condition__c ooc = new Opportunity_Ownership_Condition__c(Field_API_Name__c = 'Primary_Product_Family_2__c',
                                                                                        Operator__c       = 'Equal To',
                                                                                        Value__c          = 'Email Security Gateway',
                                                                                        Index__c          = 10,
                                                                                        Opportunity_Ownership_Rule__c = oor.id);
        insert ooc;

        Test.startTest();
            //Run the Opportunity Ownership Rule
            OpportunityOwnership.setOpportunityOwner(new List<Opportunity>{testOpp});
        Test.stopTest();

        //Check Opportunity Owner
        List<Opportunity> updatedOpp = [Select Id, OwnerId from Opportunity where Id = :testOpp.Id limit 1];
        List<SBQQ__Quote__c> updateQuote = [Select Id, OwnerId, SBQQ__SalesRep__c from SBQQ__Quote__c where Id = :testQuote.Id limit 1];

        //Assertions
        System.assertEquals(salesUser.Id, String.valueOf(updatedOpp[0].OwnerId));
        System.assertEquals(salesUser.Id, String.valueOf(updateQuote[0].OwnerId));
        System.assertEquals(salesUser.Id, String.valueOf(updateQuote[0].SBQQ__SalesRep__c));
    }

    //Scenario 2: Opportunity owner should change as per the Opportunity Ownership Rule after explicitly running rules
    @isTest
    private static void test_shouldAssignOwnersAfterRuleExecution(){
        //get the user
        User renewalUser = [Select Id from User where Profile.Name = 'Apollo: Custom- Renewals Profile' and Username = 'testOppOwner@barracuda.com'];
        User salesUser   = [Select Id from User where Profile.Name = 'Apollo: Custom- Sales Profile' and Username = 'testOppOwnerSales@barracuda.com'];

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');   
        //Create an Account
        Account acc = TestDataFactory.customers[0];

        Opportunity testOpp;
        SBQQ__Quote__c testQuote;

        //Get territory id
        Territory2 territory = [Select Id from Territory2 where DeveloperName = 'TestTerritory'];

        //Create an Opportunity without a ter
        testOpp = TestDataFactory.opportunities[0];
        
        //Create Quote
                testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, 
                SBQQ__Primary__c      = true,
                Ownerid = renewalUser.Id,
                SBQQ__SalesRep__c = renewalUser.Id);
        insert testQuote;  

        Contract testContract = new Contract(AccountId            = acc.Id, 
                                             Business_Group__c    = 'Core', 
                                             SBQQ__Quote__c       = testQuote.Id, 
                                             StartDate            = System.today(),
                                             SBQQ__RenewalTerm__c = 12);

        insert testContract;

        testOpp.SBQQ__RenewedContract__c = testContract.Id;
        testOpp.Ownerid = renewalUser.Id;
        testOpp.Territory2Id = territory.Id;
        testOpp.Primary_Product_Family_2__c = 'Email Security Gateway';
        testOpp.Business_Group__c = 'Core';
        testOpp.RecordTypeId = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Renewal').getRecordTypeId();
        testOpp.LeadSource = 'Renewal'; 
        testOpp.CloseDate = Date.today().addDays(10);
        testOpp.Bypass_Validation__c = true;
        testOpp.Is_Unit_Test__c = true;
        update testOpp;

   
        TriggerHandler.clearAllBypasses();  
        //Create Opportunity Ownership Rule
        Opportunity_Ownership_Rule__c oor1 = new Opportunity_Ownership_Rule__c(Active__c = true, 
                                                                            Opportunity_Owner__c = salesUser.Id,
                                                                            TerritoryID__c=territory.Id);

        Opportunity_Ownership_Rule__c oor2 = new Opportunity_Ownership_Rule__c(Active__c = true, 
                                                                               Opportunity_Owner__c = UserInfo.getUserId(),
                                                                               TerritoryID__c=territory.Id,
                                                                               Conditions_Met__c = 'Any');  
        Opportunity_Ownership_Rule__c oor3 = new Opportunity_Ownership_Rule__c(Active__c = true, 
                                                                               Opportunity_Owner__c = UserInfo.getUserId(),
                                                                               TerritoryID__c=territory.Id,
                                                                               Conditions_Met__c = 'Custom',
                                                                               Advanced_Condition__c = '10');                                                                                                                                                         
        List<Opportunity_Ownership_Rule__c> oorList = new List<Opportunity_Ownership_Rule__c>{oor1,oor2,oor3};
        insert oorList;
        
        //Create Opportunity Ownership Condition
        Opportunity_Ownership_Condition__c ooc1 = new Opportunity_Ownership_Condition__c(Field_API_Name__c = 'Primary_Product_Family_2__c',
                                                                                         Operator__c       = 'Equal To',
                                                                                         Value__c          = 'Email Security Gateway',
                                                                                         Index__c          = 10,
                                                                                         Opportunity_Ownership_Rule__c = oorList[0].id);

        Opportunity_Ownership_Condition__c ooc2 = new Opportunity_Ownership_Condition__c(Field_API_Name__c = 'Amount',
                                                                                         Operator__c       = 'Equal To',
                                                                                         Value__c          = '10000',
                                                                                         Index__c          = 10,
                                                                                         Opportunity_Ownership_Rule__c = oorList[1].id);

        Opportunity_Ownership_Condition__c ooc3 = new Opportunity_Ownership_Condition__c(Field_API_Name__c = 'Amount',
                                                                                         Operator__c       = 'Equal To',
                                                                                         Value__c          = '10000',
                                                                                         Index__c          = 10,
                                                                                         Opportunity_Ownership_Rule__c = oorList[2].id);                                                                                        
        insert new List<Opportunity_Ownership_Condition__c>{ooc1, ooc2, ooc3};

        Test.startTest();
            //Create an instance of the batch 
            OpportunityOwnershipBatch oob = new OpportunityOwnershipBatch(new List<Id>{oorList[0].Id, oorList[1].Id, oorList[2].Id});
            Database.executeBatch(oob);
            
        Test.stopTest();

        //Check Opportunity Owner
        List<Opportunity> updatedOpp = [Select Id, OwnerId from Opportunity where Id = :testOpp.Id limit 1];
        List<SBQQ__Quote__c> updateQuote = [Select Id, OwnerId, SBQQ__SalesRep__c from SBQQ__Quote__c where Id = :testQuote.Id limit 1];

        //Assertions
        System.assertEquals(salesUser.Id, String.valueOf(updatedOpp[0].OwnerId));
        System.assertEquals(salesUser.Id, String.valueOf(updateQuote[0].OwnerId));
        System.assertEquals(salesUser.Id, String.valueOf(updateQuote[0].SBQQ__SalesRep__c));
    }    
}