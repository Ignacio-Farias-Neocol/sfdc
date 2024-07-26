/**
 * @description       : Handler Class to refactor Set Default Credit Card subflow, called from Opportunity Process Builder.

 * @author            : Ignacio F.
 * @group             : 
 * @last modified on  : 07-01-2024
 * @last modified by  : Ignacio F.
**/
public class OpportunitySetDefaultCreditCard implements DynamicBusinessRuleAction {

    public void processRecords(Map<Id, SObject> newRecordMap, Map<Id, SObject> oldRecordMap, List<SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        
        if(!meetsCriteria(oldRecordMap, newRecordMap, records)){
            return;
        }

        List<Opportunity> oppList = newRecordMap.values().isEmpty() ? (List<Opportunity>)records :(List<Opportunity>)newRecordMap.values();

        handleOpportunities(oppList);
    }

    /**
    * @description 
    * @author Ignacio F. | 07-01-2024 
    * @param oppList 
    **/
    public static void handleOpportunities(List<Opportunity> oppList) {
        try {

            Set<Id> accountSet = new set<Id>();
            for (Opportunity opp : oppList) {
                accountSet.add(opp.accountId);
            }

            // Get accounts with payment terms and related default credit cards in one query
            Map<Id, Account> accountsWithCreditCards = getAccountsWithPaymentTermsAndCreditCards(accountSet);
            // Map opportunities to their respective credit cards
            for (Opportunity opp : oppList) {
                if (accountsWithCreditCards.containsKey(opp.AccountId)) {
                    Account account = accountsWithCreditCards.get(opp.AccountId);
                    if (account.Payment_Terms__c == 'Credit Card' && !account.Credit_Cards__r.isEmpty()) {
                        opp.Bill_To_Credit_Card__c = account.Credit_Cards__r[0].Id;
                    }
                }
            }

        } catch (Exception ex) {
            throw new OpportunitySetDefaultCreditCardException(ex.getMessage());
        }
    }

    /**
    * @description 
    * @author Ignacio F. | 07-01-2024 
    * @param accountSet - Accounts related to the Opportunity.
    * @return Map<Id, Account> 
    **/
    private static Map<Id, Account> getAccountsWithPaymentTermsAndCreditCards(Set<Id> accountSet) {
        Map<Id, Account> accountsMap = new Map<Id, Account>();
        for (Account acc : [
            SELECT Id, Payment_Terms__c, 
                    (SELECT Id FROM Credit_Cards__r WHERE Is_Default__c = true)
            FROM Account 
            WHERE Id IN :accountSet
        ]) {
            accountsMap.put(acc.Id, acc);
        }
        return accountsMap;
    }


    /**
    * @description Method to check initial conditions.
    * @author Ignacio F. | 07-01-2024 
    * @param oldRecordMap 
    * @param newRecordMap 
    * @param records 
    * @return Boolean 
    **/
    public static Boolean meetsCriteria( Map<Id, SObject> oldRecordMap,  Map<Id, SObject> newRecordMap, List<SObject> records){
        for (Id recordId : newRecordMap.keySet()) {
            // Check if the record exists in the old map
            SObject oldRecord = oldRecordMap.get(recordId);
            SObject newRecord = newRecordMap.get(recordId);
            if (oldRecordMap.containsKey(recordId)) {
                //TODO.
            }else if(isNewOrRelevantFieldsChanged((Opportunity)newRecord, (Opportunity)oldRecord)) {
                return true;
            }
        }
        
        for(Opportunity opp: (List<Opportunity>) records){
            if(isNewOrRelevantFieldsChanged(opp, null)) {
                return true;
            }
        }

        return false;
    }

    /**
    * @description - Initial criteria check for New Opportunity records.
    * @author Ignacio F. | 07-01-2024 
    * @param opp 
    * @param oldOpp 
    * @return Boolean 
    **/
    public static Boolean isNewOrRelevantFieldsChanged(Opportunity opp, Opportunity oldOpp) {
        Boolean isNew = oldOpp == null;
        Boolean amendedContractNotNull = opp.SBQQ__AmendedContract__c == null;
        Boolean renewedContractNotNull = opp.SBQQ__RenewedContract__c == null;        
    
        if ((isNew && amendedContractNotNull && renewedContractNotNull)) {
            return true;
        }
        return false;
    }

    public class OpportunitySetDefaultCreditCardException extends Exception {}

}
