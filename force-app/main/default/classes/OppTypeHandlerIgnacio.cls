/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-25-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class OppTypeHandlerIgnacio {

    public void setOpportunityType(Id opportunityId, Id accountId, Boolean isMigration, Id amendedContract, Id renewedContract) {

        Savepoint sp = Database.setSavepoint();

        Date threeYearsAgo = Date.today().addYears(-3);
        Date within30Days = Date.today().addDays(-30);

        List<Account> accounts = [SELECT Id, 
                                    (SELECT Id, Active__c, SBQQ__EndDate__c, SBQQ__StartDate__c
                                    FROM SBQQ__Subscriptions__r
                                    WHERE SBQQ__Account__c = :accountId
                                    AND SBQQ__EndDate__c >= :threeYearsAgo
                                    ORDER BY SBQQ__EndDate__c ASC),
                                    (SELECT Id, CloseDate, RecordType.DeveloperName
                                    FROM Opportunities
                                    WHERE AccountId = :accountId
                                    AND Has_Demo_Product__c = false
                                    AND Id != :opportunityId
                                    AND StageName = 'Closed Won'
                                    AND CloseDate >= :threeYearsAgo
                                    ORDER BY CloseDate ASC)
                                    From Account Where Id =: accountId];

        // // Query for subscriptions within the last 3 years
        // List<SBQQ__Subscription__c> subscriptions = [SELECT Id, Active__c, SBQQ__EndDate__c, SBQQ__StartDate__c
        //                                              FROM SBQQ__Subscription__c
        //                                              WHERE SBQQ__Account__c = :accountId
        //                                              AND SBQQ__EndDate__c >= :threeYearsAgo
        //                                              ORDER BY SBQQ__EndDate__c ASC];
        
        // // Query for closed won opportunities within the last 3 years
        // List<Opportunity> opp = [SELECT Id, CloseDate 
        //                                      FROM Opportunity 
        //                                      WHERE AccountId = :accountId
        //                                      AND Has_Demo_Product__c = false
        //                                      AND Id != :opportunityId
        //                                      AND StageName = 'Closed Won'
        //                                      AND CloseDate >= :threeYearsAgo
        //                                      ORDER BY CloseDate ASC];

        List<Opportunity> oppList = new List<Opportunity>(); 
        for(Account acc : accounts){
            Date firstOpptyCloseDate;
            Date lastClosedDate;
            
            if(acc.Opportunities.size() > 0){
                firstOpptyCloseDate = acc.Opportunities[0].CloseDate;
                lastClosedDate = acc.Opportunities[acc.Opportunities.size() - 1].CloseDate;
            }

            // Determine opportunity type
            for(Opportunity opp : acc.Opportunities){
                String opptyType = opp.RecordType.DeveloperName;
                if (isMigration || opptyType == 'Locked_Renewal' || opptyType == 'Renewal' || amendedContract != null || renewedContract != null) {
                    opptyType = 'Existing_Business';
                } else if (acc.SBQQ__Subscriptions__r.isEmpty() && acc.Opportunities.isEmpty()) {
                    opptyType = 'New_Business';
                } else if ((lastClosedDate != null && lastClosedDate > within30Days) || 
                        (firstOpptyCloseDate != null && firstOpptyCloseDate > within30Days) || 
                        (acc.SBQQ__Subscriptions__r.size() > 0 && acc.SBQQ__Subscriptions__r[0].SBQQ__StartDate__c > within30Days)) {
                    opptyType = 'New_Business';
                } else if (acc.SBQQ__Subscriptions__r.isEmpty() && acc.Opportunities.isEmpty()) {
                    opptyType = 'New_Business';
                } else {
                    opptyType = 'Existing_Business';
                }
                oppList.add(opp);
            }
            
        }       

        update oppList;
        Database.RollBack(sp);
    }
    
}