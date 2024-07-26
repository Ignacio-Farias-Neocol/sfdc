/**
 * @description       : Updates Opportunities' Accounts based on certain conditions
 * @author            : santiago.gonzalez@neocol.com
 * @group             : Neocol
 * @last modified on  : 07-10-2024
 * @last modified by  : santiago.gonzalez@neocol.com
**/
public with sharing class NEO_OpportunityUpdateRelatedAccount implements DynamicBusinessRuleAction {
    
    @TestVisible
    private static Boolean isMethodExecuted = false;
    Map<Id, SObject> accountsForUpdateMap = new Map<Id, SObject>();

    private List<Opportunity> oppListForExportComplianceApproval = new List<Opportunity>();
    private List<Opportunity> oppListForOppClosedNotAmendmentOrRenewal = new List<Opportunity>();

    public void processRecords(Map<Id, SObject> newRecordMap, Map<Id, SObject> oldRecordMap, List<SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
     
        if ( isMethodExecuted ) {
            return;
        }
        isMethodExecuted = true;
     
        meetsCriteria(records, oldRecordMap);

        try {
            Map<Id, Opportunity> opportunitiesMap = retrieveAllOpportunities(records);

            updateExportComplianceApproval();
            updateOppClosedNotAmendmentOrRenewal(opportunitiesMap);
            // Final update of the Account object
            updateAccount();
        } catch(Exception ex) {
            throw new OpportunityUpdateRelatedAccountException(ex.getMessage());
        }
    }

    /**
    * @description Review if the records meet the criteria to add them to a list of Opportunities to process
    * @author santiago.gonzalez@neocol.com | 07-10-2024 
    * @param records 
    * @param oldRecordMap 
    **/
    private void meetsCriteria(List<SObject> records, Map<Id, SObject> oldRecordMap) {

        for ( SObject record : records ) {
            Opportunity opp = (Opportunity) record;
            Opportunity oldRecord = (Opportunity) oldRecordMap.get(opp.Id);
            // Reviewing conditions for PB - Opportunity Management - Create/Edit, Node - Check Ship To Account is Govt Customer
            if ( String.isBlank(opp.Export_Compliance_Approved__c) && opp.Export_Approval_Exempt__c && opp.Account_Name_Check_for_Compliance__c && NEO_TriggerUtils.checkChangedFields(opp, oldRecord, new List<Schema.SObjectField>{ Opportunity.Export_Compliance_Approved__c, Opportunity.Export_Approval_Exempt__c, Opportunity.AccountId, Opportunity.Account_Name_Check_for_Compliance__c }) ) {
                oppListForExportComplianceApproval.add(opp);
            }
            // Reviewing conditions for PB - Opportunity Management - Create/Edit, Node - Opp Closed (not Amendment or Renewal))
            if ( opp.StageName == 'Closed Won' && opp.SBQQ__RenewedContract__c == null && opp.SBQQ__AmendedContract__c == null && NEO_TriggerUtils.checkChangedFields(opp, oldRecord, new List<Schema.SObjectField>{ Opportunity.StageName, Opportunity.SBQQ__RenewedContract__c, Opportunity.SBQQ__AmendedContract__c }) ) {
                oppListForOppClosedNotAmendmentOrRenewal.add(opp);
            }
        }
    }

    /**
    * @description Updates the Account object based on the values of the map accountsForUpdateMap
    * @author santiago.gonzalez@neocol.com | 07-10-2024 
    **/
    private void updateAccount() {
        if ( !accountsForUpdateMap.isEmpty() ) {
            for ( Database.SaveResult saveResult : Database.update(accountsForUpdateMap.values(), false) ) {
                if ( !saveResult.isSuccess() ) {
                    for ( Database.Error error : saveResult.getErrors() ) {
                        // TODO - Log error on AppLog - AppLogDetail
                    }
                }
            }
        }
    }

    /**
    * @description Retrieves related records fields from Opportunity
    * @author santiago.gonzalez@neocol.com | 07-11-2024 
    * @param records 
    * @return Map<Id, Opportunity> 
    **/
    private Map<Id, Opportunity> retrieveAllOpportunities(List<SObject> records) {
        return new Map<Id, Opportunity>(
            [ SELECT Id, AccountId, Hot_List__c,
                Account.User_na__c, Account.Partner_Created_Date_MSP__c,
                Hot_List__r.Trial_Create_Date__c, Hot_List__r.Trial_Username__c
              FROM Opportunity 
              WHERE Id IN :records ]
        );
    }

    /**
    * @description Sets the Requires Export Compliance Approval field to true on the Account object 
    * @flow Opportunity Management - Create/Edit 
    * @node Check Ship To Account is Govt Customer 
    * @author santiago.gonzalez@neocol.com | 07-10-2024 
    **/
    private void updateExportComplianceApproval() {
        for ( Opportunity opp : oppListForExportComplianceApproval ) {
            Account accountForUpdate = (Account) NEO_TriggerUtils.getRecordFromMap(accountsForUpdateMap, opp.AccountId);
            accountForUpdate.Requires_Export_Compliance_Approval__c = true;
        }
    }

    /**
    * @description Sets the Account Partner Created Date and Username based on Hot List values
    * @flow Opportunity Management - Create/Edit 
    * @node Opp Closed (not Amendment or Renewal)) 
    * @author santiago.gonzalez@neocol.com | 07-11-2024 
    * @param opportunitiesMap 
    **/
    private void updateOppClosedNotAmendmentOrRenewal(Map<Id, Opportunity> opportunitiesMap) {
        for ( Opportunity opp : oppListForOppClosedNotAmendmentOrRenewal ) {
            Opportunity queriedOpp = opportunitiesMap.get(opp.Id);
            if ( queriedOpp.Account.Partner_Created_Date_MSP__c == null && String.isBlank(queriedOpp.Account.User_na__c) ) {
                Account accountForUpdate = (Account) NEO_TriggerUtils.getRecordFromMap(accountsForUpdateMap, opp.AccountId);
                accountForUpdate.Partner_Created_Date_MSP__c = queriedOpp.Hot_List__r?.Trial_Create_Date__c;
                accountForUpdate.User_na__c = queriedOpp.Hot_List__r?.Trial_Username__c ?? queriedOpp.Account?.User_na__c;
            }
        }
    }

    public class OpportunityUpdateRelatedAccountException extends Exception{}
}