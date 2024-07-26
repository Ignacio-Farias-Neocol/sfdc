public with sharing class OpportunitySelector {

    public without sharing class OppSelectorWithoutSharing {

        public List<Opportunity> getOpportunitysByAccount(String accountId) {
            Id newBusinessRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Business').getRecordTypeId();
            return [
                SELECT Id, Name, Account.Name, Owner.Name, CloseDate, StageName, Amount,
                Business_Group__c, Primary_Product_Family_2__c
                FROM Opportunity
                WHERE IsClosed = false
                AND AccountId = :accountId
                AND RecordTypeId = :newBusinessRecordTypeId
                ORDER BY CloseDate DESC
                LIMIT 15
            ];
        }

    }

}