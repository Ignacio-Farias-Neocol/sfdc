/**
 * @description       : Handler Class to refactor Default Opportunity Type subflow, called from Opportunity Process Builder.
 * @author            : Ignacio F.
 * @group             : Neocol
 * @last modified on  : 07-17-2024
 * @last modified by  : Ignacio F.
**/
public with sharing class NEO_OpportunityBusinessTypeHandler implements DynamicBusinessRuleAction{
    private static Boolean isMethodExecuted = false;

    private List<Opportunity> oppListForTypeAlignment = new List<Opportunity>();
    private List<Opportunity> oppListForStageChange = new List<Opportunity>();
    
    public void processRecords(Map<Id, SObject> newRecordMap, Map<Id, SObject> oldRecordMap, List<SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        
        if(isMethodExecuted) {
            return;
        }
        isMethodExecuted = true;

        meetsCriteria(oldRecordMap, records);

        try{
            if(!oppListForTypeAlignment.isEmpty()) {
                processRecordsForTypeAlignment();
            }
            if(!oppListForStageChange.isEmpty()){
                processRecordsForStageChange();
            }
        }catch(Exception ex){
            throw new OpportunityBusinessTypeHandlerException(ex.getMessage());
        }
    }

    /**
    * @description 
    * @author Ignacio F. | 07-01-2024 
    * @param oldRecordMap 
    * @param records 
    * @return Boolean 
    **/
    private void meetsCriteria(Map<Id, SObject> oldRecordMap, List<sObject> records){
        for ( SObject record : records ) {
            Opportunity opp = (Opportunity) record;
            Opportunity oldRecord = (Opportunity) oldRecordMap.get(opp.Id);
            // Reviewing conditions for PB - Opportunity Management - Create/Edit, Node - Trigger Type Alignment Run (only trigger)
            if ( NEO_TriggerUtils.checkChangedFields(opp, oldRecord, new List<Schema.SObjectField>{Opportunity.Type_Alignment_Run__c}) ) {
                oppListForTypeAlignment.add(opp);
            }
            
            // Reviewing conditions for PB - Opportunity Management - Create/Edit, Node - Oppty Is Closed
            if ( isNewOrChangedStage(opp, oldRecord) ) {
                oppListForStageChange.add(opp);
            }
        }
    }

    /**
    * @description
    * @author Ignacio F. | 07-01-2024 
    * @param opp 
    * @param oldOpp 
    * @return Boolean 
    **/
    private Boolean isNewOrChangedStage(Opportunity opp, Opportunity oldOpp) {
        Boolean isNew = oldOpp == null;
        Boolean isChanged = NEO_TriggerUtils.checkChangedFields(opp, oldOpp, new List<Schema.SObjectField>{Opportunity.StageName});
        Boolean isAcceptedOrNotContacted = opp.StageName == 'Accepted' || opp.StageName == 'Not Contacted';
        Boolean isRelevantStageChange = opp.StageName == 'Accepted' || 
                                        opp.StageName == 'Not Contacted' || 
                                        opp.StageName == 'Closed Won' || 
                                        opp.StageName == 'Closed Lost';
    
        if ((isNew && isAcceptedOrNotContacted) || (isChanged && isRelevantStageChange)) {
            return true;
        }
        return false;
    }

    
    /**
    * @description Process each opportunity for Type Alignment run criteria
    * @author Ignacio F. | 07-17-2024 
    * @param accountMap 
    **/
    private void processRecordsForTypeAlignment(){
        Map<Id, Account> accountMap = getAccountMap(oppListForTypeAlignment);

        for(Opportunity opp : oppListForTypeAlignment){
            processOpportunityType(opp, accountMap.get(opp.AccountId));
        }
    }

    /**
    * @description Process each opportunity for Stage name Criteria
    * @author Ignacio F. | 07-17-2024 
    * @param accountMap 
    **/
    private void processRecordsForStageChange(){
        Map<Id, Account> accountMap = getAccountMap(oppListForStageChange);

        for(Opportunity opp : oppListForStageChange){
            processOpportunityType(opp, accountMap.get(opp.AccountId));
        }
    }


    /**
    * @description Method to query to get all necessary data with parent-child subqueries
    * @author Ignacio F. | 07-17-2024 
    * @return Map<Id, Account> 
    **/
    private Map<Id, Account> getAccountMap(List<Opportunity> oppList){
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : oppList) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }

        return new Map<Id, Account>([
            SELECT Id, 
            (SELECT Active__c, Id, SBQQ__EndDate__c, SBQQ__StartDate__c 
            FROM SBQQ__Subscriptions__r 
            WHERE SBQQ__EndDate__c >= :System.today().addYears(-3)
            ORDER BY SBQQ__StartDate__c DESC),
            (SELECT Id, CloseDate, RecordType_Name__c, SBQQ__AmendedContract__c, SBQQ__RenewedContract__c
            FROM Opportunities 
            WHERE StageName = 'Closed Won' 
            AND Has_Demo_Product__c = false 
            AND CloseDate >= :System.today().addYears(-3) 
            ORDER BY CloseDate DESC)
            FROM Account 
            WHERE Id IN :accountIds
        ]);
    }

    /**
    * @description Proccess each Opportunity to determine Opportunity Type
    * @author Ignacio F. | 07-01-2024 
    * @param opp - Original Opportunity.
    * @param account - Account related to Original Opportunity.
    **/
    private void processOpportunityType(Opportunity opp, Account account) {
        if (account != null) {
            Date currOpptyClosedDate = opp.CloseDate;
            Date threeYearsAgo = currOpptyClosedDate.addYears(-3);
            Date within30Days = currOpptyClosedDate.addDays(-30);

            List<SBQQ__Subscription__c> subscriptions = account.SBQQ__Subscriptions__r ?? new List<SBQQ__Subscription__c>();
            List<Opportunity> closedWonOpptys = account.Opportunities ?? new List<Opportunity>();

            SBQQ__Subscription__c latestCloseDateSub = subscriptions.isEmpty() ? null : subscriptions[0];
            SBQQ__Subscription__c earliestCloseDateSub = subscriptions.isEmpty() ? null : subscriptions[subscriptions.size() - 1];
            
            Opportunity latestCloseDateOpp = closedWonOpptys.isEmpty() ? null : closedWonOpptys[0];
            Opportunity earliestCloseDateOpp = closedWonOpptys.isEmpty() ? null : closedWonOpptys[closedWonOpptys.size() - 1];

            // Update opportunity type field based on conditions.
            updateOpportunityType(opp, latestCloseDateOpp, earliestCloseDateOpp, latestCloseDateSub, earliestCloseDateSub, within30Days);
        }
    }   

    /**
    * @description 
    * @author Ignacio F. | 07-01-2024 
    * @param opp - Original Opportunity.
    * @param latestCloseDateOpp - first Opportunity related to Account.
    * @param earliestCloseDateOpp - last Opportunity related to Account
    * @param latestCloseDateSub - first Subscription related to Account.
    * @param earliestCloseDateSub - last Subscription related to Account.
    * @param within30Days : Date variable to check if date is within 30 days.
    **/
    public void updateOpportunityType(Opportunity opp, Opportunity latestCloseDateOpp, Opportunity earliestCloseDateOpp, SBQQ__Subscription__c latestCloseDateSub, SBQQ__Subscription__c earliestCloseDateSub, Date within30Days) {
        if (isMigrationOpportunity(opp)) {
            setExistingBusiness(opp);
        } else if (isRenewalOpportunity(opp)) {
            setExistingBusiness(opp);
        } else if (allIdsNull(latestCloseDateSub, latestCloseDateOpp, earliestCloseDateOpp, earliestCloseDateSub)) {
            setNewBusiness(opp);
        } else if (allDatesAfterWithin(latestCloseDateOpp, earliestCloseDateOpp, latestCloseDateSub, earliestCloseDateSub, within30Days)) {
            setNewBusiness(opp);
        } else if (datesAfterWithNull(latestCloseDateOpp, earliestCloseDateOpp, earliestCloseDateSub, within30Days)) {
            setNewBusiness(opp);
        } else if (closeDateIsInLast30Days(latestCloseDateOpp, earliestCloseDateOpp, latestCloseDateSub, earliestCloseDateSub, within30Days)) {
            setNewBusiness(opp);
        } else if (closeDateIsInLast30DaysNoSubs(latestCloseDateOpp, earliestCloseDateOpp, latestCloseDateSub, earliestCloseDateSub, within30Days)) {
            setNewBusiness(opp);
        } else if (noClosedWonOpptysWithStartDateInLast30Days(latestCloseDateOpp, earliestCloseDateSub, within30Days)) {
            setNewBusiness(opp);
        } else {
            setExistingBusiness(opp);
        }
    }

    /**
    * @description 
    * @author Ignacio F. | 07-01-2024 
    * @param opp - Original Opportunity.
    * @return Boolean 
    **/
    private Boolean isMigrationOpportunity(Opportunity opp) {
        return opp.Migration__c;
    }

    /**
    * @description 
    * @author Ignacio F. | 07-01-2024 
    * @param opp - Original Opportunity.
    * @return Boolean 
    **/
    private Boolean isRenewalOpportunity(Opportunity opp) {
        return (opp.RecordType_Name__c == 'Locked_Renewal' || 
            opp.RecordType_Name__c == 'Renewal' || 
            opp.SBQQ__AmendedContract__c != null || 
            opp.SBQQ__RenewedContract__c != null);
    }

    /**
    * @description 
    * @author Ignacio F. | 07-01-2024 
    * @param latestCloseDateOpp - first Opportunity related to Account.
    * @param earliestCloseDateOpp - last Opportunity related to Account
    * @param latestCloseDateSub - first Subscription related to Account.
    * @param earliestCloseDateSub - last Subscription related to Account.
    * @return Boolean 
    **/
    private Boolean allIdsNull(SBQQ__Subscription__c latestCloseDateSub, Opportunity latestCloseDateOpp, Opportunity earliestCloseDateOpp, SBQQ__Subscription__c earliestCloseDateSub) {
        return (latestCloseDateSub?.Id   == null && 
                latestCloseDateOpp?.Id   == null && 
                earliestCloseDateOpp?.Id == null && 
                earliestCloseDateSub?.Id == null);
    }

    /**
    * @description 
    * @author Ignacio F. | 07-01-2024 
    * @param latestCloseDateOpp - first Opportunity related to Account.
    * @param earliestCloseDateOpp - last Opportunity related to Account
    * @param latestCloseDateSub - first Subscription related to Account.
    * @param earliestCloseDateSub - last Subscription related to Account.
    * @param within30Days : Date variable to check if date is within 30 days.
    * @return Boolean 
    **/
    private Boolean allDatesAfterWithin(Opportunity latestCloseDateOpp, Opportunity earliestCloseDateOpp, SBQQ__Subscription__c latestCloseDateSub, SBQQ__Subscription__c earliestCloseDateSub, Date within30Days) {
        return (isDateAfterWithin(latestCloseDateOpp, within30Days) && isDateAfterWithin(earliestCloseDateOpp, within30Days) &&
                isDateAfterWithin(latestCloseDateSub, within30Days) && isDateAfterWithin(earliestCloseDateSub, within30Days)) ||
            (isDateAfterWithin(latestCloseDateOpp, within30Days) && isDateAfterWithin(earliestCloseDateOpp, within30Days) &&
                earliestCloseDateOpp == null && earliestCloseDateSub == null);
    }

    /**
    * @description 
    * @author Ignacio F. | 07-01-2024 
    * @param latestCloseDateOpp - first Opportunity related to Account.
    * @param earliestCloseDateOpp - last Opportunity related to Account
    * @param earliestCloseDateSub - last Subscription related to Account.
    * @param within30Days : Date variable to check if date is within 30 days.
    * @return Boolean 
    **/
    private Boolean datesAfterWithNull(Opportunity latestCloseDateOpp, Opportunity earliestCloseDateOpp, SBQQ__Subscription__c earliestCloseDateSub, Date within30Days) {
        return latestCloseDateOpp == null && earliestCloseDateOpp == null &&
            isDateAfterWithin(earliestCloseDateSub, within30Days);
    }

    /**
    * @description Checks if the close date is within the last 30 days.
    * @author Ignacio F. | 07-01-2024 
    * @param latestCloseDateOpp - latest Opportunity related to Account.
    * @param earliestCloseDateOpp - earliest Opportunity related to Account.
    * @param latestCloseDateSub - latest Subscription related to Account.
    * @param earliestCloseDateSub - earliest Subscription related to Account.
    * @param within30Days : Date variable to check if date is within 30 days.
    * @return Boolean 
    **/
    private Boolean closeDateIsInLast30Days(Opportunity latestCloseDateOpp, Opportunity earliestCloseDateOpp, SBQQ__Subscription__c latestCloseDateSub, SBQQ__Subscription__c earliestCloseDateSub, Date within30Days) {
        return (isDateAfterWithin(latestCloseDateOpp, within30Days) && isDateAfterWithin(earliestCloseDateOpp, within30Days)) ||
               (isDateAfterWithin(latestCloseDateSub, within30Days) && isDateAfterWithin(earliestCloseDateSub, within30Days));
    }

    /**
    * @description Checks if the close date is within the last 30 days and no subscriptions.
    * @author Ignacio F. | 07-01-2024 
    * @param latestCloseDateOpp - latest Opportunity related to Account.
    * @param earliestCloseDateOpp - earliest Opportunity related to Account.
    * @param latestCloseDateSub - latest Subscription related to Account.
    * @param earliestCloseDateSub - earliest Subscription related to Account.
    * @param within30Days : Date variable to check if date is within 30 days.
    * @return Boolean 
    **/
    private Boolean closeDateIsInLast30DaysNoSubs(Opportunity latestCloseDateOpp, Opportunity earliestCloseDateOpp, SBQQ__Subscription__c latestCloseDateSub, SBQQ__Subscription__c earliestCloseDateSub, Date within30Days) {
        return (isDateAfterWithin(latestCloseDateOpp, within30Days) && isDateAfterWithin(earliestCloseDateOpp, within30Days) &&
                latestCloseDateSub == null && earliestCloseDateSub == null);
    }

    /**
    * @description Checks if there are no closed won opportunities with start date in the last 30 days.
    * @author Ignacio F. | 07-01-2024 
    * @param latestCloseDateOpp - latest Opportunity related to Account.
    * @param earliestCloseDateSub - earliest Subscription related to Account.
    * @param within30Days : Date variable to check if date is within 30 days.
    * @return Boolean 
    **/
    private Boolean noClosedWonOpptysWithStartDateInLast30Days(Opportunity latestCloseDateOpp, SBQQ__Subscription__c earliestCloseDateSub, Date within30Days) {
        return (latestCloseDateOpp == null && 
                isDateAfterWithin(earliestCloseDateSub, within30Days));
    }
    
    /**
    * @description 
    * @author Ignacio F. | 07-01-2024 
    * @param record - Opportunity or Subscription record.
    * @param withinDate 
    * @return Boolean 
    **/
    private Boolean isDateAfterWithin(SObject record, Date withinDate) {
        if (record instanceof Opportunity) {
            return ((Opportunity)record).CloseDate != null && ((Opportunity)record).CloseDate > withinDate;
        } else if (record instanceof SBQQ__Subscription__c) {
            return ((SBQQ__Subscription__c)record).SBQQ__StartDate__c != null && ((SBQQ__Subscription__c)record).SBQQ__StartDate__c > withinDate;
        }
        return false;
    }

    /**
    * @description 
    * @author Ignacio F. | 07-01-2024 
    * @param opp - Original Opportunity.
    **/
    private void setExistingBusiness(Opportunity opp) {
        opp.Type = 'Existing Business';
        return;
    }

    /**
    * @description 
    * @author Ignacio F. | 07-01-2024 
    * @param opp - Original Opportunity.
    **/
    private void setNewBusiness(Opportunity opp) {
        opp.Type = 'New Business';
        return;
    }

   public class OpportunityBusinessTypeHandlerException extends Exception {}
}