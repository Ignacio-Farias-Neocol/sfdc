/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-17-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class DynamicBusinessRuleOrderItemTest {
    @isTest static void myUnitTest() {
        Product2 testProd = TestDataFactory.products[0];
        testProd.ProductCode = 'DiscMo';
        update testProd;
        
        Account acc = TestDataFactory.customers[0];
        acc.Territory_ID__c = '123';
        
        
        System.debug(acc.Territory_ID__c+'***acc');
        
        /*Account acc = new Account();
        acc.Name = 'TESH ACC';
        acc.Type = 'Partner - MSP';
        acc.Bill_To_Contact__c='test';
        acc.Bill_To_Email__c='Test@gmail.com';
        acc.ShippingCity='Reynolds';
        acc.ShippingState='Pennsylvania';
        acc.ShippingStateCode='PA';
        acc.ShippingCountryCode='US';
        acc.ShippingCountry='United States';
        acc.ShippingPostalCode='18704';
        acc.ShippingStreet='402 W 100 N';
        acc.State_Code__c='PA2';
        acc.BillingState='Pennsylvania';
        acc.BillingCity='Wilkes-Barre';
        acc.BillingCountry='United States';
        acc.BillingCountryCode='US';
        acc.BillingPostalCode='18704';
        acc.Terr_Location__c ='NORWAY - LOCATION';
        acc.Terr_Region__c='NORDICS - REGION';
        acc.Terr_Sub_Territory__c='NORWAY - SUB TERRITORY';
        acc.Terr_Sub_Theater__c='BENELUX - NORDICS - SUB THEATER';
        acc.Territory__c='NORDICS - TERRITORY';
        acc.Terr_Theater__c='EMEA';
        acc.Territory_ID__c='0MIf20000000WM6GAM';
        
        insert acc;  */ 
        
        Contact rec = new Contact();
            rec.LastName = 'Doe456' ;
            rec.FirstName = 'John';
            //rec.FirstName__c = 'John';
            //rec.LastName__c = 'Doe' + ' ' + suffixNumber;
            rec.Email = 'John.Doe@test456.com';
            rec.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
            rec.AccountId = acc.Id;
            rec.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
            rec.LeadSource = 'Renewal';
            insert rec;
        
        Opportunity testOpp = new Opportunity();
        testOpp.Name ='Oppty' + 123;
        testOpp.AccountID = acc.Id;
        testOpp.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
        testOpp.Model_Series__c = 'API';
        testOpp.StageName = 'Accepted';
        testOpp.Amount = 3000;
        testOpp.CloseDate = System.today();
        testOpp.Bypass_Validation__c = true;
        testOpp.Is_Unit_Test__c = true;
        testOpp.LeadSource = 'Renewal';
        testOpp.BypassBusinessGroupValidation__c = True;
        testOpp.Bill_To_Account__c = acc.Id;
        testOpp.Ship_To_Account__c=acc.id;
        testOpp.Primary_Contact__c= rec.Id;
        testOpp.Street__c='402 W 100 N`';
        testOpp.City__c='Reynolds';
        testOpp.Country__c='US';
        testOpp.Zip_Postal_Code__c='18704';
        testOpp.Ship_To_City__c='Chelmsford';
        testOpp.Ship_To_Zip_Postal_Code__c='01824';
        testOpp.Country_ISO_Code__c='US';
        testOpp.Ship_To_State__c='Pennsylvania';        
        testOpp.Business_Group__c='Core';
        testopp.Shipping_Country_ISO_Code__c='US';
        testOpp.Ship_To_Street__c='100 Apollo Drive';
        testOpp.Ship_To_State__c='Massachusetts';
        testOpp.Ship_To_Country__c='United States';
        Insert testOpp;
        
        System.debug(acc.id+'***acc.id');
        
        testOpp = [Select Id,AccountId,Account.Territory_ID__c,Territory_ID__c,Shipping_Country_ISO_Code__c,Ship_To_Street__c,Ship_To_State__c,Ship_To_Country__c from Opportunity
        where Id =:testOpp.Id]; 
        System.debug( testopp.AccountId+'*** testopp.AccountId');
        

        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = testOpp.Id, SBQQ__Primary__c = true, SBQQ__Type__c = 'Renewal');
        //testQuote.SBQQ__Opportunity2__r.Account.Territory_ID__c='123';
        insert testQuote;
        
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 2, SBQQ__Quote__c = testQuote.Id, SBQQ__NetPrice__c = 0, SBCF_Is_Shipped__c = TRUE, Appliance_Line_Type__c = 'Standard');
        test.startTest();
        insert testQuoteLine; 

            Order testOrder = TestDataFactory.orders[0];
            OrderItem testOrderLine = new OrderItem(OrderId = testOrder.Id, UnitPrice = NULL, SBQQ__QuoteLine__c = testQuoteLine.Id, Product2Id = testProd.Id, Quantity = 1, PricebookEntryId = TestDataFactory.priceBookEntry[0].Id);
            insert testOrderLine;
            update testOrderLine;
        test.stopTest();
    }
}