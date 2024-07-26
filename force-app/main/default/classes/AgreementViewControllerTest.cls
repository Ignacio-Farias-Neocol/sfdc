/**
* @author        Ivan Yeung/salesforce services
* @date          2019-02-15
* @description   Unit Test class for AgreementViewControllerTest
* @group         Test
*
*   SFDC-9274 Rewrite the code.
*/
@isTest
private class AgreementViewControllerTest {
    @isTest static void unitTest() {
        Product2 testProd = TestDataFactory.products[0];
        testProd.productcode='SL-MMC';
        UPDATE testProd;
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
        Test.StartTest();
        insert testQuoteLine; 

        Contract testContract = new Contract(AccountId = testAcount.Id, Business_Group__c = 'MSP', SBQQ__Quote__c = testQuote.Id, StartDate = System.Today());
        insert testContract;

        List<SBQQ__Subscription__c> testSubcriptions = new List<SBQQ__Subscription__c> {
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAcount.Id, SBCF_Serial_Number__c = '123',SBQQ__Product__c=testProd.id),
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAcount.Id, SBCF_Serial_Number__c = '123',SBQQ__Product__c=testProd.id),
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAcount.Id, SBCF_Serial_Number__c = '123',SBQQ__Product__c=testProd.id),
            new SBQQ__Subscription__c(SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today(), ExtendedMonthlyPrice__c = 100, SBQQ__Account__c = testAcount.Id, SBCF_Serial_Number__c = '123',SBQQ__Product__c=testProd.id)
        }; 
        insert testSubcriptions;
        
        
            //testSubs[3] is master
            //testSubs[2] revised testSubs[3]
            //testSubs[2] renewed testSubs[0]
            //testSubs[0] revised testSubs[1]
            testQuoteLine.SBQQ__RenewedSubscription__c = testSubcriptions[0].Id;
            update testQuoteLine;
    
            testSubcriptions[0].SBQQ__RevisedSubscription__c = testSubcriptions[1].Id;
            testSubcriptions[2].SBQQ__QuoteLine__c = testQuoteLine.Id;
            testSubcriptions[2].SBQQ__RevisedSubscription__c = testSubcriptions[3].Id;
            update testSubcriptions;

            List<SBQQ__Subscription__c> testSubs = [SELECT ID, Name, 
                                                        SBQQ__ProductName__c, 
                                                        SBQQ__Quantity__c, 
                                                        OverageRate__c, 
                                                        SBQQ__StartDate__c,
                                                        Monthly_Unit_Price__c, 
                                                        ExtendedMonthlyPrice__c, //twined from quote line; New_Monthly_Total__c * SBQQ__EffectiveQuantity__c
                                                        SBQQ__EndDate__c, 
                                                        SBQQ__ListPrice__c, 
                                                        SBCF_Serial_Number__c,
                                                        SBQQ__RevisedSubscription__c,
                                                        SBQQ__RevisedSubscription__r.SBQQ__Quantity__c,
                                                        SBQQ__RevisedSubscription__r.ExtendedMonthlyPrice__c,
                                                        SBQQ__QuoteLine__c,
                                                        SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__c,
                                                        SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__r.SBQQ__RevisedSubscription__c,
                                                        SBQQ__TerminatedDate__c,
                                                        CurrencyISOCode,
                                                        convertCurrency(ExtendedMonthlyPrice__c) ExtendedMonthlyPriceConverted
                                                    From SBQQ__Subscription__c];
            
            PageReference pageRef = Page.MspAgreementView;
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('qid',testQuote.Id);

            AgreementViewController controller = new AgreementViewController();

            controller.init();

            System.Debug('*** newMonthlyTotal ' + controller.newMonthlyTotal);

            AgreementViewController.ShowSubsWrapper sw = new AgreementViewController.ShowSubsWrapper(testSubs[0]);
            AgreementViewController.ShowSubsWrapper sw2 = new AgreementViewController.ShowSubsWrapper(testSubs[1]);
            sw2.compareTo(sw);
            sw.compareTo(sw2);
            sw.compareTo(sw);

            AgreementViewController.formatDecimal(null, 2, true);
            AgreementViewController.formatDecimal(null, 2, false);
            AgreementViewController.formatDecimal(1234.9, 2, true);

            AgreementViewController.codeToSymbol('');
            AgreementViewController.codeToSymbol('EUR');
            AgreementViewController.codeToSymbol('GBP');
            AgreementViewController.codeToSymbol('USD');
            AgreementViewController.codeToSymbol('JPY');
            AgreementViewController.codeToSymbol('RMB');
            AgreementViewController.codeToSymbol('XYZ');
        Test.StopTest();
    }
}