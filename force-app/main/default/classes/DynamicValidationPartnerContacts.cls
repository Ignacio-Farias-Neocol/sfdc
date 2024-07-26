/**
 * Created by hzaw on 10/08/19
 */
public with sharing class DynamicValidationPartnerContacts implements DynamicValidationRule {

    public Set<String> getExpectedFields() {
        return new Set<String> {
        }; // not used in bulk validation in trigger context
    }

    /*******************************************************************************************************
    * @description validate if the partner (disti/reseller) selected contacts has a relationship to the partner account
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */
    public Map<SObject,Boolean> evaluateRule(List<SObject> records) {

        System.debug('~~~ validation Rule DynamicValidationPartnerContacts with ' + records);

        Map<Id, Opportunity> distiAccIdOpp = new Map<Id, Opportunity>();
        Map<Id, Opportunity> resellerAccIdOpp = new Map<Id, Opportunity>();
        For (SObject o : records) {
            Opportunity opp = (Opportunity) o;
            if (opp.Distributor__c != null && opp.Distributor_Contact__c != null) {
                distiAccIdOpp.put(opp.Distributor__c, opp);
            }
            if (opp.Reseller__c != null && opp.Reseller_Contact__c != null) {
                resellerAccIdOpp.put(opp.Reseller__c, opp);
            }
        }

        // get distributor & reseller account contact relationships
        List<AccountContactRelation> accConRel = [
                select AccountId, ContactId from AccountContactRelation where AccountId in :distiAccIdOpp.keySet() OR AccountId in :resellerAccIdOpp.keySet()
        ];

        Set<String> conAccRelList = new Set<String>();

        for (AccountContactRelation acr : accConRel) {
                conAccRelList.add((String)acr.ContactId+(String)acr.AccountId);
        }

        Map<SObject, Boolean> results = new Map<SObject, Boolean>();
        For (SObject o : records) {
            Opportunity opp = (Opportunity) o;
            results.put(opp, true); // set to valid by default
            if (opp.StageName != 'Accepted' && opp.Distributor_Contact__c != null && conAccRelList.contains((String)opp.Distributor_Contact__c+(String)opp.Distributor__c) == false) {
                results.put(opp, false); // this distributor contact is not associated with distributor account
            } else if (opp.StageName != 'Accepted' && opp.Reseller_Contact__c != null && conAccRelList.contains((String)opp.Reseller_Contact__c+(String)opp.Reseller__c) == false) {
                results.put(opp, false); // this reseller contact is not associated with reseller account
            }
        }
        return results;
    }
}