/**
* @author Brian Chong (Slalom)
* @date 2023-11-17
*
* @group 
* @group-content
*
* @description Apex Batch Job which extends FieldUpdateBatch to set IgnoreParentContractedPrices on existing Accounts for SFDC-20274 
*              One-time batch job can be deleted after executing
*/
public without sharing class IgnoreParentContractedPricingBatch extends FieldUpdateBatch {
    public IgnoreParentContractedPricingBatch() {
        super();

        this.fieldValueMap = new Map<SObjectField, Object>{
            Account.SBQQ__IgnoreParentContractedPrices__c => true
        };

        this.conditionsList = new List<String>{
            'Id in (SELECT SBQQ__Account__c from SBQQ__Subscription__c where Active__c = TRUE)',
            'ParentId != NULL'
        };
    }
}