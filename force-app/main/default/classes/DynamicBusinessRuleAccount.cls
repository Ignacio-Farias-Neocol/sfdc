/**
* @author Bhavesh Jha
* @date 2020-03-11
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description implementation of DynamicBusinessRuleAction interface & call Account changes after insert/update.

* @description SFDC-13222 Added Account Name to the list of fields to be checked for firing the event
*/

public with sharing class DynamicBusinessRuleAccount implements DynamicBusinessRuleAction  {
    
    /******************************************************************************************************
    * @description called some fields changes after account update.
    * @param trigger.new map
    * @return none, the result should be set to account object.
    * @example 
    *******************************************************************************************************/
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {

        System.debug('~~~~#~~~~: starting: ' +  'DynamicBusinessRuleAccount');
               
        if(!System.isBatch()){
            if (triggerOrder == 'POST') {
                Set<Id> accIdsForPENotify = new Set<Id>();
                if (triggerContext.contains('Insert') ){
                    for(SObject newAccRecord: records){
                        accIdsForPENotify.add((Id)newAccRecord.get('Id'));
                    }
                    //new PlatformEventHelper().publishObject('INSERT',records);
                }
                if(triggerContext.contains('Update')){
                    List<SObject> accountsForPENotify = new List<SObject>();
                    for(SObject newAccRecord: records){
                        SObject oldAccRecord = oldRecordMap.get((Id)newAccRecord.get('Id'));
                        //verify mentioned field changes.
                        if((newAccRecord.get('Original_Sign_Up_Date__c') != oldAccRecord.get('Original_Sign_Up_Date__c')) || 
                           (newAccRecord.get('Billing_Aggregator__c') != oldAccRecord.get('Billing_Aggregator__c')) ||
                           (newAccRecord.get('MSP_Bill_Day__c') != oldAccRecord.get('MSP_Bill_Day__c')) || 
                           (newAccRecord.get('MSP_Auto_Charge__c') != oldAccRecord.get('MSP_Auto_Charge__c')) || 
                           (newAccRecord.get('User_na__c') != oldAccRecord.get('User_na__c')) || 
                           (newAccRecord.get('Usage_Based_Billing__c') != oldAccRecord.get('Usage_Based_Billing__c')) ||
                           (newAccRecord.get('Bill_To_Contact__c') != oldAccRecord.get('Bill_To_Contact__c')) || 
                           (newAccRecord.get('Bill_To_Email__c') != oldAccRecord.get('Bill_To_Email__c')) || 
                           (newAccRecord.get('Bill_To_Phone__c') != oldAccRecord.get('Bill_To_Phone__c')) ||
                           (newAccRecord.get('Name') != oldAccRecord.get('Name'))){ // SFDC-13222
                            accIdsForPENotify.add((Id)newAccRecord.get('Id'));
                               continue;
                        }
                    }
                }
                System.debug('DynamicBusinessRuleAccount :: processRecords :: accIdsForPENotify ::'+JSON.serialize(accIdsForPENotify));
                if(!accIdsForPENotify.isEmpty()){
                    Map<String, Schema.SObjectField> fieldMap = Account.sObjectType.getDescribe().fields.getMap();
                    // Get all of the fields on the object
                    Set<String> fieldNames = new Set<String>();
                    for(string fld:fieldMap.keySet())fieldNames.add(fld);
                    fieldNames.add('(Select id,Name,State_ISO__c,Zip_Postal_Code__c,Country_ISO__c,Street__c,City__c,Country_Name__c,Type__c,Primary__c from Addresses__r)');
                    String queryFields = String.join(new List<String>(fieldNames), ',');                 
                    List<Account> accListForPENotify = Database.query('select ' + String.escapeSingleQuotes(queryFields) + ' from Account where id in: accIdsForPENotify');
                    System.debug('DynamicBusinessRuleAccount :: processRecords :: accountsForPENotify ::'+JSON.serialize(accListForPENotify));
                    if(!accListForPENotify.isEmpty()){
                        if (triggerContext.contains('Insert')){
                            new PlatformEventHelper().publishObject('INSERT',accListForPENotify);
                        }
                        if(triggerContext.contains('Update')){
                            new PlatformEventHelper().publishObject('UPDATE',accListForPENotify);
                        }
                    }
                }
            }
        }
    }
}