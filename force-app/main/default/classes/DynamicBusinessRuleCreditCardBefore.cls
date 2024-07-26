/**
* @author Aditya Padhy
* @date 2022-02-16
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description:
*   SFDC-16504 Core/Prod/UAT: Need to change the CC Tokenization Profile Mapping Currency
*  
*/
public class DynamicBusinessRuleCreditCardBefore implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        if (triggerContext.contains('Insert')) {
            updateCurrencyOnCreditCard((List<Credit_Card__c>)records, null);
        }
        
        if (triggerContext.contains('Update')) {
            updateCurrencyOnCreditCard((List<Credit_Card__c>)records,oldRecordMap);
        }
    }
    //This method will copy the Account Currency code to the creditcard Currency code
    public void updateCurrencyOnCreditCard(List<Credit_Card__c> listOfNewCreditCards, Map<Id, SObject> mapOfOldCreditCards){
        Set<Id> setOfAccountIds = new Set<Id>();
        Credit_Card__c cCard;
        for(Credit_Card__c cc : listOfNewCreditCards){
            cCard = (mapOfOldCreditCards == null) ? null : (Credit_Card__c)mapOfOldCreditCards.get(cc.Id);
            if((cCard == null && String.isNotBlank(cc.Account__c)) || (cCard != null && cCard.Sync_to_Netsuite__c != cc.Sync_to_Netsuite__c && cc.Sync_to_Netsuite__c)){
                setOfAccountIds.add(cc.Account__c);
            }
        }
        if(!setOfAccountIds.isEmpty()){
            Map<Id, Account> mapOfAccs = new Map<Id, Account>([SELECT Id, CurrencyIsoCode FROM Account WHERE Id IN: setOfAccountIds]);
            Account acc;
            for(Credit_Card__c cc : listOfNewCreditCards){
                acc = mapOfAccs.get(cc.Account__c);
                if(acc != null && (cc.CurrencyIsoCode != acc.CurrencyIsoCode)){
                    cc.CurrencyIsoCode = acc.CurrencyIsoCode;
                }
            }
        }    
    }
}