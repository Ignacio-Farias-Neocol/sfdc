/**
* @author Salesforce Services
* @date 10/29/2020
*
* @group VF Page extension. Opportunity Ownership
*
* @description: VF page extension for running ownership rules
*/
public with sharing class OppOwnerRuleExecutionExt {
    public List<Id> ruleIds {get;set;}
    public String message {get;set;}
    public Boolean showOKButton{get;set;}
    public Boolean runRuleFromRecordPage {get;set;}
    
    //Constructor used when VF page launched from VF page
    public OppOwnerRuleExecutionExt(ApexPages.StandardSetController standardController){
        //Initalise variables exposed to VF page
        ruleIds = new List<Id>();
        message = '';
        showOKButton = false;
        runRuleFromRecordPage = false;
        if(!Test.isRunningTest()) {
            standardController.addFields(new String[] { 'Active__c' });
        }
        //If active rules are selected then get their IDs
        if(standardController.getSelected()!=null && !standardController.getSelected().isEmpty()){
            Set<Id> ruleIdSet = new Set<Id>();
            for(SObject selectedRecord: standardController.getSelected()){
                Opportunity_Ownership_Rule__c oor = (Opportunity_Ownership_Rule__c)selectedRecord;
                if(oor.Active__c){
                    ruleIdSet.add(selectedRecord.Id);
                }
            }

            //Convert set to list
            if(ruleIdSet!=null && !ruleIdSet.isEmpty()){
                ruleIds.addAll(ruleIdSet);
            }            
        }
    }

    //Constructor used when VF page launched from custom action
    public OppOwnerRuleExecutionExt(ApexPages.StandardController standardController){
        //Initalise variables exposed to VF page
        ruleIds = new List<Id>();
        message = '';
        showOKButton = false;
        runRuleFromRecordPage = true;

        if(!Test.isRunningTest()) {
            standardController.addFields(new String[] { 'Active__c' });
        }

        Opportunity_Ownership_Rule__c ruleRecord = (Opportunity_Ownership_Rule__c)standardController.getRecord();
        //If rule is active then get their IDs
        if(ruleRecord!=null && ruleRecord.Active__c){
            ruleIds.add(standardController.getId());          
        }
    }  
}