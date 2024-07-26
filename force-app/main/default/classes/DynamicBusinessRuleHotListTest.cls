@IsTest
private class DynamicBusinessRuleHotListTest {
    @IsTest
    static  void unitTest() {
        Product2 testProd = TestDataFactory.products[0];
        Account testAcount = TestDataFactory.customers[0];
        Lead testLead = TestDataFactory.postMQLLeads[0];
        Test.startTest();
            //no account
            Hot_List__c testHotList = new Hot_List__c (Lead__c = testLead.Id, Business_Group__c = 'Core', Serial_Number__c = 'AA-TestTestTest', Products__c = 'TestProductCode-b', Employee_Count_Rep_Entered__c = 20);
            insert testHotList;

            //no bad product sku
            List<Hot_List__c> testHotLists = new List<Hot_List__c>{
                new Hot_List__c (Account__c = testAcount.Id, Lead__c = testLead.Id, Business_Group__c = 'Core', Serial_Number__c = 'AA-EmptyB', Products__c = '-b', Employee_Count_Rep_Entered__c = 20),
                new Hot_List__c (Account__c = testAcount.Id, Lead__c = testLead.Id, Business_Group__c = 'Core', Serial_Number__c = 'AA-BadB', Products__c = 'BadProductCode-b', Employee_Count_Rep_Entered__c = 20)
            };
            insert testHotLists;

            testProd.ProductCode = 'TestProductCode';
            testProd.SBCF_Form_Factor__c = 'SaaS';
            update testProd;

            //good
            testHotList = new Hot_List__c (Account__c = testAcount.Id, Lead__c = testLead.Id, Business_Group__c = 'Core', Serial_Number__c = 'AA-TestTestTest', Products__c = 'TestProductCode-b', Employee_Count_Rep_Entered__c = 20);
            insert testHotList;

            //Serial Number Exists
            testHotList = new Hot_List__c (Account__c = testAcount.Id, Lead__c = testLead.Id, Business_Group__c = 'Core', Serial_Number__c = 'AA-TestTestTest', Products__c = 'TestProductCode-b', Employee_Count_Rep_Entered__c = 20);
            insert testHotList;

            List<Asset> assetsToCreate = new List<Asset>();
            Asset a1 = new Asset();
            a1.Name = 'Test Asset 1';
            a1.AccountId = testAcount.Id;
            Asset a2 = new Asset();
            a2.Name = 'Test Asset 2';
            a2.AccountId = testAcount.Id;
            assetsToCreate.add(a1);
            assetsToCreate.add(a2);
            insert assetsToCreate;

           CheckLargeAssetAccountForHotList.hotListDetails det = new CheckLargeAssetAccountForHotList.hotListDetails();
           det.hotListId = testHotList.Id;
           List<CheckLargeAssetAccountForHotList.hotListDetails> res = CheckLargeAssetAccountForHotList.checkLargeAssetAccount(new List<CheckLargeAssetAccountForHotList.hotListDetails>{det});
           system.debug('--res--' + res);

           try{
            Opportunity opp = TestDataFactory.opportunities[0];    
           }
           catch(Exception e){
               system.debug('---e---' + e.getMessage());
           }
        Test.stopTest();
    }
}