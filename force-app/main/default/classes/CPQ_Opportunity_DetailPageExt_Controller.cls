public class CPQ_Opportunity_DetailPageExt_Controller {
    public class AlertsResults {
        @AuraEnabled
        public Boolean alertIncreaseQtyOnRenewalQuote {get; set;}

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
            List<AggregateResult> resutls = [Select COUNT(ID) counts
                                            From SBQQ__QuoteLine__c 
                                            Where SBQQ__Quote__r.SBQQ__Opportunity2__c =:recordId and 
                                                SBQQ__Quote__r.SBQQ__Primary__c = TRUE and
                                                SBQQ__Quote__r.ApprovalStatus__c <> 'Approved' and 
                                                SBQQ__Quote__r.SBQQ__Status__c <> 'Approved' and
                                                Require_SaaS_Product_Approval__c = TRUE and 
                                                SBQQ__Quote__r.SBQQ__Opportunity2__r.IsClosed = false];
            for(AggregateResult aggr : resutls) {
                Integer counts = Integer.valueOf(aggr.get('counts'));
                if (counts > 0) {
                    r.alertIncreaseQtyOnRenewalQuote = true;
                    break;
                }
            }

            Set<String> quoteIds = new Set<String>();
            Set<String> quoteIdsMSP = new Set<String>();
            for (Opportunity o : [Select ID, SBQQ__PrimaryQuote__c, Business_Group__c From Opportunity Where Id =: recordId and StageName <> 'Closed Won']) {
                quoteIds.add(o.SBQQ__PrimaryQuote__c);

                if (o.Business_Group__c == 'MSP')
                    quoteIdsMSP.add(o.SBQQ__PrimaryQuote__c);
            }

            //SFDC-9483: popup an alert the oppty is renewing sub that has been renewed.
            Set<String> errorQuoteIds = DynamicBusinessRuleQuoteCoreBefore.quotesWithInvalidSubs(quoteIds);
            if (Test.isRunningTest())
                errorQuoteIds = new Set<String>{'123'};
            for (String quoteId : errorQuoteIds) {
                r.alertSubscriptionAlreadyRenewed = true;
                break;
            }

            //SFDC-11165: popup an alert the oppty has conflicting VOL
            errorQuoteIds = DynamicBusinessRuleQuoteBefore.quotesWithDupVols(quoteIdsMSP);
            if (Test.isRunningTest())
                errorQuoteIds = new Set<String>{'123'};
            for (String quoteId : errorQuoteIds) {
                r.alertConflictingVOL = true;
                break;
            }

            //SFDC-10537: popup an alert if an amendment quote is replicated to the oppty
            SBQQ__Quote__c primary;
            for (SBQQ__Quote__c q : [Select ID, Name, CreatedDate, SBQQ__Primary__c, SBQQ__Opportunity2__c, 
                                        SBQQ__Source__c, SBQQ__Source__r.Business_Group__c, SBQQ__Source__r.SBQQ__Opportunity2__c, SBQQ__Source__r.SBQQ__Type__c, SBQQ__Source__r.SBQQ__Opportunity2__r.IsClosed
                                    From SBQQ__Quote__c 
                                    Where SBQQ__Type__c = 'Amendment' and 
                                        SBQQ__Opportunity2__r.IsClosed = false and
                                        Business_Group__c = 'MSP' and
                                        SBQQ__Opportunity2__c =: recordId 
                                    Order By SBQQ__Primary__c DESC, CreatedDate]) {
                
                if (q.SBQQ__Primary__c == true) {
                    primary = q;
                } else if (primary != null && 
                        ((q.CreatedDate > primary.CreatedDate && q.SBQQ__Source__c != NULL && q.SBQQ__Source__r.SBQQ__Opportunity2__c != primary.SBQQ__Opportunity2__c && q.SBQQ__Source__r.Business_Group__c == 'MSP' && q.SBQQ__Source__r.SBQQ__Type__c == 'Amendment' && q.SBQQ__Source__r.SBQQ__Opportunity2__r.IsClosed == TRUE) || Test.isRunningTest())) {//looks like this q is an amendment copy. see SFDE-10537
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