/**
 * Added as part of #SFDC-20369.
 * 
 * Class Name: CreateOppContactRolesRenewCont
 * Description: This batch class creates OpportunityContactRoles on Renewal Opportunity
 *              from it's Contract and Original Opportunity.
 * 
 * @Author:
 * @CreateDate: 22-12-2023
 */
global with sharing class CreateOppContactRolesRenewCont implements Database.Batchable<SObject>, Database.Stateful {
    //public String contractId = '800f2000001Rh6sAAC';
    public String soql = 'select id, name, SBQQ__Opportunity__c, SBQQ__RenewalOpportunity__c, SBQQ__RenewalOpportunity__r.CreatedDate from contract where SBQQ__RenewalOpportunity__c != NULL and SBQQ__Opportunity__c != NULL and (SBQQ__RenewalOpportunity__r.CreatedDate =TODAY OR SBQQ__RenewalOpportunity__r.CreatedDate= YESTERDAY)';
    //public String soql = 'select id, name, SBQQ__Opportunity__c, SBQQ__RenewalOpportunity__c from contract where id =:contractId';
    /**
     * Start Method
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        System.Debug('*** soql ' + soql);
        return Database.getQueryLocator(soql);
    }
    /**
     * Execute Method
     */
    global void execute(Database.BatchableContext BC, List<Contract> contractList){
        Set<String> OppContactRoleSet = new Set<String>();
        Map<String, OpportunityContactRole> mapOppConRole = new Map<String, OpportunityContactRole>();
        Set<ID> originalOppIds = new set<ID>(); 
        Set<ID> renewOppIds = new set<ID>(); 
        Map<ID, ID> OppMap =  new Map<ID, ID>();
        List<OpportunityContactRole> lstOppConRole = new List<OpportunityContactRole>();
        List<OpportunityContactRole> lstRenewOppConRole = new List<OpportunityContactRole>();
        List<OpportunityContactRole> newOppConRolist = new List<OpportunityContactRole>();
        String strCumKey = '';
        String strDistKey = '';
        String strResellKey = '';
        try{
            for(Contract contr: contractList){
                originalOppIds.add(contr.SBQQ__Opportunity__c);
                renewOppIds.add(contr.SBQQ__RenewalOpportunity__c);
                OppMap.put(contr.SBQQ__Opportunity__c, contr.SBQQ__RenewalOpportunity__c);
            }
            if(!originalOppIds.isEmpty()){
                lstOppConRole = [select id, OpportunityId, ContactId, Role from OpportunityContactRole where OpportunityId in :originalOppIds];
                for(OpportunityContactRole oppConRol : lstOppConRole){
                    mapOppConRole.put(String.valueOf(oppConRol.OpportunityId)+String.valueOf(oppConRol.ContactId)+oppConRol.Role, oppConRol);
                    //OppContactRoleSet.add(String.valueOf(oppConRol.OpportunityId)+String.valueOf(oppConRol.ContactId)+oppConRol.Role);
                }
            }if(!renewOppIds.isEmpty()){
                lstRenewOppConRole = [select id, OpportunityId, ContactId, Role from OpportunityContactRole where OpportunityId in :renewOppIds];
                for(OpportunityContactRole rOppConRol : lstRenewOppConRole){
                    OppContactRoleSet.add(String.valueOf(rOppConRol.OpportunityId)+String.valueOf(rOppConRol.ContactId)+rOppConRol.Role);
                }
            }
            for(OpportunityContactRole oppConRol01 : mapOppConRole.values()){
                if(OppMap.containsKey(oppConRol01.OpportunityId) && !OppContactRoleSet.contains(String.valueOf(OppMap.get(oppConRol01.OpportunityId))+String.valueOf(oppConRol01.ContactId)+oppConRol01.Role)){
                    OpportunityContactRole oppConRol02 = new OpportunityContactRole();
                    oppConRol02.OpportunityId = OppMap.get(oppConRol01.OpportunityId);
                    oppConRol02.ContactId = oppConRol01.ContactId;
                    oppConRol02.Role = oppConRol01.Role;
                    newOppConRolist.add(oppConRol02);
                }
            }
            if(!newOppConRolist.isEmpty()){
                insert newOppConRolist;
            }
        }Catch(Exception e){
            System.debug('Exception'+e.getMessage()+'Occurred At'+e.getStackTraceString());
        }
    }
    /**
     * Finish Method 
     */
    global void finish(Database.BatchableContext BC){}
}