/**
* @author Dilowar Hussain
* @date 2024-01-31
*
* @description 
* 
*
* 
* This has been added as a part of SFDC-20480
*/
public with sharing class DynamicBusRuleOnIntegrationSnap implements DynamicBusinessRuleAction{
    /**
    * Method description: 
    * @param
    * @Return
    */
    public void processRecords(Map<Id,SObject> newRecordMap, 
                                                            Map<Id,SObject> oldRecordMap,
                                                            List <SObject> records, 
                                                            String jsonParameter, 
                                                            String triggerOrder, 
                                                            String triggerContext) {
        //Instantiate the log class to capture logs for error conditions
        //System.debug('Trigger initiated');
        LogModel log = LogModel.startLog('DynamicBusRuleOnIntegrationSnap', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        Map<Id, Integration_Snapshot__c> mapIS = new Map<Id, Integration_Snapshot__c>();
        Set<String> OrderIDs = new Set<String>();
        Set<String> accountIds = new Set<String>();
        Set<String> contactIDs = new Set<String>();
        Set<String> oppIDs = new Set<String>();
        Set<String> caseIDs = new Set<String>();
        Map<Id, Order> mapOrder = new Map<Id, Order>();
        Map<Id, Account> mapAccount = new Map<Id, Account>();
        Map<Id, Contact> mapContact = new Map<Id, Contact>();
        Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity>();
        Map<Id, Case> mapCase = new Map<Id, Case>();
        String objectName = '';
        try{
            if((triggerContext.contains('Update') || triggerContext.contains('Insert'))){
                //System.debug('Trigger context:' +triggerContext);
                for(SObject rec: records){
                    Integration_Snapshot__c is01 = (Integration_Snapshot__c)rec;
                    Integration_Snapshot__c is02 = oldRecordMap == null ? null : (Integration_Snapshot__c)oldRecordMap.get(is01.Id);
                    if((is01.Record_ID__c != NULL || (is01.Record_ID__c != NULL && is02.Record_ID__c != NULL && is01.Record_ID__c != is02.Record_ID__c))
                       /*&& (is01.Object_Name__c != NULL || (is01.Object_Name__c != NULL && is02.Object_Name__c != NULL && is01.Object_Name__c != is02.Object_Name__c))*/){
                        objectName = Id.valueOf(is01.Record_ID__c).getSObjectType().getDescribe().getName();
                        mapIS.put(is01.id, is01);
                        if(objectName.equalsIgnoreCase('Order')){
                            OrderIDs.add(is01.Record_ID__c);
                        }else if(objectName.equalsIgnoreCase('Account')){
                            accountIds.add(is01.Record_ID__c);
                        }else if(objectName.equalsIgnoreCase('Contact')){
                            contactIDs.add(is01.Record_ID__c);
                        }else if(objectName.equalsIgnoreCase('Opportunity')){
                            oppIDs.add(is01.Record_ID__c);
                        }else if(objectName.equalsIgnoreCase('Case')){
                            caseIDs.add(is01.Record_ID__c);
                        }
                    }
                //System.debug('OrderIDs is:' +OrderIDs);
                }
                /**
                 * If the snapshot is created with Order.
                 */
                if(!OrderIDs.isEmpty()){
                    for(order ord : [select id, AccountID, Account.Type, Account.User_na__c from Order where id in :OrderIDs]){
                        mapOrder.put(ord.id, ord);
                    }
                    //System.debug('mapOrder is:' +mapOrder);
                    for(Integration_Snapshot__c is03 : mapIS.Values()){
                        //System.debug('final Mapping Order:' +mapOrder.get(is03.Record_ID__c).AccountID);
                        is03.Name__c = mapOrder.get(is03.Record_ID__c).AccountID != NULL ? mapOrder.get(is03.Record_ID__c).AccountID : NULL;
                        is03.Type__c = mapOrder.get(is03.Record_ID__c).Account.Type != NULL ? mapOrder.get(is03.Record_ID__c).Account.Type : '';
                        is03.Username__c = mapOrder.get(is03.Record_ID__c).Account.User_na__c != NULL ? mapOrder.get(is03.Record_ID__c).Account.User_na__c : '';
                        is03.Related_Order__c = is03.Record_ID__c;
                    }
                }
                /**
                 * If the snapshot is created with Account.
                 */
                //System.debug('accountIds is:' +accountIds);
                if(!accountIds.isEmpty()){
                    for(Account acc : [Select id, Name, Type, User_na__c from Account where id in :accountIds]){
                        mapAccount.put(acc.id, acc);
                    }
                    for(Integration_Snapshot__c is03 : mapIS.Values()){
                        //System.debug('final Mapping Account:' +mapAccount.get(is03.Record_ID__c).Name);
                        is03.Name__c = mapAccount.get(is03.Record_ID__c).ID != NULL ? mapAccount.get(is03.Record_ID__c).ID : '';
                        is03.Type__c = mapAccount.get(is03.Record_ID__c).Type != NULL ? mapAccount.get(is03.Record_ID__c).Type : '';
                        is03.Username__c = mapAccount.get(is03.Record_ID__c).User_na__c != NULL ? mapAccount.get(is03.Record_ID__c).User_na__c : '';
                    }
                }
                /**
                 * If the snapshot is created with Contact.
                 */
                //System.debug('contactIDs is:' +contactIDs);
                if(!contactIDs.isEmpty()){
                    for(Contact con : [Select id, AccountID, Account.Type, Account.User_na__c from Contact where id in :contactIDs]){
                        mapContact.put(con.id, con);
                    }
                    for(Integration_Snapshot__c is03 : mapIS.Values()){
                        //System.debug('final Mapping Contact:' +mapContact.get(is03.Record_ID__c).Account.Name);
                        is03.Name__c = mapContact.get(is03.Record_ID__c).AccountID != NULL ? mapContact.get(is03.Record_ID__c).AccountID : '';
                        is03.Type__c = mapContact.get(is03.Record_ID__c).Account.Type != NULL ? mapContact.get(is03.Record_ID__c).Account.Type : '';
                        is03.Username__c = mapContact.get(is03.Record_ID__c).Account.User_na__c != NULL ? mapContact.get(is03.Record_ID__c).Account.User_na__c : '';
                    }
                }
                /**
                 * If the snapshot is created with Opportunity.
                 */
                //System.debug('oppIDs is:' +oppIDs);
                if(!oppIDs.isEmpty()){
                    for(Opportunity opp : [Select id, AccountID, Account.Type, Account.User_na__c from Opportunity where id in :oppIDs]){
                        mapOpp.put(opp.id, opp);
                    }
                    for(Integration_Snapshot__c is03 : mapIS.Values()){
                        //System.debug('final Mapping Opportunity:' +mapOpp.get(is03.Record_ID__c).Account.Name);
                        is03.Name__c = mapOpp.get(is03.Record_ID__c).AccountID != NULL ? mapOpp.get(is03.Record_ID__c).AccountID : '';
                        is03.Type__c = mapOpp.get(is03.Record_ID__c).Account.Type != NULL ? mapOpp.get(is03.Record_ID__c).Account.Type : '';
                        is03.Username__c = mapOpp.get(is03.Record_ID__c).Account.User_na__c != NULL ? mapOpp.get(is03.Record_ID__c).Account.User_na__c : '';
                    }
                }
                /**
                 * If the snapshot is created with Case.
                 */
                //System.debug('caseIDs is:' +caseIDs);
                if(!caseIDs.isEmpty()){
                    for(Case cs : [Select id, AccountID, Account.Type, Account.User_na__c from Case where id in :caseIDs]){
                        mapCase.put(cs.id, cs);
                    }
                    for(Integration_Snapshot__c is03 : mapIS.Values()){
                        //System.debug('final Mapping Case:' +mapCase.get(is03.Record_ID__c).Account.Name);
                        is03.Name__c = mapCase.get(is03.Record_ID__c).AccountID != NULL ? mapCase.get(is03.Record_ID__c).AccountID : '';
                        is03.Type__c = mapCase.get(is03.Record_ID__c).Account.Type != NULL ? mapCase.get(is03.Record_ID__c).Account.Type : '';
                        is03.Username__c = mapCase.get(is03.Record_ID__c).Account.User_na__c != NULL ? mapCase.get(is03.Record_ID__c).Account.User_na__c : '';
                    }
                }
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
    }
}