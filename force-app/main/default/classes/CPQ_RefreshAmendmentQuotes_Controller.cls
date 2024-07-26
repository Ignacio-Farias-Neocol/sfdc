public class CPQ_RefreshAmendmentQuotes_Controller {
    public class RefreshAmendmentQuotesException extends Exception {}
 
    public class refreshAmendmentsGetQuoteIdResult {
        @AuraEnabled
        public String quoteId {get; set;}
                
        @AuraEnabled
        public AuraGridResults amendmentOppties {get; set;}
    }
    
    public class AuraGridResults {
        @AuraEnabled
        public List<LightningUtility.AuraGridColumn> columns {get; set;}
        
        @AuraEnabled
        public List<Map<String, Object>> gridData {get; set;}
    }
    
    @AuraEnabled(cacheable = true)
    public static refreshAmendmentsGetQuoteIdResult refreshAmendmentsGetQuoteId(String recordId){
        refreshAmendmentsGetQuoteIdResult r = new refreshAmendmentsGetQuoteIdResult();
        r.amendmentOppties = new AuraGridResults();

        if (String.isEmpty(recordId)) {
            throw new RefreshAmendmentQuotesException('Invalid input Record Id.');
        }

        Boolean hasCustomPermission = FeatureManagement.checkPermission('MSP_Refresh_Amendment_Quotes');
        if (hasCustomPermission == false && !Test.isRunningTest()) {
            throw new RefreshAmendmentQuotesException('You do not have permission to complete this operation.');
        }
        
        String theQuoteId;
        String theAccountId;
        if (recordId.startsWith('006')) {
            List<Opportunity> oppties = [Select ID, StageName, AccountId, (Select ID From SBQQ__Quotes2__r Where SBQQ__Primary__c = TRUE and SBQQ__Type__c = 'Amendment' Order By LastModifiedDate DESC) From Opportunity Where ID =: recordId and StageName = 'Closed Won' and Business_Group__c = 'MSP'];
            if (oppties.isEmpty()) {
                throw new RefreshAmendmentQuotesException('The Opportunity Stage is not Closed Won or Business Group is not MSP.');
            }

            Opportunity oppty = oppties[0];
            if (oppty.SBQQ__Quotes2__r.isEmpty()) {
                throw new RefreshAmendmentQuotesException('No Primary Amendment Quote found in the Opportunity.');
            }

            r.quoteId = oppty.SBQQ__Quotes2__r[0].Id;
            theAccountId = oppty.AccountId;
        } else {
            List<SBQQ__Quote__c> quotes = [Select ID, SBQQ__Account__c From SBQQ__Quote__c Where ID =: recordId and SBQQ__Primary__c = TRUE and SBQQ__Type__c = 'Amendment'/* and Business_Group__c = 'MSP'*/];
            if (quotes.isEmpty()) {
                throw new RefreshAmendmentQuotesException('The Quote must be MSP, primary and an amendment.');
            }

            r.quoteId = quotes[0].Id;
            theAccountId = quotes[0].SBQQ__Account__c;
        }
        
        if (!String.isEmpty(theAccountId)) {
            List<Opportunity> oppties = new List<Opportunity>();
            for (Opportunity o : [Select ID, Name, StageName, AccountId, OwnerId, Owner.Name, CurrencyIsoCode, (Select ID, Name, SBQQ__Primary__c From SBQQ__Quotes2__r Where SBQQ__Type__c = 'Amendment' Order By LastModifiedDate DESC) From Opportunity Where AccountId =: theAccountId and StageName Not in ('Closed Won', 'Closed Lost')/* and Business_Group__c = 'MSP'*/]) {
                if (!o.SBQQ__Quotes2__r.isEmpty()) {
                    oppties.add(o);
                }
            }

            if (!oppties.isEmpty()) {
                LightningUtility.SObjectHierarchyResults hr = new LightningUtility.SObjectHierarchyResults(
                    (LightningUtility.SearchEntityInfo)JSON.deserialize('{' +
                                                                        '   "sObjectName" : "Opportunity",' +
                                                                        '   "sObjectIcon" : "standard:opportunity",' +
                                                                        '   "displayFields" : ["Name", "StageName", "OwnerId"]' +
                                                                        '}', LightningUtility.SearchEntityInfo.class)
                );
                hr.setRecords(oppties);
                r.amendmentOppties.gridData = hr.getAuraGridData();
                r.amendmentOppties.columns = hr.getAuraGridColumnDefinition();
                hr.adjustAuraGridColumnWidth();
            }
        }
        return r;
    }

    @AuraEnabled
    public static void cloneQuote(String quoteId) {
        CPQ_RefreshAmendmentQuotes_Batch b = new CPQ_RefreshAmendmentQuotes_Batch();
        b.quoteId = quoteId;
        database.executebatch(b, 1);
    }
}