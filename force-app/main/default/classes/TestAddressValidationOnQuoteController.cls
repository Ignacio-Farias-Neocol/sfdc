/***
 *  @author Jade Global
 *  @date 2021-12-15
 *  @description  Test class to cover AddressValidationOnQuoteController. 
 */
@isTest
private class TestAddressValidationOnQuoteController {
    @testSetup static void setupTestData(){
        Account partner = AdminDashboardDataFactory.getAccount();
        Contact conRec = AdminDashboardDataFactory.getContact();
        conRec.AccountId = partner.Id;
        Insert conRec;
        Opportunity oppt = AdminDashboardDataFactory.getOppty(partner.Id, conRec.Id);
        Insert oppt; 
        Opportunity opp = new Opportunity();
        opp.Id = oppt.Id;
        for(Address__c addr : [Select Id, Street__c, City__c, State_Name__c, Country_Name__c, Country_ISO__c,Zip_Postal_Code__c, Type__c, Account__c from Address__c where Account__c =: partner.Id]){
            if(addr.Type__c == 'Billing'){
                opp.Street__c = addr.Street__c;
                opp.City__c = addr.City__c;
                opp.State__c = 'Ontario';
                opp.Country__c = 'Canada';
                opp.Country_ISO_Code__c = 'CA';
                opp.Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
                opp.Billing_Address__c = addr.Id;  
            }else if(addr.Type__c == 'Shipping'){
                opp.Ship_To_Street__c = addr.Street__c;
                opp.Ship_To_City__c = addr.City__c;
                opp.Ship_To_State__c = 'Ontario';
                opp.Ship_To_Country__c = 'Canada';
                opp.Shipping_Country_ISO_Code__c = 'CA';
                opp.Ship_To_Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
                opp.Shipping_Address__c = addr.Id;  
            }
        }
        update opp;
        SBQQ__Quote__c quote = AdminDashboardDataFactory.getQuote(opp);
        SBQQ__QuoteLineGroup__c quoteGrp = AdminDashboardDataFactory.getQuoteGroup(quote.Id);
        List<Product2> products = AdminDashboardDataFactory.addProducts(); 
        SBQQ__QuoteLine__c line = new SBQQ__QuoteLine__c();
        line.SBQQ__Product__c = products[1].Id;
        line.SBQQ__Quote__c = quote.Id;
        line.SBQQ__Quantity__c = 1;
        line.SBQQ__NetPrice__c = 0;
        line.Reseller_Memo_Sonian_Only__c = 'Skout'+products[1].ProductCode;
        line.SBQQ__Group__c = quoteGrp.Id; 
        Test.StartTest();
        Insert line; 
        Test.StopTest();
    }
    @isTest static void testAddressValidation(){
      Id quoteId = [Select Id from SBQQ__Quote__c].Id;
      Test.startTest();  
      String message = AddressValidationOnQuoteController.setWarningOnQuote(quoteId); 
      test.stopTest();  
      //system.assert(message != '');
    } 
}