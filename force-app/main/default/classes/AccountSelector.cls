public class AccountSelector {

    public without sharing class AccountSelectorWithoutSharing {

        public  List<List<Account>> findByAccountName(Account accountRecord){
            List<List<Account>> searchResults = new List<List<Account>>();

            System.debug('AccountSelector==='+accountRecord); // To be removed

            // If Name is missing, cannot continue with search
            if (String.isBlank(accountRecord.Name)){
                return null;
            }

            // If DnB DUNS Number is available, use it alone with SOQL search
            // If no result with DnB DUNS Number, use Name and/or Website with "NAME FIELDS" SOSL search
            if (!String.isBlank(accountRecord.D_B_DUNS_Number__c)) {
                List<Account> accountResults = findAccountsByDUNS(accountRecord.D_B_DUNS_Number__c);
                if (!accountResults.isEmpty()) {
                    System.debug('DUNS accountResults ===' + accountResults);
                    searchResults.add(accountResults);
                } else {
                    searchResults = findAccountsBySOSL(accountRecord);
                }
            } else {
                // For Name & Website, use "NAME FIELDS" SOSL Search
                searchResults = findAccountsBySOSL(accountRecord);
            }
            return searchResults;
        }

        private List<Account> findAccountsByDUNS(String dunsNumber) {
            System.debug('findAccountsByDUNS::: ' + dunsNumber);
            return [SELECT Id, Name, ParentId, Website, Alternative_Account_Name__c, Type, BusinessGroup__c,
                           D_B_DUNS_Number__c, NumberOfEmployees, DUNS_Number__c, Account_Owner__c,ARR__c,
                           CurrencyIsoCode, BillingCountry, BillingState, BillingPostalCode, BillingCity,
                           BillingStreet, BillingCountryCode, Industry, Phone
                    FROM Account
                    WHERE D_B_DUNS_Number__c = :dunsNumber
                    AND RecordType.DeveloperName != 'Not_Transactional'
                    LIMIT 5];
        }

        private List<List<Account>> findAccountsBySOSL(Account accountRecord) {
            System.debug('findAccountsBySOSL::: ' + accountRecord);

            String searchTerm;
            // For Name & Website, use "NAME FIELDS" SOSL Search Group
            // If Website is available, include it in the search term
            searchTerm = '*' + accountRecord.Name + '*';
            if (!String.isBlank(accountRecord.Website)) {
                searchTerm += ' OR ' + accountRecord.Website;
            }
            System.debug('searchTerm = ' + searchTerm);
            return
            [
                FIND :searchTerm
                IN NAME FIELDS
                RETURNING Account(ParentId,Name,Website,Alternative_Account_Name__c,Type,BusinessGroup__c,D_B_DUNS_Number__c,NumberOfEmployees,DUNS_Number__c,
                    Account_Owner__c,ARR__c,CurrencyIsoCode,BillingCountry,BillingState,BillingPostalCode,BillingCity,BillingStreet,BillingCountryCode,Industry,Phone
                    WHERE BillingCountryCode = :accountRecord.BillingCountryCode
                    AND RecordType.DeveloperName != 'Not_Transactional')
                LIMIT 10
            ];
        }

        public  Account findByAccountId(Id accountId){

            return [ Select Id , name from Account where Id=:accountId];
        }
    }

    public static List<Account> findMatch(Account acc) {
        String soql = 'SELECT Id, Name, Type, Status__c, ParentId FROM Account';
        List<String> conditions = new List<String>();

        // Set up the binding variables
        // if(String.isNotBlank(acc.Name) || String.isNotBlank(acc.D_B_DUNS_Number__c)) {
        //     conditions.add('(Name = \'' + String.escapeSingleQuotes(acc.Name) + '\' OR D_B_DUNS_Number__c = \'' + String.escapeSingleQuotes(acc.D_B_DUNS_Number__c) + '\')');
        // }
        if (String.isNotBlank(acc.Name)) {
            conditions.add('(Name = \'' + String.escapeSingleQuotes(acc.Name) + '\')');
        }

        if (String.isNotBlank(acc.D_B_DUNS_Number__c)) {
            conditions.add('D_B_DUNS_Number__c = \'' + String.escapeSingleQuotes(acc.D_B_DUNS_Number__c) + '\'');
        }

        if (String.isNotBlank(acc.BillingCountry) && String.isNotBlank(acc.BillingState)) {
            conditions.add('(BillingCountry = \'' + String.escapeSingleQuotes(acc.BillingCountry) + '\' AND BillingState = \'' + String.escapeSingleQuotes(acc.BillingState) + '\')');
        } else if (String.isNotBlank(acc.BillingPostalCode)) {
            conditions.add('BillingPostalCode = \'' + String.escapeSingleQuotes(acc.BillingPostalCode) + '\'');
        }

        if (String.isNotBlank(acc.Phone)) {
            conditions.add('Phone = \'' + String.escapeSingleQuotes(acc.Phone) + '\'');
        }

        if (String.isNotBlank(acc.Website)) {
            conditions.add('Website = \'' + String.escapeSingleQuotes(acc.Website) + '\'');
        }

        // Construct the WHERE clause
        if (!conditions.isEmpty()) {
            soql += ' WHERE ' + '(' + String.join(conditions, ' OR ') + ')';
        }
        soql += ' LIMIT 10';

        // Print the SOQL query for debugging
        System.debug('SOQL Query: ' + soql);

        // Execute the SOQL query
        return Database.query(soql);
    }
}