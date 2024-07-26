/**
* @author Yuli Fintescu
* @date 2019-9-29
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description:
*   SFDC-6733 Sonian Direct Sale Quote Enhancements. Set quoteline SBQQ__PackageProductDescription__c
*   SFDC-8689 Move PB to Trigger.
*/
public class DynamicBusinessRuleQuoteLineBefore implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        SetPackageProductDescription(records, oldRecordMap);
    }

    private static void SetPackageProductDescription(List <SObject> records, Map<Id,SObject> oldRecordMap) {
        List<SBQQ__QuoteLine__c> candidates = new List<SBQQ__QuoteLine__c>();
        Set<String> productIds = new Set<String>();

        for (SBQQ__QuoteLine__c ql : (List<SBQQ__QuoteLine__c>)records){
            SBQQ__QuoteLine__c qlOld = oldRecordMap == null ? new SBQQ__QuoteLine__c() : (SBQQ__QuoteLine__c)oldRecordMap.get(ql.Id);
            if (qlOld == null)
                qlOld = new SBQQ__QuoteLine__c();
            
            if (ql.SBQQ__Product__c != qlOld.SBQQ__Product__c || 
                    ql.SBQQ__PackageProductDescription__c != qlOld.SBQQ__PackageProductDescription__c||
                    ql.LastModifiedDate != qlOld.LastModifiedDate) {
                if (ql.SBQQ__Product__c != null)
                    productIds.add(ql.SBQQ__Product__c);

                candidates.add(ql);
            }
        }

        if (candidates.size() > 0) {
            Map<ID, Product2> products = new Map<ID, Product2>();
            if (productIds.size() > 0)
                products = new Map<ID, Product2>([Select ID, Product_Long_Description__c From Product2 Where ID in: productIds]);

            for (SBQQ__QuoteLine__c ql : candidates) {
                Product2 prd = null;
                if (ql.SBQQ__Product__c != null)
                    prd = products.get(ql.SBQQ__Product__c);

                ql.SBQQ__PackageProductDescription__c = (prd == null ? null : prd.Product_Long_Description__c);
            }
        }
    }
}