/**
 * Created by iyeung on 12/14/18.
 */
public with sharing class DynamicValidationCaseSerial implements DynamicValidationRule {

    public Set<String> getExpectedFields() {
        return new Set<String> {
        }; // not used in bulk validation in trigger context
    }

    /*******************************************************************************************************
    * @description validate if the serial selected has a corresponding assigned serial record for the same account
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */
    public Map<SObject,Boolean> evaluateRule(List<SObject> records) {


        System.debug('~~~ validation Rule DynamicValidationCaseSerial with ' + records);

        Map<Id, Case> serialIdCase = new Map<Id, Case>();
        For (SObject o : records) {
            Case c = (Case) o;
            if (c.Serial__c != null) {
                serialIdCase.put(c.Serial__c, c);
            }
        }

        List<Assigned_Serial__c> assignedSerials = [
                select Asset__c, Asset__r.AccountId, Name, Serial__c, Serial_Number__c, Status__c, Subscription__c, Subscription__r.SBQQ__Account__c,
                        Parent_Subscription__c, Parent_Subscription__r.SBQQ__Account__c
                from Assigned_Serial__c
                where Status__c = 'Active' and Serial__c in :serialIdCase.keySet()
        ];


        Map<Id, Id> serialAccountIdMap = new Map<Id, Id>();
        for (Assigned_Serial__c s : assignedSerials) {
            if (s.Asset__r.AccountId != null){
                serialAccountIdMap.put(s.Serial__c, s.Asset__r.AccountId);
            } else if (s.Subscription__r.SBQQ__Account__c != null){ // 2019-07-01 account for asset being null
                serialAccountIdMap.put(s.Serial__c, s.Subscription__r.SBQQ__Account__c );
            } else if (s.Subscription__r.SBQQ__Account__c != null){
                serialAccountIdMap.put(s.Serial__c, s.Subscription__r.SBQQ__Account__c );
            } else if (s.Parent_Subscription__r.SBQQ__Account__c != null){
                serialAccountIdMap.put(s.Serial__c, s.Parent_Subscription__r.SBQQ__Account__c );
            }

        }

        Map<SObject, Boolean> results = new Map<SObject, Boolean>();
        For (SObject o : records) {
            Case c = (Case) o;
            results.put(c, true); // set to valid by default
            if (c.Serial__c != null) {
                Id accId = serialAccountIdMap.get(c.Serial__c);
                if (c.AccountId != accId) {
                    results.put(c, false); // this serial is associated with different account
                }
            }
        }

        return results;

    }



}