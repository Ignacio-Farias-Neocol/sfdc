/**
* @author IY
* @date 2018
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description implementation of DynamicBusinessRuleAction interface to quote before trigger
* SFDC-10463: RMA should remove the "renewed by Subs"
*/
public class DynamicBusinessRuleQuoteCoreBefore implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
         QuotePaymentTerms (records, oldRecordMap);
         ValidateSubsInRenewalQuote(newRecordMap, oldRecordMap);
    }

    private static void QuotePaymentTerms (List <SObject> records, Map<Id, SObject> oldMap) {
        Set<String> opptyIds = new Set<String>();
        List<SBQQ__Quote__c> candidates = new List<SBQQ__Quote__c>();

        for (SBQQ__Quote__c q : (List <SBQQ__Quote__c>)records) {
            SBQQ__Quote__c qOld = (oldMap == null ? new SBQQ__Quote__c() : (SBQQ__Quote__c)oldMap.get(q.Id));
            if (qOld == null)
                qOld = new SBQQ__Quote__c();

            if (q.SBQQ__Opportunity2__c != qOld.SBQQ__Opportunity2__c || 
                    (q.ApprovalStatus__c != qOld.ApprovalStatus__c && (q.ApprovalStatus__c == 'Approved' || qOld.ApprovalStatus__c == 'Approved')) || 
                    (q.SBQQ__Status__c != qOld.SBQQ__Status__c && (q.SBQQ__Status__c == 'Approved' || qOld.SBQQ__Status__c == 'Approved')) || 
                    q.SBQQ__PaymentTerms__c != qOld.SBQQ__PaymentTerms__c) {
                
                if (q.SBQQ__Opportunity2__c == null) {
                    q.SBQQ__PaymentTerms__c = null;
                    q.SBQQ__Status__c = 'Draft';
                    q.ApprovalStatus__c = null;
                } else {
                    opptyIds.add(q.SBQQ__Opportunity2__c);
                    candidates.add(q);
                }
            }
        }

        if (opptyIds.size() > 0) {
            Map<String, Opportunity> opptys = new Map<String, Opportunity>([Select ID, Name, Bill_To_Account__c, Bill_To_Account__r.Payment_Terms__c, Payment_Terms__c From Opportunity Where Id in: opptyIds]);

            for (SBQQ__Quote__c q : candidates) {
                SBQQ__Quote__c qOld = (oldMap == null ? new SBQQ__Quote__c() : (SBQQ__Quote__c)oldMap.get(q.Id));
                Opportunity opp = opptys.get(q.SBQQ__Opportunity2__c);

                if (q.ApprovalStatus__c == 'Approved' || q.SBQQ__Status__c == 'Approved' || opp.Payment_Terms__c == 'Credit Card') {
                    q.SBQQ__PaymentTerms__c = opp.Payment_Terms__c;
                } else {
                    q.SBQQ__PaymentTerms__c = opp.Bill_To_Account__r.Payment_Terms__c;
                }
            }
        }
    }

    private static void ValidateSubsInRenewalQuote (Map<Id,SObject> newMap, Map<Id, SObject> oldMap) {
        Set<String> candidates = new Set<String>();

        for (SBQQ__Quote__c q : (List <SBQQ__Quote__c>)newMap.values()) {
            SBQQ__Quote__c qOld = (oldMap == null ? new SBQQ__Quote__c() : (SBQQ__Quote__c)oldMap.get(q.Id));
            if (qOld == null)
                qOld = new SBQQ__Quote__c();

            if ((q.ApprovalStatus__c != qOld.ApprovalStatus__c && (q.ApprovalStatus__c == 'Approved' || q.ApprovalStatus__c == 'Pending')) || 
                    (q.SBQQ__Status__c != qOld.SBQQ__Status__c && (q.SBQQ__Status__c == 'Approved' || q.SBQQ__Status__c == 'In Review'))) {
                candidates.add(q.Id);
            }
        }

        if (candidates.size() > 0) {
            for (String quoteId : quotesWithInvalidSubs(candidates)) {
                SBQQ__Quote__c errorQuote =  (SBQQ__Quote__c)newMap.get(quoteId);
                if (errorQuote != null)
                    errorQuote.addError('One or more of the subscriptions on this quote have already been renewed or are associated with multiple line items in the quote. Please double check your subscriptions have not already been renewed, or ensure that you have one of your quote options marked as optional. You can see this by looking at the subscription record in the Renewed by Subscription field.');
            }
        }
    }

    public static Set<String> quotesWithInvalidSubs(Set<String> quoteIds) {
        Set<String> errorQuoteIds = new Set<String>();

        Map<String, Set<String>> subIdsByQuote = new Map<String, Set<String>>();
        for (SBQQ__QuoteLine__c ql : [Select ID, SBQQ__Quote__c, SBQQ__RenewedSubscription__c, 
                                        SBQQ__RenewedSubscription__r.Has_Not_Been_Renewed__c
                                    From SBQQ__QuoteLine__c 
                                    Where SBQQ__Quote__c in: quoteIds and 
                                        SBQQ__Optional__c = FALSE and 
                                        SBQQ__Group__r.SBQQ__Optional__c = FALSE and 
                                        SBQQ__RenewedSubscription__c <> NULL and
										SBQQ__Quantity__c != 0 
                                    Order By SBQQ__Quote__c, SBQQ__RenewedSubscription__c]) {
            
            if (!errorQuoteIds.contains(ql.SBQQ__Quote__c)) {
                if (ql.SBQQ__RenewedSubscription__r.Has_Not_Been_Renewed__c == false) {
                    errorQuoteIds.add(ql.SBQQ__Quote__c);
                } else {
                    //in the same quote, prevent multiple quotelines from renewing the same sub.
                    Set<String> subIds = subIdsByQuote.get(ql.SBQQ__Quote__c);
                    if (subIds == null) {
                        subIds = new Set<String>();
                        subIdsByQuote.put(ql.SBQQ__Quote__c, subIds);
                    } else if (subIds.contains(ql.SBQQ__RenewedSubscription__c)){
                        errorQuoteIds.add(ql.SBQQ__Quote__c);
                    }
                    subIds.add(ql.SBQQ__RenewedSubscription__c);
                }
            }
        }

        return errorQuoteIds;
    }
}