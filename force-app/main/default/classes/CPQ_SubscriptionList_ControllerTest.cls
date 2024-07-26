@isTest
private class CPQ_SubscriptionList_ControllerTest {
    @isTest static void unitTest() {
        Product2 testProd = TestDataFactory.products[0];
        Account testAcount = TestDataFactory.customers[0];

        List <Address__c> addresses = [select id, Street__c, City__c, State_Name__c, Country_Name__c, Zip_Postal_Code__c, Type__c, Account__c from Address__c];

        String opptRTId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        Opportunity testOpp = New Opportunity(Name = 'The Closed Oppty', AccountID = testAcount.Id, Primary_Product_Family_2__c = 'Email Security Gateway', Model_Series__c = 'API', StageName = 'Accepted', CloseDate = System.today(), recordTypeId = opptRTId, Bypass_Validation__c = true, Is_Unit_Test__c = true, LeadSource = 'Renewal', Bill_To_Account__c = testAcount.Id);    
        insert testOpp;

        for (Address__c addr : addresses){
            if (addr.Type__c == 'Billing' ){
                testOpp.Billing_Address__c = addr.Id;
                testOpp.Street__c = addr.Street__c;
                testOpp.City__c = addr.City__c;
                testOpp.State__c = addr.State_Name__c;
                testOpp.Country__c = addr.Country_Name__c;
                testOpp.Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
            } else if  (addr.Type__c == 'Shipping' ){
                testOpp.Shipping_Address__c = addr.Id;
                testOpp.Ship_To_Street__c = addr.Street__c;
                testOpp.Ship_To_City__c = addr.City__c;
                testOpp.Ship_To_State__c = addr.State_Name__c;
                testOpp.Ship_To_Country__c = addr.Country_Name__c;
                testOpp.Ship_To_Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
            }    
        }
        update testOpp;

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true, SBCF_Monthly_Cost_Total__c = 0);
        insert testQuote;

        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 0, SBCF_Is_Shipped__c = TRUE, Appliance_Line_Type__c = 'Standard');
        insert testQuoteLine; 

        Contract testContract = new Contract(AccountId = testAcount.Id, Business_Group__c = 'MSP', SBQQ__Quote__c = testQuote.Id, StartDate = System.Today());
        insert testContract;

        List<SBQQ__Subscription__c> testSubs = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAcount.Id, SBCF_Serial_Number__c = '123', SBQQ__QuoteLine__c = testQuoteLine.Id),
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAcount.Id, SBCF_Serial_Number__c = '123', SBQQ__QuoteLine__c = testQuoteLine.Id)
        }; 
        insert testSubs;

        Test.startTest();
            testQuoteLine.SBQQ__RenewedSubscription__c = testSubs[0].Id;
            testQuoteLine.SBQQ__UpgradedSubscription__c = testSubs[1].Id;
            update testQuoteLine;

            CPQ_SubscriptionList_Controller.SubscriptionResults r = CPQ_SubscriptionList_Controller.retrieveSubscriptions('006000000000000000');

            r = CPQ_SubscriptionList_Controller.retrieveSubscriptions(testOpp.Id);
            System.Debug(r.errorMsg);
        Test.stopTest();
    }
}