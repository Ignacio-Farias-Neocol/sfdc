public without sharing class QuoteListViewHelper {

    @AuraEnabled(cacheable=true)
    public static List<SBQQ__Quote__c> getQuotes(String entityId, String accountType, String fromDateStr, String toDateStr) {

        String objectName = Id.valueOf(entityId).getSobjectType().getDescribe().getName();

        String quoteTypeFilterValue = 'Renewal';

        String accountId;

        // Convert fromDateStr and toDateStr to Date type to resolve the SOQL Injection
        Date fromDate = String.isBlank(fromDateStr) ? null : Date.valueOf(fromDateStr);
        Date toDate = String.isBlank(toDateStr) ? null : Date.valueOf(toDateStr);

        //If the Objectname is user then get the account Id else call the account method
        if(objectName.equalsIgnoreCase('User')){
          //Get the user information using the logged in user Id
          User communityUser = [Select Contact.AccountId from User where Id = :entityId];
    
          //User Account Id
          accountId = communityUser.Contact.AccountId;
        }
        else{
          accountId = entityId;
        }

        List<String> quoteStatuses = System.Label.g_List_View_Quote_Status.split(','); // Aditya : Added as part of addtion of Quote Status 

        //Need to format  to standard date format “yyyy-MM-dd HH:mm:ss”
        // Date fromDT = new Date(fromDate);
        // Date toDT = new Date(toDate);

        String query;
        query = 'SELECT ' + 
                   'Id, ' +
                   'Name, ' +
                   'SBQQ__Account__r.Name, ' +
                   'SBQQ__Status__c, ' +
                   'SBQQ__Type__c, ' +
                   'Original_Contract_End_Date__c, ' +
                   'SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Reseller__r.Name, ';

        query += '(SELECT ' +
                    'Id, '+
                    'SBQQ__StartDate__c, '+
                    'SBQQ__EndDate__c, '+
                    'Extended_Final_Price__c, '+
                    'SBCF_Serial_Number__c '+
                    'FROM SBQQ__LineItems__r) ';

        query += 'FROM SBQQ__Quote__c '+
                 'WHERE SBQQ__Opportunity2__r.Bill_To_Account__c = :accountId '+
                 'AND SBQQ__Opportunity2__r.isClosed = false '+
                 'AND Original_Contract_End_Date__c >= LAST_N_MONTHS:6 '+
                 'AND Available_on_Portal__c = true '+
                 //'AND (SBQQ__Status__c = \'Approved\' OR SBQQ__Status__c = \'Pending\') '+  // Aditya : Commented as part of addtion of Quote Status
                 'AND SBQQ__Status__c IN :quoteStatuses '+  // Aditya : Added as part of addtion of Quote Status
                 'AND SBQQ__Primary__c = true '+
                 'AND SBQQ__Type__c = :quoteTypeFilterValue '+
                 'AND Original_Contract_End_Date__c >= :fromDate ' +
                 ' AND Original_Contract_End_Date__c <= :toDate';
        query += ' ORDER BY Original_Contract_End_Date__c ASC';

        System.debug('query...'+query);
        List<SBQQ__Quote__c> queryResults = Database.query(query);
        return queryResults;
    }

}