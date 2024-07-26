/**
 * @description       : Updates Opportunities' HotLists based on certain conditions
 * @author            : Ignacio F.
 * @group             : Neocol
 * @last modified on  : 07-19-2024
 * @last modified by  : Ignacio F.
**/
public with sharing class NEO_OpportunityUpdateRelatedHotList implements DynamicBusinessRuleAction {
    
    private static Boolean isMethodExecuted = false;
    Map<Id, SObject> hotListForUpdateMap = new Map<Id, SObject>();
    private List<Opportunity> oppListForUpsellAmendmentOrRenewal = new List<Opportunity>();

    public void processRecords(Map<Id, SObject> newRecordMap, Map<Id, SObject> oldRecordMap, List<SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
     
        if ( isMethodExecuted ) {
            return;
        }
        isMethodExecuted = true;
     
        meetsCriteria(records, oldRecordMap);

        if(oppListForUpsellAmendmentOrRenewal.isEmpty()){
            return;
        }

        try{
            Map<Id, Opportunity> opportunitiesMap = getOpportunities();

            updateOppUpsellAmendmentOrRenewal(opportunitiesMap);
            updateHotLists();
        } catch(Exception ex) {
            throw new OpportunityUpdateRelatedHotListException(ex.getMessage());
        }
    }

    /**
    * @description Review if the records meet the criteria to add them to a list of Opportunities to process
    * @author Ignacio F. | 07-15-2024 
    * @param records 
    * @param oldRecordMap 
    **/
    private void meetsCriteria(List<SObject> records, Map<Id, SObject> oldRecordMap){

        for ( SObject record : records ) {
            Opportunity opp = (Opportunity) record;
            Opportunity oldRecord = (Opportunity) oldRecordMap.get(opp.Id);
            // Reviewing conditions for PB - Opportunity Management - Create/Edit, Node - Is New (Upsell Amendment OR Upsell Renewal)
            if ( oldRecord == null && (opp.SBQQ__AmendedContract__c != null || opp.SBQQ__RenewedContract__c != null )) {
                oppListForUpsellAmendmentOrRenewal.add(opp);
            }
        }
    }

    /**
    * @description Updates the HotList object based on the values of the map hotListForUpdateMap
    * @author Ignacio F. | 07-15-2024 
    **/
    private void updateHotLists() {
        if ( !hotListForUpdateMap.isEmpty() ) {
            update hotListForUpdateMap.values();
        }
    }

    /**
    * @description Retrieves the applicable opportunities to check lookup fields afterwards.
    * @author Ignacio F. | 07-16-2024 
    * @return Map<Id, Opportunity> 
    **/
    private Map<Id, Opportunity> getOpportunities() {
        Set<Id> oppIds = new Set<Id>();

        for(Opportunity opp: oppListForUpsellAmendmentOrRenewal){
            oppIds.add(opp.Id);
        }

        return new Map<Id, Opportunity>(
            [ SELECT Id, Hot_List__c, SBQQ__AmendedContract__r.Most_Recent_Upsell_Hot_List__c, SBQQ__RenewedContract__r.Most_Recent_Upsell_Hot_List__c FROM Opportunity Where Id IN: oppIds ]
        );
    }

    /**
    * @description Updates related fields if criteria is met.
    * @author Ignacio F. | 07-16-2024 
    * @param opportunityMap 
    **/
    private void updateOppUpsellAmendmentOrRenewal(Map<Id, Opportunity> opportunityMap) {
        
        for(Opportunity opp : opportunityMap.values()){
            if(opp.SBQQ__AmendedContract__r.Most_Recent_Upsell_Hot_List__c != null || opp.SBQQ__RenewedContract__r.Most_Recent_Upsell_Hot_List__c != null){        
                Hot_List__c hotlistforUpdate = (Hot_List__c) NEO_TriggerUtils.getRecordFromMap(hotListForUpdateMap, opp.Hot_List__c);
                hotlistforUpdate.Converted_Opportunity__c = opp.Id;
                hotlistforUpdate.Disposition__c = 'Converted';
            }
        } 
    }

    public class OpportunityUpdateRelatedHotListException extends Exception{}
}