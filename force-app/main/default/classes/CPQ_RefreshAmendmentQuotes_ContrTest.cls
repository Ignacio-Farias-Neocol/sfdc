@isTest
private class CPQ_RefreshAmendmentQuotes_ContrTest {
    @isTest static void myUnitTest() {
        Opportunity testOpp = TestDataFactory.opportunities[0]; 
    
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true);
        insert testQuote;

        Test.startTest();
            try {
                CPQ_RefreshAmendmentQuotes_Controller.refreshAmendmentsGetQuoteIdResult r = CPQ_RefreshAmendmentQuotes_Controller.refreshAmendmentsGetQuoteId(null);
            } catch (Exception e) {}
            
            try {
                CPQ_RefreshAmendmentQuotes_Controller.refreshAmendmentsGetQuoteIdResult r = CPQ_RefreshAmendmentQuotes_Controller.refreshAmendmentsGetQuoteId(testOpp.Id);
            } catch (Exception e) {}

            try {
                CPQ_RefreshAmendmentQuotes_Controller.refreshAmendmentsGetQuoteIdResult r = CPQ_RefreshAmendmentQuotes_Controller.refreshAmendmentsGetQuoteId(testQuote.Id);
            } catch (Exception e) {}
            
        Test.stopTest();
    }

  /*  @isTest static void myUnitTest2() {  Rahul:Need to look into this Unit Test later
    
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        Account testAccount = TestDataFactory.customers[0];
        testAccount.Bill_To_Email__c = '123@123.com';
        testAccount.Bill_To_Contact__c = 'Knock Knock';
        testAccount.User_na__c = 'TESTUSERNAME';
        testAccount.Compliance_Status__c = 'Active';
        testAccount.Maestro_ECHO_Password__c = 'test123';
        update testAccount;

        Contact testContact = TestDataFactory.customerContacts[0];
        testContact.MailingCountryCode = 'US';
        update testContact;

        List <Address__c> addresses = [select id, Street__c, City__c, State_Name__c, Country_Name__c, Zip_Postal_Code__c, Type__c, Account__c from Address__c];

        String opptRTId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
        List<Opportunity> testOpps = new List<Opportunity> {
            new Opportunity(Name = 'The Closed Oppty', AccountID = testAccount.Id, Primary_Product_Family_2__c = 'Email Security Gateway', Model_Series__c = 'API', StageName = 'Accepted', CloseDate = System.today(), recordTypeId = opptRTId, Bypass_Validation__c = true, Is_Unit_Test__c = true, LeadSource = 'Renewal', Business_Group__c = 'MSP', Bill_To_Account__c = testAccount.Id, Primary_Contact__c = testContact.Id),
            new Opportunity(Name = 'The Open Oppty', AccountID = testAccount.Id, Primary_Product_Family_2__c = 'Email Security Gateway', Model_Series__c = 'API', StageName = 'Accepted', CloseDate = System.today(), recordTypeId = opptRTId, Bypass_Validation__c = true, Is_Unit_Test__c = true, LeadSource = 'Renewal', Business_Group__c = 'MSP', Bill_To_Account__c = testAccount.Id, Primary_Contact__c = testContact.Id)
        };    
        insert testOpps;

        List<Opportunity> oppts = new List<Opportunity>();
        for (Opportunity oppt: testOpps ){
            for (Address__c addr : addresses){
                if (addr.Type__c == 'Billing' ){
                    oppt.Billing_Address__c = addr.Id;
                    oppt.Street__c = addr.Street__c;
                    oppt.City__c = addr.City__c;
                    oppt.State__c = addr.State_Name__c;
                    oppt.Country__c = addr.Country_Name__c;
                    oppt.Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
                } else if  (addr.Type__c == 'Shipping' ){
                    oppt.Shipping_Address__c = addr.Id;
                    oppt.Ship_To_Street__c = addr.Street__c;
                    oppt.Ship_To_City__c = addr.City__c;
                    oppt.Ship_To_State__c = addr.State_Name__c;
                    oppt.Ship_To_Country__c = addr.Country_Name__c;
                    oppt.Ship_To_Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
                }    
            }

            oppts.add(oppt);
        }    
        update oppts;

        List<SBQQ__Quote__c> testQuotes = new List<SBQQ__Quote__c> {
            new SBQQ__Quote__c(SBQQ__Account__c = testAccount.Id, SBQQ__Opportunity2__c = testOpps[0].Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Amendment'),
            new SBQQ__Quote__c(SBQQ__Account__c = testAccount.Id, SBQQ__Opportunity2__c = testOpps[1].Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Amendment')
        };    
        insert testQuotes;
        
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(SBQQ__Quote__c = testQuotes[0].Id, SBQQ__Number__c = 10);
        insert testGroup;

        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Group__c = testGroup.Id, SBQQ__Product__c = TestDataFactory.products[0].Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuotes[0].Id);
        insert testQuoteLine;

        testQuotes[0].ApprovalStatus__c = 'Approved';
        update testQuotes[0];

        testOpps[0].StageName = 'Closed Won';
        update testOpps[0];
        TriggerHandler.clearAllBypasses();
        
      
        
        Test.startTest();
            //Opportunity o = [Select Primary_Contact__c, Primary_Contact__r.MailingCountryCode, Business_Group__c, Bill_To_Account__c, Bill_To_Account__r.Bill_To_Contact__c, Bill_To_Account__r.Bill_To_Email__c From Opportunity Where ID =: testOpp.Id];
            //System.Debug('*** o.Primary_Contact__c, Primary_Contact__r.MailingCountryCode ' + o.Primary_Contact__c + o.Primary_Contact__r.MailingCountryCode);

            CPQ_RefreshAmendmentQuotes_Controller.refreshAmendmentsGetQuoteIdResult r = CPQ_RefreshAmendmentQuotes_Controller.refreshAmendmentsGetQuoteId(testOpps[0].Id);
            r = CPQ_RefreshAmendmentQuotes_Controller.refreshAmendmentsGetQuoteId(testQuotes[0].Id);
            CPQ_RefreshAmendmentQuotes_Controller.cloneQuote(testQuotes[0].Id);
             
        Test.stopTest();
    } */
}