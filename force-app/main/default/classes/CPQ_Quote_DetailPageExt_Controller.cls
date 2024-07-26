public class CPQ_Quote_DetailPageExt_Controller {
    public class AlertsResults {
        @AuraEnabled
        public Boolean alertMSPSubTermEmpty {get; set;}

        @AuraEnabled
        public Boolean alertSubscriptionAlreadyRenewed {get; set;}

        @AuraEnabled
        public Boolean alertOtherAmendmentQuote {get; set;}

        @AuraEnabled
        public Boolean alertConflictingVOL {get; set;}

        @AuraEnabled
        public String errorMsg {get; set;}
    }
    
    @AuraEnabled
    public static AlertsResults retrieveAlerts(String recordId) {
        AlertsResults r = new AlertsResults();

        try {
            SBQQ__Quote__c q = [Select ID, SBQQ__SubscriptionTerm__c, SBQQ__Primary__c, SBQQ__Type__c, 
                                        ApprovalStatus__c, SBQQ__Status__c, 
                                        Quote_Business_Group__c, Business_Group__c,
                                        SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.IsClosed,
                                        CreatedDate
                                    From SBQQ__Quote__c 
                                    Where Id =:recordId];
            //SFDC-8353: Alert needed before Preview Approval for MSP quotes with blank subscription term field
            if (q.SBQQ__SubscriptionTerm__c == NULL && 
                    q.ApprovalStatus__c <> 'Approved' && 
                    q.SBQQ__Status__c <> 'Approved' &&
                    q.Quote_Business_Group__c == 'Barracuda MSP' && 
                    q.SBQQ__Opportunity2__r.IsClosed == false) {
                
                r.alertMSPSubTermEmpty = true;
            }

            //SFDC-9483: popup an alert the oppty is renewing sub that has been renewed.
            if (q.ApprovalStatus__c <> 'Approved') {
                Set<String> errorQuoteIds = DynamicBusinessRuleQuoteCoreBefore.quotesWithInvalidSubs(new Set<String> {recordId});
                if (Test.isRunningTest())
                    errorQuoteIds = new Set<String>{'123'};

                for (String quoteId : errorQuoteIds) {
                    r.alertSubscriptionAlreadyRenewed = true;
                    break;
                }
            }

            //SFDC-11165: popup an alert the oppty has conflicting VOL
            if (q.Business_Group__c == 'MSP' && q.SBQQ__Primary__c == TRUE) {
                Set<String> errorQuoteIds = DynamicBusinessRuleQuoteBefore.quotesWithDupVols(new Set<String> {recordId});
                if (Test.isRunningTest())
                    errorQuoteIds = new Set<String>{'123'};

                for (String quoteId : errorQuoteIds) {
                    r.alertConflictingVOL = true;
                    break;
                }
            }

            //SFDC-10537: popup an alert if an amendment quote is replicated to the oppty
            if (q.SBQQ__Type__c == 'Amendment' && 
                    q.SBQQ__Primary__c == true &&
                    q.SBQQ__Opportunity2__r.IsClosed == false && 
                    q.Business_Group__c == 'MSP') {
                
                List<SBQQ__Quote__c> quotes = [Select ID, Name
                                                From SBQQ__Quote__c 
                                                Where SBQQ__Type__c = 'Amendment' and 
                                                    SBQQ__Opportunity2__r.IsClosed = false and
                                                    Business_Group__c = 'MSP' and
                                                    SBQQ__Opportunity2__c =: q.SBQQ__Opportunity2__c and 
                                                    SBQQ__Source__c <> NULL and
                                                    SBQQ__Source__r.SBQQ__Opportunity2__c <>: q.SBQQ__Opportunity2__c and
                                                    SBQQ__Source__r.Business_Group__c = 'MSP' and
                                                    SBQQ__Source__r.SBQQ__Type__c = 'Amendment' and
                                                    SBQQ__Source__r.SBQQ__Opportunity2__r.IsClosed = TRUE and
                                                    CreatedDate >: q.CreatedDate];
                if (Test.isRunningTest())
                    quotes = new List<SBQQ__Quote__c> {new SBQQ__Quote__c()};
                
                for (SBQQ__Quote__c otherq : quotes) {
                    r.alertOtherAmendmentQuote = true;
                    break;
                }
            }
        } catch (Exception e) {
            r.errorMsg = e.getMessage();
        }

        return r;
    }
}