/**
* @author Aditya
* @date 13 July 2022
* @group DynmaicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
* @description implementation of DynamicBusinessRuleAction interface 
to update User's default Currency based on Contact's Account Currency
*/
public with sharing class UpdateCommunityUserCurrency implements DynamicBusinessRuleAction{
    
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap,List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        System.debug('inside processRecords...'+records);
        if (triggerOrder == 'POST') {
            if(triggerContext.contains('Insert')){
                Set<Id> contIds = new Set<Id>();
                List<User> listOfCommUsers = new List<User>();
                for(Sobject u : records){
                    contIds.add((Id)u.get('contactId'));
                    listOfCommUsers.add((User)u);
                }
                UpdateCommunityUserCurrencyHelper.updateCommunityUserCurrency(contIds,listOfCommUsers,'User');
            }
            if(triggerContext.contains('Update')){
                String objectName = records[0].Id.getSobjectType().getDescribe().getName();
                if(objectName=='Contact'){
                    Set<Id> contIds = new Set<Id>();
                    for(Sobject con : records){
                        SObject oldContRecord = oldRecordMap.get((Id)con.get('Id'));
                        if((Id)oldContRecord.get('AccountId') != (Id)con.get('AccountId')){
                            contIds.add((Id)con.get('Id'));
                        }
                    }
                    UpdateCommunityUserCurrencyHelper.updateCommunityUserCurrency(contIds,null,objectName);
                }
                else if(objectName=='Account'){
                    Set<Id> accIds = new Set<Id>();
                    for(Sobject acc : records){
                        SObject oldAccRecord = oldRecordMap.get((Id)acc.get('Id'));
                        if(oldAccRecord.get('CurrencyIsoCode') != acc.get('CurrencyIsoCode')){
                            accIds.add((Id)acc.get('Id'));
                        }
                    }
                    UpdateCommunityUserCurrencyHelper.updateCommunityUserCurrency(accIds,null,objectName);
                }
            }
        }
    }
}