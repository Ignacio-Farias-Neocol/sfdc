/**
 * @description       : Handler Class to refactor Set Amendment Oppty Owner subflow, called from Opportunity Process Builder.
 * @author            : Ignacio F.
 * @group             : Neocol
 * @last modified on  : 07-23-2024
 * @last modified by  : Ignacio F.
**/
public with sharing class NEO_OpportunityOwner {
    private static Boolean isMethodExecuted = false;
    private static Boolean needsUpdate = false;

    private Set<Id> oppSetForOwnerUpdate = new Set<Id>();
    private List<Opportunity> oppListToUpdate = new List<Opportunity>();

    public void processRecords(Map<Id, SObject> newRecordMap, Map<Id, SObject> oldRecordMap, List<SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
     
        if(isMethodExecuted) {
            return;
        }

        isMethodExecuted = true;
     
        meetsCriteria(oldRecordMap, records);

        try{
            List<Opportunity> oppList = getOpportunities();
            getElegibleOpportunities(oppList);
            updateOpportunityOwner();
        }catch(Exception ex){
            throw new OpportunityOwnerException(ex.getMessage());
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

            Boolean amendmentContractNotNull = opp.SBQQ__AmendedContract__c != null;
            Boolean primaryQuoteNotNull = opp.SBQQ__PrimaryQuote__c != null; //TODO: Check Primary Quote Type = 'Amendment'
            Boolean elegibleStageName = opp.StageName == 'Commit' || opp.StageName == 'Order in process' || opp.StageName == 'Closed Won';
            Boolean stageNameChanged = NEO_TriggerUtils.checkChangedFields(opp, oldRecord, new List<Schema.SObjectField>{Opportunity.StageName});
            Boolean isCore = opp.Business_Group__c == 'Core'; 
            
            // Reviewing conditions for PB - Opportunity Management - Create/Edit, Node - Oppty Is Amendment
            if ((amendmentContractNotNull || primaryQuoteNotNull) && elegibleStageName && stageNameChanged && isCore) {
                oppSetForOwnerUpdate.add(opp.Id);                
            }
        }
    }

    /**
    * @description Retrieve the necessary fields to check for each applicable Opportunity.
    * @author Ignacio F. | 07-23-2024 
    * @return List<Opportunity> 
    **/
    private List<Opportunity> getOpportunities(){
       return [SELECT Id, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.SBCF_Order_Type__c, SBQQ__PrimaryQuote__r.SBQQ__Type__c, Original_Opportunity__c, Original_Opportunity__r.Owner.IsActive, SBQQ__AmendedContract__r.SBQQ__Opportunity__c, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Owner.IsActive, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.OwnerId, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Owner.ManagerId, SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Owner.Manager.IsActive
                                          FROM Opportunity
                                          WHERE Id IN :oppSetForOwnerUpdate];
    }

    /**
    * @description Process the queried records 
    * @author Ignacio F. | 07-23-2024 
    * @param oppList 
    **/
    private void getElegibleOpportunities(List<Opportunity> oppList) {
        for(Opportunity opp : oppList){
            if ((opp.SBQQ__PrimaryQuote__r.SBCF_Order_Type__c == 'New - Return' || 
                 opp.SBQQ__PrimaryQuote__r.SBCF_Order_Type__c == 'Renewal - Return') && 
                 opp.SBQQ__PrimaryQuote__r.Has_RMA_Replace__c == false) {
                    oppListToUpdate.add(opp);
            }
        }
    }

    /**
    * @description Check conditions of the elegible list of Opportunities.
    * @author Ignacio F. | 07-23-2024 
    **/
    public void updateOpportunityOwner() {
        for(Opportunity opp : oppListToUpdate){
            if (opp.SBQQ__AmendedContract__c != null && opp.SBQQ__AmendedContract__c != '' && opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__c != null) {
                processAmendedContract(opp);
            } else if (opp.SBQQ__PrimaryQuote__c != null && opp.SBQQ__PrimaryQuote__c != '' && opp.SBQQ__PrimaryQuote__r.SBQQ__Type__c == 'Amendment') {
                processAmendmentAsset(opp);
            }
        }
    }

    /**
    * @description Method called from updateOpportunityOwner to process the opps with Amended Contract
    * @author Ignacio F. | 07-23-2024 
    * @param opp 
    **/
    private void processAmendedContract(Opportunity opp) {
        if(opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__c != null){
            if (opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Owner.IsActive) {
                setOpportunityOwner(opp, opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.OwnerId);
            } else if(opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Owner.Manager.IsActive) {
                setOpportunityOwner(opp, opp.SBQQ__AmendedContract__r.SBQQ__Opportunity__r.Owner.ManagerId);
            }
        }
    }

    /**
    * @description Method called from updateOpportunityOwner to process the opps with Amended Asset
    * @author Ignacio F. | 07-23-2024 
    * @param opp 
    **/
    private void processAmendmentAsset(Opportunity opp){
        if(opp.Original_Opportunity__c != '' && opp.Original_Opportunity__r.Owner.IsActive){
            setOpportunityOwner(opp, opp.Original_Opportunity__r.OwnerId);
        }else if(opp.Original_Opportunity__r.Owner.ManagerId != ''){
            setOpportunityOwner(opp, opp.Original_Opportunity__r.Owner.ManagerId);
        }
    }

    /**
    * @description Generic method to set the OwnerId of the Opportunity.
    * @author Ignacio F. | 07-23-2024 
    * @param opp 
    * @param newOwnerId 
    **/
    private void setOpportunityOwner(Opportunity opp, Id newOwnerId) {
        opp.OwnerId = newOwnerId;
    }

    public class OpportunityOwnerException extends Exception{}
}


