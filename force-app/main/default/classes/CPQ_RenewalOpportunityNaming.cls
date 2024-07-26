/*
Yuli 10/1/2019 Removed from PB. moved to contract trigger, DynamicBusinessRuleContract class
 */
public with sharing class CPQ_RenewalOpportunityNaming {
    @InvocableMethod
    public static void process(List<ID> contractIds) {
        /*Map<Id, Opportunity> oppties = new Map<Id, Opportunity>();
        For (Contract c : [Select ID, SBQQ__RenewalOpportunity__c, SBQQ__RenewalOpportunity__r.Id, 
                                SBQQ__RenewalOpportunity__r.AccountId, 
                                SBQQ__RenewalOpportunity__r.Account.Name,
                                SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c,
                                SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__r.ContractNumber,
                                SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__r.SBQQ__MasterContract__c
                            From Contract 
                            Where Id in: contractIds and SBQQ__RenewalOpportunity__c <> NULL]) {
            String oppName = '';
            
            oppName = oppName + (!String.isEmpty(c.SBQQ__RenewalOpportunity__r.AccountId) && !String.isEmpty(c.SBQQ__RenewalOpportunity__r.Account.Name) ?
                                c.SBQQ__RenewalOpportunity__r.Account.Name.left(62)+ ' - ' : '');
            
            oppName = oppName + 'Renewal Oppty';

            oppName = oppName + (!String.isEmpty(c.SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c) ? 
                                ' - ' + c.SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__r.ContractNumber : '');
            
            oppName = oppName + (!String.isEmpty(c.SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__c) && c.SBQQ__RenewalOpportunity__r.SBQQ__RenewedContract__r.SBQQ__MasterContract__c == TRUE ? 
                                ' - Co-Term' : '');
            
            Opportunity o = new Opportunity(Id = c.SBQQ__RenewalOpportunity__c, Name = oppName);
            oppties.put(c.SBQQ__RenewalOpportunity__c, o);
        }
        
        if (oppties.size() > 0)
            update oppties.values();
        */
    }
}