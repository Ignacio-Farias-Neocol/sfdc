/** 
 * Test methods to cover QuoteExtController updates to approval status
 * 
 * @author Micah Gerger
 * @date 2018/11/07
 * 
 */

@isTest
private class QuoteExtControllerTests {
    
    testMethod static void testSubmit() {

        // 2019-01-30 test failed, change to use TestDataFactory
        /*
        // arrange some data
        Opportunity oppty = new Opportunity();
        oppty.Name = 'Test Opp';
        oppty.StageName = 'Discovery';
        oppty.CloseDate = system.today();
        oppty.Business_Group__c = null;
        DML.save(oppty);

        Opportunity oppty = TestDataFactory.opportunities[0];
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = oppty.Id;
        DML.save(quote);

        */


        // by pass business action ,
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        List <Contact> contacts = TestDataFactory.customerContacts;
        List <Account> customers = TestDataFactory.customers;
        List <Account> partners = TestDataFactory.partners;
        List <Product2> products = TestDataFactory.products;
        List <Opportunity> opportunities = TestDataFactory.opportunities;
        TriggerHandler.clearAllBypasses();

        SBQQ__Quote__c quote = TestDataFactory.quotes[0];

        // run the test
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onSubmit();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        // assert the result
        System.assertEquals('Approved', quote.ApprovalStatus__c);
    }
    
    testMethod static void testRecall() {



        // by pass business action ,
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        List <Contact> contacts = TestDataFactory.customerContacts;
        List <Account> customers = TestDataFactory.customers;
        List <Account> partners = TestDataFactory.partners;
        List <Product2> products = TestDataFactory.products;
        List <Opportunity> opportunities = TestDataFactory.opportunities;
        Opportunity oppty = opportunities[0];
        TriggerHandler.clearAllBypasses();

        /*
        // arrange some data
        Opportunity oppty = new Opportunity();
        oppty.Name = 'Test Opp';
        oppty.StageName = 'Discovery';
        oppty.CloseDate = system.today();
        oppty.Business_Group__c = null;
        DML.save(oppty);

        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = oppty.Id;
        DML.save(quote);
        
        */



        SBQQ__Quote__c quote = TestDataFactory.quotes[0];
        
        // run the test
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onRecall();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        // assert the result
        System.assertEquals('Recalled', quote.ApprovalStatus__c);
    }
    
}