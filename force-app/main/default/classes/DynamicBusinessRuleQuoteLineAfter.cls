/**
* @author Yuli Fintescu
* @date 2019-9-29
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description:
*   SFDC-6229 - Spike story for Amending Assets use case ( HWO)
*   SFDC-8689 Move PB to Trigger
*/
public class DynamicBusinessRuleQuoteLineAfter implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        SetOpportunityAmenedHWFields(records, oldRecordMap);
    }

    private static void SetOpportunityAmenedHWFields(List <SObject> records, Map<Id,SObject> oldRecordMap) {
        Set<String> candidates = new Set<String>();

        for (SBQQ__QuoteLine__c ql : (List<SBQQ__QuoteLine__c>)records){
            SBQQ__QuoteLine__c qlOld = oldRecordMap == null ? new SBQQ__QuoteLine__c() : (SBQQ__QuoteLine__c)oldRecordMap.get(ql.Id);
            if (qlOld == null)
                qlOld = new SBQQ__QuoteLine__c();
                
            if (ql.SBQQ__UpgradedAsset__c != qlOld.SBQQ__UpgradedAsset__c && !String.isEmpty(ql.SBQQ__UpgradedAsset__c)) {
                candidates.add(ql.Id);
            }
        }

        if (candidates.size() > 0) {
            Map<ID, Opportunity> opps = new Map<ID, Opportunity>();

            for (SBQQ__QuoteLine__c ql : [Select ID, Name, 
                                            SBQQ__UpgradedAsset__c, SBQQ__UpgradedAsset__r.Related_Order__c, 
                                            SBQQ__UpgradedAsset__r.Related_Order__r.Active_Contract__c,
                                            SBQQ__Quote__r.SBQQ__Opportunity2__c, 
                                            SBQQ__Quote__r.SBQQ__Opportunity2__r.Asset_HW_Contract__c, 
                                            SBQQ__Quote__r.SBQQ__Opportunity2__r.Asset_HW_Order__c
                                        From SBQQ__QuoteLine__c 
                                        Where SBQQ__Quote__r.SBQQ__Opportunity2__c <> NULL and 
                                            SBQQ__Quote__r.SBQQ__Primary__c = TRUE and
                                            SBQQ__Quote__r.SBQQ__Type__c = 'Amendment' and
                                            ID in: candidates]) {

                if (ql.SBQQ__Quote__r.SBQQ__Opportunity2__r.Asset_HW_Order__c != ql.SBQQ__UpgradedAsset__r.Related_Order__c || ql.SBQQ__Quote__r.SBQQ__Opportunity2__r.Asset_HW_Contract__c != ql.SBQQ__UpgradedAsset__r.Related_Order__r.Active_Contract__c) {
                    opps.put(ql.SBQQ__Quote__r.SBQQ__Opportunity2__c, new Opportunity(ID = ql.SBQQ__Quote__r.SBQQ__Opportunity2__c, Asset_HW_Order__c = ql.SBQQ__UpgradedAsset__r.Related_Order__c, Asset_HW_Contract__c = ql.SBQQ__UpgradedAsset__r.Related_Order__r.Active_Contract__c));
                }

                //if (opps.size() > 0 && !Test.isRunningTest())
                    //update opps.values();
            }
            if (opps.size() > 0 && !Test.isRunningTest())
                update opps.values();
        }
    }
}