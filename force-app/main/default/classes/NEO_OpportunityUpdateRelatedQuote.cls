/**
 * @description       : Updates related Opportunities based on certain conditions
 * @author            : Ignacio F.
 * @group             : 
 * @last modified on  : 07-19-2024
 * @last modified by  : Ignacio F.
**/
public with sharing class NEO_OpportunityUpdateRelatedQuote implements DynamicBusinessRuleAction{

    private static Boolean isMethodExecuted = false;
    private static Boolean needsUpdate = false;

    private List<Opportunity> oppListForUpdatePrimaryQuote = new List<Opportunity>();
    private Map<Id, SBQQ__Quote__c> quotesForUpdateMap = new Map<Id, SBQQ__Quote__c>();

    public void processRecords(Map<Id, SObject> newRecordMap, Map<Id, SObject> oldRecordMap, List<SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
     
        if(isMethodExecuted) {
            return;
        }

        isMethodExecuted = true;
     
        meetsCriteria(oldRecordMap, records);

        try{
            updatePrimaryQuote();
        }catch(Exception ex){
            throw new OpportunityUpdateRelatedQuoteException(ex.getMessage());
        }
    }

    /**
    * @description Method to check initial criteria.
    * @author Ignacio F. | 07-17-2024 
    * @param oldRecordMap 
    * @param records 
    **/
    private void meetsCriteria(Map<Id, SObject> oldRecordMap, List<SObject> records){
        for ( SObject record : records ) {
            Opportunity opp = (Opportunity) record;
            Opportunity oldRecord = (Opportunity) oldRecordMap.get(opp.Id);
            
            // Reviewing conditions for PB - Opportunity Management - Create/Edit, Node - Update Quote IF It Already Exists
            if (opp.SBQQ__PrimaryQuote__c != null) {
                oppListForUpdatePrimaryQuote.add(opp);                
            }
            // Reviewing conditions for PB - Opportunity Management - Create/Edit, Node - Opp Stage change to Closed Won
            else if(NEO_TriggerUtils.checkChangedFields(opp, oldRecord, new List<Schema.SObjectField>{ Opportunity.StageName }) && opp.StageName == 'Closed Won'){
                oppListForUpdatePrimaryQuote.add(opp);
            }
        }
    }

    /**
    * @description 
    * @author Ignacio F. | 07-08-2024 
    * @param oppList 
    **/
    private void updatePrimaryQuote() {
        Set<Id> oppIdSet = extractOpportunityIds(oppListForUpdatePrimaryQuote);
        if(oppIdSet.isEmpty()) {
            return;
        }

        Map<Id, Opportunity> opportunityMap = queryOpportunities(oppIdSet);

        Map<Id, Opportunity> opportunityQuoteMap = mapOpportunityQuotes(opportunityMap);

        Map<Id, SBQQ__Quote__c> quoteMap = queryQuotes(opportunityQuoteMap);

        processQuotes(opportunityQuoteMap, quoteMap);

        updateQuotes();
    }


    /**
    * @description 
    * @author Ignacio F. | 07-08-2024 
    * @param oppList 
    * @return Set<Id> 
    **/
    private Set<Id> extractOpportunityIds(List<Opportunity> oppList){
        Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp: oppList){
            oppIds.add(opp.Id);
        }
        return oppIds;
    }


    /**
    * @description 
    * @author Ignacio F. | 07-03-2024 
    * @param oppIdSet 
    * @return Map<Id, Opportunity> 
    **/
    private Map<Id, Opportunity> queryOpportunities(Set<Id> oppIdSet) {
        return new Map<Id, Opportunity>([
            SELECT Id, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.ApprovalStatus__c, Auto_Renewal_Eligible_Core__c, Account.MSP_Bill_Day__c, SBQQ__PrimaryQuote__r.SBQQ__StartDate__c
            FROM Opportunity 
            WHERE Id IN :oppIdSet
        ]);
    }

    /**
    * @description 
    * @author Ignacio F. | 07-03-2024 
    * @param opportunityMap 
    * @return Map<Id, Opportunity> 
    **/
    private Map<Id, Opportunity> mapOpportunityQuotes(Map<Id, Opportunity> opportunityMap) {
        Map<Id, Opportunity> opportunityQuoteMap = new Map<Id, Opportunity>();
        for (Opportunity opp : opportunityMap.values()) {
            if (opp.SBQQ__PrimaryQuote__c != null) {
                opportunityQuoteMap.put(opp.SBQQ__PrimaryQuote__c, opp);
            }
        }
        return opportunityQuoteMap;
    }

    /**
    * @description 
    * @author Ignacio F. | 07-03-2024 
    * @param opportunityQuoteMap 
    * @return Map<Id, SBQQ__Quote__c> 
    **/
    private Map<Id, SBQQ__Quote__c> queryQuotes(Map<Id, Opportunity> opportunityQuoteMap) {
        return new Map<Id, SBQQ__Quote__c>([
            SELECT Id, AR_Recalc__c, ApprovalStatus__c, SBQQ__Status__c, SBQQ__Type__c, Business_Group__c
            FROM SBQQ__Quote__c 
            WHERE Id IN :opportunityQuoteMap.keySet()
        ]);
    }

    /**
    * @description 
    * @author Ignacio F. | 07-03-2024 
    * @param opportunityQuoteMap 
    * @param quoteMap 
    * @return List<SBQQ__Quote__c> 
    **/
    private void processQuotes(Map<Id, Opportunity> opportunityQuoteMap, Map<Id, SBQQ__Quote__c> quoteMap) {
        for (Opportunity opp : opportunityQuoteMap.values()) {
            SBQQ__Quote__c quoteRecord = (SBQQ__Quote__c) NEO_TriggerUtils.getRecordFromMap(quotesForUpdateMap, opp.SBQQ__PrimaryQuote__c);
            
            if (quoteRecord != null && opp.SBQQ__PrimaryQuote__r.ApprovalStatus__c != 'Approved' && opp.Auto_Renewal_Eligible_Core__c) {
                quoteRecord.AR_Recalc__c = true;
                quoteRecord.ApprovalStatus__c = 'Approved';
                quoteRecord.SBQQ__Status__c = 'Customer Accepted';
            }
            if(quoteRecord.SBQQ__Type__c == 'Quote' && quoteRecord.Business_Group__c == 'MSP'){
                quoteRecord.SBQQ__StartDate__c = opp.Account.MSP_Bill_Day__c == null ? opp.CloseDate : quoteRecord.SBQQ__StartDate__c;
            }
        }
    }
    
    /**
    * @description 
    * @author Ignacio F. | 07-03-2024 
    * @param quoteList 
    **/
    private void updateQuotes() {
        if ( !quotesForUpdateMap.isEmpty() ) {
            update quotesForUpdateMap.values();
        }
    }

    public class OpportunityUpdateRelatedQuoteException extends Exception{}
}