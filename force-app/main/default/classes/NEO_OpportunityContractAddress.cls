/**
 * @description       : Handler class to replace Copy Contract address subflow and a node from Opportunity PB.
 * @author            : Ignacio F.
 * @group             : 
 * @last modified on  : 07-17-2024
 * @last modified by  : Ignacio F.
**/
public with sharing class NEO_OpportunityContractAddress implements DynamicBusinessRuleAction{

    private static Boolean isMethodExecuted = false;
    
    private List<Opportunity> oppList = new List<Opportunity>();

    public void processRecords(Map<Id, SObject> newRecordMap, Map<Id, SObject> oldRecordMap, List<SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {

        if(isMethodExecuted) {
            return;
        }

        isMethodExecuted = true;

        meetsCriteria(oldRecordMap,records);

        if(oppList.isEmpty()) {
            return;
        }

        try{
            handleOpportunities();
        }catch(Exception ex){
            throw new OpportunityContractAddressHandlerException(ex.getMessage());
        }
    }

    /**
    * @description 
    * @author Ignacio F. | 07-03-2024 
    * @param oldRecordMap 
    * @param records 
    * @return Boolean   
    **/
    private void meetsCriteria(Map<Id, SObject> oldRecordMap, List<SObject> records){
        for ( SObject record : records ) {
            Opportunity opp = (Opportunity) record;
            Opportunity oldRecord = (Opportunity) oldRecordMap.get(opp.Id);
            // Reviewing conditions for PB - Opportunity Management - Create/Edit, Node - Trigger Type Alignment Run (only trigger)
            if ( opp.Asset_HW_Contract__c != null ) {
                oppList.add(opp);
            }         
        }
    }

    /**
    * @description : Query Contracts with related Billing and Shipping Addresses. Update Opportunities with Addresses if they meet the criteria.
    * @author Ignacio F. | 07-03-2024 
    * @param oppList 
    **/
    public void handleOpportunities() {
        Set<Id> amendedContractIds = new Set<Id>();
        Set<Id> renewedContractIds = new Set<Id>();

        for (Opportunity opp : oppList) {
            if (opp.SBQQ__AmendedContract__c != null) {
                amendedContractIds.add(opp.SBQQ__AmendedContract__c);
            }
            if (opp.SBQQ__RenewedContract__c != null) {
                renewedContractIds.add(opp.SBQQ__RenewedContract__c);
            }
        }

        Map<Id, Contract> amendedContracts = queryContractsWithAddresses(amendedContractIds);
        Map<Id, Contract> renewedContracts = queryContractsWithAddresses(renewedContractIds);

        updateOpportunitiesIfCriteriaMet(amendedContracts, renewedContracts);
    }

    /**
    * @description 
    * @author Ignacio F. | 07-03-2024 
    * @param contractIds Ammended and renewed contracts related to the Opportunity.
    * @return Map<Id, Contract> 
    **/
    private Map<Id, Contract> queryContractsWithAddresses(Set<Id> contractIds) {
        return new Map<Id, Contract>(
            [SELECT Id, BillingStreet, BillingCity, BillingCountry, BillingState, BillingPostalCode, BillingCountryCode, 
                    Billing_Address__c, Shipping_Address__c, Most_Recent_Upsell_Hot_List__c,
                    Billing_Address__r.Street__c, Billing_Address__r.City__c, Billing_Address__r.Country__c, 
                    Billing_Address__r.State__c, Billing_Address__r.Zip_Postal_Code__c, Billing_Address__r.Country_ISO__c, 
                    SBQQ__Opportunity__c, SBQQ__Opportunity__r.Primary_Product_Family_2__c, SBQQ__Opportunity__r.Model_Series__c,
                    ShippingStreet, ShippingCity, ShippingCountry, ShippingState, ShippingPostalCode, ShippingCountryCode,
                    Shipping_Address__r.Street__c, Shipping_Address__r.City__c, Shipping_Address__r.Country__c, 
                    Shipping_Address__r.State__c, Shipping_Address__r.Zip_Postal_Code__c, Shipping_Address__r.Country_ISO__c
                FROM Contract 
                WHERE Id IN :contractIds]
        );
    }

    /**
    * @description 
    * @author Ignacio F. | 07-03-2024 
    * @param oppList 
    * @param amendedContracts 
    * @param renewedContracts 
    **/
    private void updateOpportunitiesIfCriteriaMet(Map<Id, Contract> amendedContracts, Map<Id, Contract> renewedContracts) {
        for (Opportunity opp : oppList) {
            Boolean meetsCriteria = true;

            if (opp.SBQQ__AmendedContract__c != null && amendedContracts.containsKey(opp.SBQQ__AmendedContract__c)) {
                Contract contract = amendedContracts.get(opp.SBQQ__AmendedContract__c);
                meetsCriteria = contract.Most_Recent_Upsell_Hot_List__c == null;
            }

            if (opp.SBQQ__RenewedContract__c != null && renewedContracts.containsKey(opp.SBQQ__RenewedContract__c)) {
                Contract contract = renewedContracts.get(opp.SBQQ__RenewedContract__c);
                meetsCriteria = contract.Most_Recent_Upsell_Hot_List__c == null;
            }

            if (meetsCriteria) {
                Id contractId = opp.SBQQ__AmendedContract__c != null ? opp.SBQQ__AmendedContract__c : opp.SBQQ__RenewedContract__c;
                Contract contract = (amendedContracts.containsKey(contractId) ? amendedContracts.get(contractId) : renewedContracts.get(contractId));
                updateOpportunityAddresses(opp, contract);
                updateOpportunityFromOriginal(opp, contract);
            }
        }
    }

    /**
    * @description : Use ternary operators to check and update billing and shipping address. 
    * @author Ignacio F. | 07-03-2024 
    * @param opp 
    * @param contract 
    **/
    private void updateOpportunityAddresses(Opportunity opp, Contract contract) {
        opp.City__c                      = contract.BillingCity ?? contract.Billing_Address__r?.City__c;
        opp.Country__c                   = contract.BillingCountry ?? contract.Billing_Address__r?.Country__c;
        opp.Country_ISO_Code__c          = contract.BillingCountryCode ?? contract.Billing_Address__r?.Country_ISO__c;
        opp.State__c                     = contract.BillingState ?? contract.Billing_Address__r?.State__c;
        opp.Street__c                    = contract.BillingStreet ?? contract.Billing_Address__r?.Street__c;
        opp.Zip_Postal_Code__c           = contract.BillingPostalCode ?? contract.Billing_Address__r?.Zip_Postal_Code__c;

        opp.Ship_To_City__c              = contract.ShippingCity ?? contract.Shipping_Address__r?.City__c;
        opp.Ship_To_Country__c           = contract.ShippingCountry ?? contract.Shipping_Address__r?.Country__c;
        opp.Ship_To_State__c             = contract.ShippingState ?? contract.Shipping_Address__r?.State__c;
        opp.Ship_To_Street__c            = contract.ShippingStreet ?? contract.Shipping_Address__r?.Street__c;
        opp.Ship_To_Zip_Postal_Code__c   = contract.ShippingPostalCode ?? contract.Shipping_Address__r?.Zip_Postal_Code__c;
        opp.Shipping_Country_ISO_Code__c = contract.ShippingCountryCode ?? contract.Shipping_Address__r?.Country_ISO__c;
    }   


    /**
    * @description : Update the triggered Opportunity with the original opportunity related to the contract.
    * @author Ignacio F. | 07-03-2024 
    * @param opp 
    * @param contract 
    **/
    private void updateOpportunityFromOriginal(Opportunity opp, Contract contract) {
        if (contract.SBQQ__Opportunity__c != null) {
            opp.Primary_Product_Family_2__c = contract.SBQQ__Opportunity__r?.Primary_Product_Family_2__c;
            opp.Model_Series__c             = contract.SBQQ__Opportunity__r?.Model_Series__c;
            opp.PurchaseOrderID__c          = contract.SBQQ__Opportunity__r?.PurchaseOrderID__c;
        }
    }

    public class OpportunityContractAddressHandlerException extends Exception {}
}
