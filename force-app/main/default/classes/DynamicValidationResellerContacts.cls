/**
 * Created by hzaw on 5/13/20
 */
public with sharing class DynamicValidationResellerContacts implements DynamicValidationRule {

    public Set<String> getExpectedFields() {
        return new Set<String> {
        }; // not used in bulk validation in trigger context
    }

    /*******************************************************************************************************
    * @description validate if the partner (reseller) selected contacts has a relationship to the partner account
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */
    public Map<SObject,Boolean> evaluateRule(List<SObject> records) {

        System.debug('~~~ validation Rule DynamicValidationResellerContacts with ' + records);

        Map<Id, Opportunity> resellerAccIdOpp = new Map<Id, Opportunity>();
        For (SObject o : records) {
            Opportunity opp = (Opportunity) o;
            if (opp.StageName != 'Accepted' && opp.Reseller__c != null && opp.Reseller_Contact__c != null) {
                resellerAccIdOpp.put(opp.Reseller__c, opp);
            }
        }

        Set<String> conAccRelList = new Set<String>();
        
        If (!resellerAccIdOpp.isEmpty()) {
            // get reseller account contact relationships
            List<AccountContactRelation> accConRel = [
                select AccountId, ContactId from AccountContactRelation where AccountId in :resellerAccIdOpp.keySet()
            ];

            for (AccountContactRelation acr : accConRel) {
                conAccRelList.add((String)acr.ContactId+(String)acr.AccountId);
            }
        }

        Map<SObject, Boolean> results = new Map<SObject, Boolean>();
        For (SObject o : records) {
            Opportunity opp = (Opportunity) o;
            results.put(opp, true); // set to valid by default
            if (opp.StageName != 'Accepted' && opp.Reseller_Contact__c != null && conAccRelList.contains((String)opp.Reseller_Contact__c+(String)opp.Reseller__c) == false) {
                results.put(opp, false); // this reseller contact is not associated with reseller account
            }
        }
        return results;
    }
}