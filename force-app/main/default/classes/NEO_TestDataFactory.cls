/**
 * @description       : TestDataFactory Class.
 * @author            : Ignacio F.
 * @group             : 
 * @last modified on  : 07-08-2024
 * @last modified by  : Ignacio F.
**/
@isTest
public with sharing class NEO_TestDataFactory {

    /**
    * @description Updates the given record with the fields and values provided in the map
    * @author santiago.gonzalez@neocol.com | 07-11-2024 
    * @param record 
    * @param fieldsMap 
    **/
    private static void updateRecordWithFieldsMap(SObject record, Map<Schema.SObjectField, Object> fieldsMap) {
        for ( Schema.SObjectField field : fieldsMap.keySet() ) {
            record.put(field, fieldsMap.get(field));
        }
    }

    public static List<Account> createAccounts(Integer numberOfRecords) {
        return createAccounts(numberOfRecords, false, new Map<Schema.SObjectField, Object>{});
    }
    public static List<Account> createAccounts(Integer numberOfRecords, Boolean needToInsert) {
        return createAccounts(numberOfRecords, needToInsert, new Map<Schema.SObjectField, Object>{});
    }
    public static List<Account> createAccounts(Integer numberOfRecords, Boolean needToInsert, Map<Schema.SObjectField, Object> fieldsMap) {
        List<Account> recordsList = new List<Account>();
        for ( Integer i = 0; i < numberOfRecords; i++ ) {
            Account record = new Account(
                Name = 'Test Account ' + i
            );
            updateRecordWithFieldsMap(record, fieldsMap);
            recordsList.add(record);
        }
        if ( needToInsert ) {
            insert recordsList;
        }
        return recordsList;
    }

    public static List<Opportunity> createOpportunities(Integer numberOfRecords) {
        return createOpportunities(numberOfRecords, false, new Map<Schema.SObjectField, Object>{});
    }
    public static List<Opportunity> createOpportunities(Integer numberOfRecords, Boolean needToInsert) {
        return createOpportunities(numberOfRecords, needToInsert, new Map<Schema.SObjectField, Object>{});
    }
    public static List<Opportunity> createOpportunities(Integer numberOfRecords, Boolean needToInsert, Map<Schema.SObjectField, Object> fieldsMap) {
        List<Opportunity> recordsList = new List<Opportunity>();
        for ( Integer i = 0; i < numberOfRecords; i++ ) {
            Opportunity record = new Opportunity(
                Name = 'Test Opportunity ' + i,
                CloseDate = Date.today().addMonths(1),
                StageName = 'Accepted'
            );
            updateRecordWithFieldsMap(record, fieldsMap);
            recordsList.add(record);
        }
        if ( needToInsert ) {
            insert recordsList;
        }
        return recordsList;
    }

    public static List<Contact> createContacts(Integer numberOfRecords) {
        return createContacts(numberOfRecords, false, new Map<Schema.SObjectField, Object>{});
    }
    public static List<Contact> createContacts(Integer numberOfRecords, Boolean needToInsert) {
        return createContacts(numberOfRecords, needToInsert, new Map<Schema.SObjectField, Object>{});
    }
    public static List<Contact> createContacts(Integer numberOfRecords, Boolean needToInsert, Map<Schema.SObjectField, Object> fieldsMap) {
        List<Contact> recordsList = new List<Contact>();
        for ( Integer i = 0; i < numberOfRecords; i++ ) {
            Contact record = new Contact(
                LastName = 'Test Contact ' + i,
                Email = 'test@example.com',
                Phone = '1234567890'
            );
            updateRecordWithFieldsMap(record, fieldsMap);
            recordsList.add(record);
        }
        if ( needToInsert ) {
            insert recordsList;
        }
        return recordsList;
    }

    public static List<Hot_List__c> createHotLists(Integer numberOfRecords) {
        return createHotLists(numberOfRecords, false, new Map<Schema.SObjectField, Object>{});
    }
    public static List<Hot_List__c> createHotLists(Integer numberOfRecords, Boolean needToInsert) {
        return createHotLists(numberOfRecords, needToInsert, new Map<Schema.SObjectField, Object>{});
    }
    public static List<Hot_List__c> createHotLists(Integer numberOfRecords, Boolean needToInsert, Map<Schema.SObjectField, Object> fieldsMap) {
        List<Hot_List__c> recordsList = new List<Hot_List__c>();
        
        // Looks into fieldsMap for Contact__c field, if null, then takes the first contact in the org, if there is none, creates one
        Id contactId = (Id) fieldsMap.get(Hot_List__c.Contact__c) ?? [ SELECT Id FROM Contact LIMIT 1 ].get(0)?.Id ?? createContacts(1, true)[0].Id;

        for ( Integer i = 0; i < numberOfRecords; i++ ) {
            Hot_List__c record = new Hot_List__c(
                Contact__c = contactId
            );
            updateRecordWithFieldsMap(record, fieldsMap);
            recordsList.add(record);
        }
        if ( needToInsert ) {
            insert recordsList;
        }
        return recordsList;
    }

    public static List<SBQQ__Quote__c> createQuotes(Integer numberOfRecords) {
        return createQuotes(numberOfRecords, false, new Map<Schema.SObjectField, Object>{});
    }
    public static List<SBQQ__Quote__c> createQuotes(Integer numberOfRecords, Boolean needToInsert) {
        return createQuotes(numberOfRecords, needToInsert, new Map<Schema.SObjectField, Object>{});
    }
    public static List<SBQQ__Quote__c> createQuotes(Integer numberOfRecords, Boolean needToInsert, Map<Schema.SObjectField, Object> fieldsMap) {
        List<SBQQ__Quote__c> recordsList = new List<SBQQ__Quote__c>();
        
        for ( Integer i = 0; i < numberOfRecords; i++ ) {
            SBQQ__Quote__c record = new SBQQ__Quote__c(
                SBQQ__Primary__c = i == 0,
                SBQQ__PriceBook__c = Test.getStandardPricebookId()
            );
            updateRecordWithFieldsMap(record, fieldsMap);
            recordsList.add(record);
        }
        if ( needToInsert ) {
            insert recordsList;
        }
        return recordsList;
    }

    public static List<Address__c> createAddresses(Integer numberOfRecords) {
        return createAddresses(numberOfRecords, false, new Map<Schema.SObjectField, Object>{});
    }
    public static List<Address__c> createAddresses(Integer numberOfRecords, Boolean needToInsert) {
        return createAddresses(numberOfRecords, needToInsert, new Map<Schema.SObjectField, Object>{});
    }
    public static List<Address__c> createAddresses(Integer numberOfRecords, Boolean needToInsert, Map<Schema.SObjectField, Object> fieldsMap) {
        List<Address__c> recordsList = new List<Address__c>();
        
        // Looks into fieldsMap for Account__c field, if null, then takes the first account in the org, if there is none, creates one
        Id accountId = (Id) fieldsMap.get(Address__c.Account__c) ?? [ SELECT Id FROM Account LIMIT 1 ]?.get(0)?.Id ?? createAccounts(1, true)[0].Id;
        // Looks into fieldsMap for State__c field, if null, then takes the first state in the org, if there is none, creates one
        Id stateId = (Id) fieldsMap.get(Address__c.State__c) ?? [ SELECT Id FROM State__c LIMIT 1 ]?.get(0)?.Id ?? createStates(1, true)[0].Id;
        // Looks into fieldsMap for Country__c field, if null, then takes the first country in the org, if there is none, creates one
        Id countryId = (Id) fieldsMap.get(Address__c.Country__c) ?? [ SELECT Id FROM Country__c LIMIT 1 ]?.get(0)?.Id ?? createCountries(1, true)[0].Id;

        for ( Integer i = 0; i < numberOfRecords; i++ ) {
            Address__c record = new Address__c(
                Country__c = countryId,
                State__c = stateId,
                Account__c = accountId,
                Street__c = '123 Main St',
                City__c = 'Springfield',
                Zip_Postal_Code__c = '12345',
                Type__c = ( Math.mod(i, 2) == 0 ) ? 'Billing' : 'Shipping'
            );
            updateRecordWithFieldsMap(record, fieldsMap);
            recordsList.add(record);
        }
        if ( needToInsert ) {
            insert recordsList;
        }
        return recordsList;
    }

    public static List<Country__c> createCountries(Integer numberOfRecords) {
        return createCountries(numberOfRecords, false, new Map<Schema.SObjectField, Object>{});
    }
    public static List<Country__c> createCountries(Integer numberOfRecords, Boolean needToInsert) {
        return createCountries(numberOfRecords, needToInsert, new Map<Schema.SObjectField, Object>{});
    }
    public static List<Country__c> createCountries(Integer numberOfRecords, Boolean needToInsert, Map<Schema.SObjectField, Object> fieldsMap) {
        List<Country__c> recordsList = new List<Country__c>();
        for ( Integer i = 0; i < numberOfRecords; i++ ) {
            Country__c record = new Country__c(
                Name = 'United States',
                Country_ISO__c = 'US'
            );
            updateRecordWithFieldsMap(record, fieldsMap);
            recordsList.add(record);
        }
        if ( needToInsert ) {
            insert recordsList;
        }
        return recordsList;
    }

    public static List<State__c> createStates(Integer numberOfRecords) {
        return createStates(numberOfRecords, false, new Map<Schema.SObjectField, Object>{});
    }
    public static List<State__c> createStates(Integer numberOfRecords, Boolean needToInsert) {
        return createStates(numberOfRecords, needToInsert, new Map<Schema.SObjectField, Object>{});
    }
    public static List<State__c> createStates(Integer numberOfRecords, Boolean needToInsert, Map<Schema.SObjectField, Object> fieldsMap) {
        List<State__c> recordsList = new List<State__c>();
        
        // Looks into fieldsMap for Country__c field, if null, then takes the first country in the org, if there is none, creates one
        Id countryId = (Id) fieldsMap.get(State__c.Country__c) ?? [ SELECT Id FROM Country__c LIMIT 1 ].get(0)?.Id ?? createCountries(1, true)[0].Id;

        for ( Integer i = 0; i < numberOfRecords; i++ ) {
            State__c record = new State__c(
                Name = 'Missouri',
                State_ISO__c  = 'MO',
                Country__c = countryId
            );
            updateRecordWithFieldsMap(record, fieldsMap);
            recordsList.add(record);
        }
        if ( needToInsert ) {
            insert recordsList;
        }
        return recordsList;
    }















    
    public static List<Account> getPartnerAccounts(Integer numberOfAccounts){
        List<Account> accountList = new List<Account>();
        for(Integer i = 0; i < numberOfAccounts; i++){
            Account acc = new Account(
                Name = 'Test Account ' + i,
                BillingStreet = 'Teston Road',
                BillingCity = 'Vaughan',
                BillingState = 'Ontario',
                BillingCountry = 'Canada',
                BillingPostalCode = 'L4H0L7',
                Type = 'Customer',
                Terr_Theater__c = 'AMERICAS',
                Is_Unit_Test__c = true,
                Territory__c = 'ONTARIO - TERRITORY',
                Terr_Region__c = 'CANADA - REGION',
                recordTypeId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId()
            );
            accountList.add(acc);
        }
        return accountList;
    }

    public static List<Contact> getRelatedContacts(Integer numberOfContacts, Id accId){
        List<Contact> contactList = new List<Contact>();
        for(Integer i = 0 ; i < numberOfContacts; i++){
            Contact acc = new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                AccountId = accId,
                Email = 'test@example.com',
                Phone = '+5989696969' + i,
                CurrencyIsoCode = 'USD'
            );
            contactList.add(acc);
        }
        return contactList;
    } 


    public static List<Address__c> getBillingAddress(Integer numberOfAddress, Id countryId, Id StateId, Id accId){
        List<Address__c> addressList = new List<Address__c>();
        for(Integer i = 0 ; i < numberOfAddress; i++){
            Address__c addr = new Address__c(
                Country__c =countryId,
                State__c = StateId,
                Street__c = '415 Mission Street',
                City__c = 'St. Louis',
                Zip_Postal_Code__c = '94105',
                Type__c = 'Billing',
                Account__c = accId
            );
            addressList.add(addr);
        }
        return addressList;
    }
    
    public static List<Address__c> getShippingAddress(Integer numberOfAddress, Id countryId, Id StateId, Id accId){
        List<Address__c> addressList = new List<Address__c>();
        for(Integer i = 0 ; i < numberOfAddress; i++){
            Address__c addr = new Address__c(
                Country__c = countryId,
                State__c = StateId,
                Street__c = '415 Mission Street',
                City__c = 'St. Louis',
                Zip_Postal_Code__c = '94105',
                Type__c = 'Shipping',
                Account__c = accId
            );
            addressList.add(addr);
        }
        return addressList;
    }

    public static List<Opportunity> getOpportunities(Integer numberOpportunities, Id accId, Id conId){
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < numberOpportunities; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                StageName = 'Accepted',
                CloseDate = Date.today().addDays(30),
                AccountId = accId,
                Primary_Contact__c = conId,
                Bill_To_Account__c = accId,
                Street__c = '123 Billing St ' + i,
                City__c = 'Billing City ' + i,
                Country__c = 'United States',
                State__c = 'Missouri',
                Zip_Postal_Code__c = '12345' + i,
                Country_ISO_Code__c = 'US',
                Ship_To_Street__c = '123 Shipping St ' + i,
                Ship_To_City__c = 'Shipping City ' + i,
                Ship_To_Country__c = 'United States',
                Ship_To_State__c = 'Missouri',
                Ship_To_Zip_Postal_Code__c = '54321' + i,
                Shipping_Country_ISO_Code__c = 'US'
            );
            opps.add(opp);
        }
        return opps;
    }

    /**
     * Creates the product records
     * @param  prefix           | Product name's prefix
     * @param  num              | Quantity of products to be created
     * @param  chargeType       | Charge Type: One-Time | RecurtestQuoteLinesring | Usage
     * @param  billingFrequency | Billing Frequency:  Monthly | Quarterly | Semiannual | Annual | Invoice Plan
     * @param  billingType      | Billing Type: Advance | Arrears
     * @return                  | return a list of product records
     */
    public static List<Product2> createProducts(
        String prefix,
        Integer num,
        String chargeType,
        String billingFrequency
    ) {
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < num; i++) {
            Product2 product = new Product2(
                Name = prefix + ' ' + i,
                ProductCode = prefix + i,
                IsActive = true,
                SBQQ__ChargeType__c = chargeType,
                SBQQ__BillingFrequency__c = billingFrequency,
                SBQQ__SubscriptionTerm__c = chargeType == 'Recurring'
                    ? 1
                    : null,
                SBQQ__SubscriptionPricing__c = chargeType == 'Recurring'
                    ? 'Renewable'
                    : null,
                SBQQ__BillingType__c = chargeType == 'Recurring' 
                    ? 'Arrears' 
                    : null
            );
            products.add(product);
        }
        insert products;
        return products;
    }

    /**
     * Creates a pricebook entry for each product passed in the parameter
     * the unit price is a value between 0 and 100
     * @param  products         | List of products to create the pricebooks for
     * @param  randomUnitPrice  | True if the unitprice should be between 0 and 100 or False if would like to use the specified unit price in the param
     * @param  unitPrice        | uses this value if the randomUnitPrice is False, otherwise ignores the param
     * @param  isoCode          | The ISO code of the currency for these price book entries
     * @param  standardPricebook| The standard Pricebook2 record, optional parameter.
     * @return                  | return a map of Product Id and the pricebookEntry
     */
    public static Map<Id, PricebookEntry> createPricebookEntries(
        List<Product2> products,
        Boolean randomUnitPrice,
        Decimal unitPrice,
        String isoCode,
        Pricebook2 standardPricebook
    ) {
        Map<Id, PricebookEntry> pricebookEntries = new Map<Id, PricebookEntry>();
        Decimal currentUnitPrice = 0;
        Id pricebookId = (standardPricebook != null)
            ? standardPricebook.Id
            : Test.getStandardPricebookId();

        // First, create standard prices in the standard price book
        List<PricebookEntry> standardPrices = new List<PricebookEntry>();
        for (Product2 product : products) {
            currentUnitPrice = randomUnitPrice
                ? Decimal.valueOf((Math.random() * 100))
                : unitPrice;
            PricebookEntry standardPrice = new PricebookEntry(
                Product2Id = product.Id,
                Pricebook2Id = Test.getStandardPricebookId(),
                IsActive = true,
                UnitPrice = currentUnitPrice,
                UseStandardPrice = false
            );
            standardPrices.add(standardPrice);
        }
        insert standardPrices;

        // Now create custom price book entries
        for (Product2 product : products) {
            PricebookEntry pbe = new PricebookEntry(
                Product2Id = product.Id,
                Pricebook2Id = pricebookId,
                IsActive = true,
                UnitPrice = currentUnitPrice, // This could also be a different price for the custom price book
                UseStandardPrice = false
            );
            if (isoCode != null) {
                pbe.CurrencyIsoCode = isoCode;
            }
            pricebookEntries.put(product.Id, pbe);
        }
        insert pricebookEntries.values();

        return pricebookEntries;
    }

    /**
     * Creates a quote.
     * @param num              | The number of quotes to create
     * @param makeFirstPrimary | If true, the first quote will have "Prmary" set to true
     * @return                 | A list of the created quotes
     */
    // public static List<SBQQ__Quote__c> createQuotes(
    //     Integer num,
    //     Boolean makeFirstPrimary
    // ) {
    //     List<SBQQ__Quote__c> records = new List<SBQQ__Quote__c>();
    //     for (Integer i = 0; i < num; i++) {
    //         SBQQ__Quote__c record = new SBQQ__Quote__c(
    //             SBQQ__Primary__c = (i == 0 && makeFirstPrimary),
    //             SBQQ__PriceBook__c = Test.getStandardPricebookId()
    //         );
    //         records.add(record);
    //     }
    //     insert records;
    //     return records;
    // }

    /**
     * Creates quote lines.
     * @param quotes       | The quotes on which to create lines. The same products will be used for every quote.
     * @param products     | The products to use to create quote lines. One line will be created for each product.
     * @param pbe          | The PBEs for the products.
     * @param lineQuantity | The quantity to be used for every line.
     */
    public static List<SBQQ__QuoteLine__c> createQuoteLines(
        List<SBQQ__Quote__c> quotes,
        List<Product2> products,
        Map<Id, PricebookEntry> pbe,
        Integer lineQuantity
    ) {
        List<SBQQ__QuoteLine__c> records = new List<SBQQ__QuoteLine__c>();
        for (SBQQ__Quote__c quote : quotes) {
            Integer productIndex = 0;
            for (Product2 product : products) {
                Decimal unitPrice = pbe.get(product.Id).UnitPrice;

                SBQQ__QuoteLine__c record = new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quote.Id,
                    // Product & Price Book fields:
                    SBQQ__Product__c = product.Id,
                    SBQQ__PricebookEntryId__c = pbe.get(product.Id).Id,
                    SBQQ__RegularPrice__c = unitPrice,
                    SBQQ__NetPrice__c = unitPrice,
                    SBQQ__BillingFrequency__c = product.SBQQ__BillingFrequency__c,
                    SBQQ__BillingType__c = product.SBQQ__BillingType__c,
                    SBQQ__ChargeType__c = product.SBQQ__ChargeType__c,
                    SBQQ__Number__c = productIndex++,
                    SBQQ__ProrateMultiplier__c = 1,
                    SBQQ__DefaultSubscriptionTerm__c = 12,
                    // Quote line fields:
                    SBQQ__Quantity__c = lineQuantity
                );
                records.add(record);
            }
        }
        insert records;
        return records;
    }

    /**
     * Creates a standard Pricebook2 record with the name 'Standard Price Book' and sets it to active.
     *
     * @return                  | Returns the created standard Pricebook2 record
     */
    public static Pricebook2 createStandardPricebook() {
        Pricebook2 standardPricebook = new Pricebook2(
            Name = 'Standard Price Book',
            IsActive = true
        );
        insert standardPricebook;
        return standardPricebook;
    }
}