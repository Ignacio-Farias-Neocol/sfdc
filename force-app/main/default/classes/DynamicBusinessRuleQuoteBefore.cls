/**
* @author Yuli Fintescu
* @date 2020-03-31
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description implementation of DynamicBusinessRuleAction interface to Quote trigger
* SFDC-5894 initialize quote approval status
* SFDC-11165 Should not be able to have 2 VOL subscriptions on an account
* SFDC-12828 Adding Renewed Subscription = null in the condition to check conflicts in Account
*/
public class DynamicBusinessRuleQuoteBefore implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        if (triggerContext.contains('Insert')) {
            InitializeStageApprovalStatus(records);
        }
    }

    //SFDC-5894
    private static void InitializeStageApprovalStatus(List <SObject> records) {
        Boolean hasCustomPermission = FeatureManagement.checkPermission('Cloned_Quote_retained_Approval_status');
        if (hasCustomPermission == true && !Test.isRunningTest()) 
            return;
        
        for (SBQQ__Quote__c q : (List <SBQQ__Quote__c>)records) {
            if (q.ApprovalStatus__c == 'Pending' || q.ApprovalStatus__c == 'Approved')
                q.ApprovalStatus__c = 'Recalled';
            q.SBQQ__Status__c = 'Draft';
        }
    }

    //SFDC-11165: this code is shared by other modules.
    public static Set<String> quotesWithDupVols(Set<String> quoteIds) {
        Set<String> errorQuoteIds = new Set<String>();

        //account id by involved quote
        Map<String, String> acctIdsByQuote = new Map<String, String>();
        //different VGBs which quanity > 0 by quote
        Map<String, Set<String>> prdCdsByQuote = new Map<String, Set<String>>();
        //different VGBs which quanity = 0 by quote. 
        //if quantity = 0 in quote and is amendment, meaning we are about to terminate the VGA sub from account. we should allow user to go through with the quote.
        Map<String, Set<String>> zeroQuantitySubsByQuote = new Map<String, Set<String>>();
        //VGB subs by account
        Map<String, Set<String>> subsByAccount = new Map<String, Set<String>>();

        for (SBQQ__QuoteLine__c ql : [Select ID, SBQQ__ProductCode__c, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Account__c, SBQQ__Quantity__c, SBQQ__UpgradedSubscription__c
                                    From SBQQ__QuoteLine__c 
                                    Where SBQQ__Quote__c in: quoteIds and 
                                        SBQQ__ProductCode__c like 'VGB-%' and
                                        SBQQ__Quote__r.Business_Group__c = 'MSP' and
                                        SBQQ__Quote__r.SBQQ__Account__c <> NULL]) {
            acctIdsByQuote.put(ql.SBQQ__Quote__c, ql.SBQQ__Quote__r.SBQQ__Account__c);

            if (ql.SBQQ__Quantity__c > 0) {
                Set<String> prdCds = prdCdsByQuote.get(ql.SBQQ__Quote__c);
                if (prdCds == null) {
                    prdCds = new Set<String>();
                    prdCdsByQuote.put(ql.SBQQ__Quote__c, prdCds);
                }
                prdCds.add(ql.SBQQ__ProductCode__c);
            } else if (ql.SBQQ__Quantity__c == 0 && ql.SBQQ__UpgradedSubscription__c <> NULL) {
                Set<String> subIds = zeroQuantitySubsByQuote.get(ql.SBQQ__Quote__c);
                if (subIds == null) {
                    subIds = new Set<String>();
                    zeroQuantitySubsByQuote.put(ql.SBQQ__Quote__c, subIds);
                }
                subIds.add(ql.SBQQ__UpgradedSubscription__c);
            }
        }
        
        //Check in the same quote there should not be multiple VGBs.
        //-----------------------------------------------------------
        for (String key : prdCdsByQuote.keySet()) {
            Set<String> prdCds = prdCdsByQuote.get(key);
            if (prdCds.size() > 1) {
                errorQuoteIds.add(key);

                //already errored out, no need to check VOLs in account
                acctIdsByQuote.remove(key);
            }
        }

        if (acctIdsByQuote.size() == 0) 
            return errorQuoteIds;
        
        //Check in the account if there is any conflict
        //-----------------------------------------------------------
        //SFDC-12828: Adding the condition for renewed subscription
        Map<ID, SBQQ__Subscription__c> subsMap = new Map<ID, SBQQ__Subscription__c> ([Select ID, 
                                                                                             SBQQ__Account__c, 
                                                                                             SBQQ__Product__c, 
                                                                                             SBQQ__Product__r.ProductCode 
                                                                                      From SBQQ__Subscription__c 
                                                                                      Where SBQQ__Account__c in: acctIdsByQuote.values() 
                                                                                      and SBQQ__Product__r.ProductCode like 'VGB-%' 
                                                                                      and Business_Group__c = 'MSP' 
                                                                                      and (SBQQ__TerminatedDate__c = NULL or SBQQ__TerminatedDate__c > TODAY) 
                                                                                      and SBQQ__RevisedSubscription__c = NULL 
                                                                                      and Renewed_By_Subscription__c = NULL ]);
        for (SBQQ__Subscription__c s : subsMap.values()) {
            
            Set<String> subIds = subsByAccount.get(s.SBQQ__Account__c);
            if (subIds == null) {
                subIds = new Set<String>();
                subsByAccount.put(s.SBQQ__Account__c, subIds);
            }
            subIds.add(s.Id);
        }

        for (String quoteId : acctIdsByQuote.keySet()) {
            if (errorQuoteIds.contains(quoteId)) 
                continue;
            
            Set<String> prdCds1 = prdCdsByQuote.get(quoteId);
            if (prdCds1 == null)
                continue;
            
            String acctId = acctIdsByQuote.get(quoteId);
            Set<String> subIds = subsByAccount.get(acctId);
            if (subIds == null)
                continue;
            System.Debug('*** subIds ' + subIds);

            //remove potential RMA subs from the account
            //the quote has set these subs to 0 quantity
            Set<String> zeroQuantitySubIds = zeroQuantitySubsByQuote.get(quoteId);
            if (zeroQuantitySubIds != null) {
                subIds.removeAll(zeroQuantitySubIds);
            }
            System.Debug('*** zeroQuantitySubIds ' + zeroQuantitySubIds);

            //now, what are left in the account?
            Set<String> prdCds2 = new Set<String>();
            for (String subId : subIds) {
                SBQQ__Subscription__c s = subsMap.get(subId);
                prdCds2.add(s.SBQQ__Product__r.ProductCode);
            }
            System.Debug('*** prdCds1 ' + prdCds1);

            //if prdCds2 does not contains all in prdCds1, meaning prdCds1 has VGB that are not currently in the account
            if (prdCds2.size() > 0 && !prdCds2.containsAll(prdCds1)) {
                errorQuoteIds.add(quoteId);
            }
        }

        return errorQuoteIds;
    }
}
/*
Set<string> s1 = new Set<string> {'1', '2', '4'};
Set<string> s2 = new Set<string> {'1', '2'};
System.Debug('*** s2.containsAll(s1) ' + s2.containsAll(s1));
System.Debug('*** s1.containsAll(s2) ' + s1.containsAll(s2));
*/