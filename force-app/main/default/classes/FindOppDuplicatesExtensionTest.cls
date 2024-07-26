@isTest
private class FindOppDuplicatesExtensionTest
{
    @isTest static void testFindOppDuplicates()
    {
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active


        // Account newAccount = TestDataFactory.customers[0]; // TestDataFactory.createAccount();

        Account newAccount = new Account();
        newAccount.Is_Unit_Test__c = true;
        newAccount.name = 'Test';
        // newAccount.recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        insert newAccount;

        Test.startTest();

        Opportunity opp1 = TestDataFactory.createOpportunity(newAccount);
        // Opportunity opp2 = TestDataFactory.createOpportunity(newAccount);
        // Opportunity[] opps = new Opportunity[]{opp1, opp2};
        // insert opps;
        insert opp1;

        Test.stopTest();
        TriggerHandler.clearAllBypasses();


        ApexPages.StandardController stdController = new ApexPages.StandardController(opp1);
        FindOppDuplicatesExtension extension = new FindOppDuplicatesExtension(stdController);

        extension.Keyword = 'Opp';
        extension.HasMergeAllOppPermission = !extension.HasMergeAllOppPermission;
        extension.retrieveOpportunity();
        for(FindOppDuplicatesExtension.OpportunityWrapper wrapper : extension.OpportunityList)
        {
            wrapper.IsSelected = true;
        }
        extension.next();
    }
}