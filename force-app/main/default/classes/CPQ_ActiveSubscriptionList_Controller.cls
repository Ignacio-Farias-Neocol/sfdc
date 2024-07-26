public class CPQ_ActiveSubscriptionList_Controller {
    @AuraEnabled
    public static SubscriptionResults retrieveSubscriptions(String inputrecordId) {
        SubscriptionResults r = new SubscriptionResults();

        List<Account> records = [Select ID, Name From Account Where Id =: inputrecordId];
        if (records.size() == 0) {
            r.errorMsg = 'Account record not found.';
            return r;
        }
        r.record = records[0];

        try {
            r.subscriptions = getSubscriptions('CPQ_ActiveSubscriptionTabinAccount', inputrecordId);
        } catch (Exception e) {
            r.errorMsg = e.getMessage();
        }
        
        return r;
    }
    
    private static AuraGridResults getSubscriptions(String fieldSetAPIName, String inputrecordId) {
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
        
        String accountId = inputrecordId;
        String searchQuery = 'Select ID, ' + soqlFields + ', ' + 
                                'SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__c, ' +
                                'SBQQ__QuoteLine__r.SBQQ__RenewedSubscription__r.SBQQ__RevisedSubscription__c' +
                            ' From ' + entity.sObjectName + 
                            ' Where SBQQ__Account__c =: accountId and Business_Group__c <> \'Core\' and ' +
            					'SBQQ__RequiredById__c = NULL and ' + //SFDC-12065 added to hide child items
                                '(SBQQ__TerminatedDate__c = NULL or SBQQ__TerminatedDate__c > TODAY) and ' + 
                                'SBQQ__RevisedSubscription__c = null and SBQQ__Contract__r.EndDate >= TODAY and ' +
                                'SBQQ__ProductOption__r.SBQQ__QuoteLineVisibility__c not in (\'Editor Only\', \'Never\')';
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
        public Account record {get; set;}

        @AuraEnabled
        public AuraGridResults subscriptions {get; set;}
    }


    public class AuraGridResults {
        @AuraEnabled
        public List<LightningUtility.AuraGridColumn> columns {get; set;}
        
        @AuraEnabled
        public List<Map<String, Object>> gridData {get; set;}
    }
}