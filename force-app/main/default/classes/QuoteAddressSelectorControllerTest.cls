/**

* @Author Sonal Agrawal
* @Date 2022/03/11
* @description: SFDC-18053 - Unit Test class for QuoteAddressSelectorController
*
*/

@isTest
public class QuoteAddressSelectorControllerTest {
    @isTest static void unitTest() {
        // prepare test data
        // by pass business action ,
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
        List <Contact> contacts = TestDataFactory.customerContacts;
        List <Account> customers = TestDataFactory.customers;
        List <Account> partners = TestDataFactory.partners;
        List <Product2> products = TestDataFactory.products;
        List <Opportunity> opportunities = TestDataFactory.opportunities;
        List <SBQQ__Quote__c> quotes = TestDataFactory.quotes;
        Map<String, Map<String, State__c>> states = TestDataFactory.states;
        Map<String, Country__c> countries = TestDataFactory.countries;
        TriggerHandler.clearAllBypasses();
        Address__c addr = new Address__c();
        addr.Country__c = countries.get('US').Id;
        addr.State__c = states.get('US').get('CA').Id;
        addr.Street__c = '415 Mission Street';
        addr.City__c = 'San Francisco';
        addr.Zip_Postal_Code__c = '94105';
        addr.Type__c = 'Billing';
        addr.Account__c = customers[0].id;
        Insert addr;
        List<Address__c> AddRec = [Select id,Country__c,Country__r.Name,State__r.Name,Country_ISO__c,State__c,Street__c,City__c,Zip_Postal_Code__c,Type__c,Account__c from Address__c limit 1];
        String addressString = JSON.serialize(AddRec);
        SBQQ__Quote__c quoteRec = [Select id from SBQQ__Quote__c limit 1];
        String quoteString = JSON.serialize(quoteRec);
        
        //system.assertEquals(quoteRec.size(), 10);
        SBQQ__Quote__c qt = quoteRec;
        Test.startTest();
        QuoteAddressSelectorController  controller = QuoteAddressSelectorController.getQuote(qt.Id);
        id Accountid = customers[0].id;
        QuoteAddressSelectorController.getAddress(Accountid, 'billTo');
        QuoteAddressSelectorController.getAddress(Accountid, 'shipTo');
        QuoteAddressSelectorController.UpdAddressOnQuote(addr.id, quoteString, 'billTo',addressString);
        QuoteAddressSelectorController.UpdAddressOnQuote(addr.id, quoteString, 'shipTo',addressString);
        Test.stopTest();
    }
}