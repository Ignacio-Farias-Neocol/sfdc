/**
* @author IY
* @date 2018
*
* @group DynmaicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to creation of premium support case entitlement
*              this rule is activated when a subscription with premimum support is inserted
* Modifications
* SFDC-9063: Setting the Entitlement start date to a day before Subscription start date
*/
public with sharing class DynamicBusinessRulePremEnt implements DynamicBusinessRuleAction {

    
    /*******************************************************************************************************
    * @description  create new entitlement record, based upon the newly created subscription
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */
    public void processRecords(Map<Id,SObject> newRecordMap,  Map<Id,SObject> oldRecordMap,  List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext){
        
        /* No longer needed as part of SFDC-14299

    // assumptions: all of the records have passed the condition of premimum case entitlement
        List <SlaProcess> slaProcesses = [select   Id,  Name from SlaProcess where name = 'Premium Cases' and isActive = true];
        List <Entitlement> entitlements = new List <Entitlement>();
        if (slaProcesses.size() > 0 ){
            for (SObject obj : records) {
                SBQQ__Subscription__c a = (SBQQ__Subscription__c)obj;
                Entitlement e = new Entitlement();
                e.AccountId = a.SBQQ__Account__c;
                if (a.SBQQ__RootId__c != null && a.SBQQ__RootId__c.startsWith('02i')){// this field might not be asset
                    e.AssetId = a.SBQQ__RootId__c;
                }
                e.Subscription__c = a.Id;   // we always have subscription id
                e.Name = a.Name + '-' + 'Premium Support';
                e.StartDate = Date.today().addDays(-1);
                /** SFDC_9063 : Commenting the code that sets the subscription date. 
                    This has been replaced with the logic where Entitlement Start Date is set to a day before Today
                if (a.SBQQ__SubscriptionStartDate__c == null || a.SBQQ__SubscriptionStartDate__c < Date.today()){
                    e.StartDate = Date.today();
                } else {
                    e.StartDate = a.SBQQ__SubscriptionStartDate__c;
                }
                
                e.EndDate = a.SBQQ__SubscriptionEndDate__c;
                e.SlaProcessId = slaProcesses[0].Id;
                entitlements.add(e);
            }
            DML.save(entitlements);
            System.debug('~E~E list of entitlement created:' + entitlements );
        } */

    }


}