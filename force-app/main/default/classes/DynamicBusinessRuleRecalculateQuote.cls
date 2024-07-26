/**
* @author IY
* @date 2018
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description implementation of DynamicBusinessRuleAction interface to recalculate quote
*/
public with sharing class DynamicBusinessRuleRecalculateQuote implements DynamicBusinessRuleAction {

private static final String COMMENT_STRING = '##0##';

/*******************************************************************************************************
* @description set the contact lookup field based upon the web form fields
* @param trigger.new map
* @return none, the result should be set to the records itself
* @example
*/
public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {


    System.debug('~~~~~ Invoke DynamicBusinessRuleRecalculateQuote');

    String objName = ((id) ((records[0].get('Id')))).getSObjectType().getDescribe().getName();

    List <SObject> filterObjects = new List  <SObject>();

    PlatformEventHelper.findFilteredRecords(objName, newRecordMap, oldRecordMap, filterObjects);

    System.debug('~~~~~ Invoke DynamicBusinessRuleRecalculateQuote changed oppty: ' + filterObjects);

    Set <Id> quoteIds = new Set<Id>();
    for (SObject o: filterObjects){
        Opportunity oppty = (Opportunity)o;

        if (oppty.stageName != null && !oppty.stageName.contains('Closed') && oppty.SBQQ__primaryquote__c != null){
            quoteIds.add(oppty.SBQQ__primaryquote__c);
            System.debug('~~~~~ Invoke DynamicBusinessRuleRecalculateQuote changed oppty: ' + oppty);
        }
    }

    System.debug('~~~~~ Invoke DynamicBusinessRuleRecalculateQuote quote ids: ' + quoteIds);
 //SFDC-200241: Added future and batch check as Opp is getting update from future DynamicBusinessRuleAddress class
    if (quoteIds.size() > 0 && !System.isFuture() && !System.isBatch()){
        updateQuoteToRecalculate(quoteIds);
    }

}

/*******************************************************************************************************
* @description
* @param
* @return
* @example
*/
    @future
    public static void updateQuoteToRecalculate(Set<id> quoteIds) {
        List <SBQQ__Quote__c> quotes = [select id,  SBQQ__Opportunity2__r.CloseDate, Quote_Description__c,SBQQ__Status__c,SBQQ__ExpirationDate__c,ApprovalStatus__c from SBQQ__Quote__c where id in:quoteIds ];
        for (SBQQ__Quote__c q: quotes){

            String s1 = String.isBlank(q.Quote_Description__c)? '': q.Quote_Description__c;
            String regExp = COMMENT_STRING + '.*' + COMMENT_STRING; // '####.*####';
            String replacement = COMMENT_STRING + ' ' +  'Recalcuate Quote at: ' + String.valueOf(Datetime.now()) + ' ' + COMMENT_STRING;
            String s2 = s1.replaceAll(regExp, replacement);
            System.debug('s2: ' + s2);

            if (!s2.contains(COMMENT_STRING)){
                s2 = replacement + '\n' + s1;
            }
            // set the quote
            q.Quote_Description__c = s2;
            // always set the approval back if quote is now expiried
            if(q.SBQQ__ExpirationDate__c<q.SBQQ__Opportunity2__r.CloseDate){
            q.SBQQ__Status__c = 'Draft';
            q.ApprovalStatus__c = null;
            }

        }

        DML.save(quotes);
    }


    }