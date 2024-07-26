public class CPQ_SubscriptionList_Controller {
    @AuraEnabled
    public static SubscriptionResults retrieveSubscriptions(String inputrecordId) {
        SubscriptionResults r = new SubscriptionResults();

        List<Opportunity> records = [Select ID, Name, SBQQ__PrimaryQuote__c From Opportunity Where Id =: inputrecordId];
        if (records.size() == 0) {
            r.errorMsg = 'Opportunity record not found.';
            return r;
        }
        r.record = records[0];

        List<SBQQ__Quote__c> quotes = [Select ID, SBQQ__Type__c From SBQQ__Quote__c Where Id =: r.record.SBQQ__PrimaryQuote__c];
        if (quotes.size() == 0) {
            r.errorMsg = 'The Opportunity has no primary quote.';
            return r;
        }
        r.primaryQuoteId = quotes[0].Id;

        Set<String> renewedSubIds = new Set<String>();
        Set<String> upgradedSubIds = new Set<String>();
        for (SBQQ__QuoteLine__c ql : [Select ID, SBQQ__RenewedSubscription__c, SBQQ__UpgradedSubscription__c From SBQQ__QuoteLine__c Where SBQQ__Quote__c in: quotes]) {
            if (!String.isEmpty(ql.SBQQ__RenewedSubscription__c)) {
                renewedSubIds.add(ql.SBQQ__RenewedSubscription__c);
            }
            
            if (!String.isEmpty(ql.SBQQ__UpgradedSubscription__c)) {
                upgradedSubIds.add(ql.SBQQ__UpgradedSubscription__c);
            }
        }
        
        try {
            r.renewedSubscriptions = getSubscriptions('CPQ_RenewedSubscriptionTabinOpportunity', renewedSubIds);
            r.upgradedSubscriptions = getSubscriptions('CPQ_UpgradedSubscriptionTabinOpportunity', upgradedSubIds);
        } catch (Exception e) {
            r.errorMsg = e.getMessage();
        }
        
        return r;
    }
    
    private static AuraGridResults getSubscriptions(String fieldSetAPIName, Set<String> inputSubIds) {
        AuraGridResults r = new AuraGridResults();
        
        LightningUtility.SearchEntityInfo entity = new LightningUtility.SearchEntityInfo();
        entity.sObjectName = 'SBQQ__Subscription__c';
        entity.sObjectIcon = 'custom:custom39';
        entity.FieldSetAPIName = fieldSetAPIName;
        /*
        entity.displayActions = new List<LightningUtility.ActionDefinition>{
            new LightningUtility.ActionDefinition('View', 'View', '|'), 
            new LightningUtility.ActionDefinition('Edit', 'Edit', '|'), 
            new LightningUtility.ActionDefinition('Delete', 'Delete', '|')
        };
        */
        LightningUtility.SObjectHierarchyResults hr = new LightningUtility.SObjectHierarchyResults(entity);
        
        String soqlFields = String.join(new List<String>(hr.describe.returningFields), ',');
        
        Set<String> subIds = inputSubIds;
        String searchQuery = 'Select ID, ' + soqlFields + 
                                    ' From ' + entity.sObjectName + 
                                    ' Where Id in: subIds ';
        List<SBQQ__Subscription__c> subs = database.query(searchQuery);
        hr.setRecords(subs);
    
        r.gridData = hr.getAuraGridData();
        r.columns = hr.getAuraGridColumnDefinition();
        hr.adjustAuraGridColumnWidth();

        return r;
    }
    
    public class SubscriptionResults {
        @AuraEnabled
        public String errorMsg {get; set;}
        
        @AuraEnabled
        public String primaryQuoteId {get; set;}

        @AuraEnabled
        public Opportunity record {get; set;}

        @AuraEnabled
        public AuraGridResults renewedSubscriptions {get; set;}

        @AuraEnabled
        public AuraGridResults upgradedSubscriptions {get; set;}

        SubscriptionResults() {
            renewedSubscriptions = new AuraGridResults();
            upgradedSubscriptions = new AuraGridResults();
        }
    }


    public class AuraGridResults {
        @AuraEnabled
        public List<LightningUtility.AuraGridColumn> columns {get; set;}
        
        @AuraEnabled
        public List<Map<String, Object>> gridData {get; set;}

        AuraGridResults() {
            columns = new List<LightningUtility.AuraGridColumn>();
            gridData = new List<Map<String, Object>>();
        }
    }
}