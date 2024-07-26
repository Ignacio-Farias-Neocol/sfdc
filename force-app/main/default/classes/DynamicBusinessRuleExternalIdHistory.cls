public with sharing class DynamicBusinessRuleExternalIdHistory implements DynamicBusinessRuleAction  {
    
    /******************************************************************************************************
    * @description called some fields changes after  External Id History update.
    * @param trigger.new map
    * @return none, the result should be set to External Id History object.
    * @example 
    *******************************************************************************************************/
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {

        System.debug('~~~~#~~~~: starting: ' +  'DynamicBusinessRuleExternalIdHistory');
               
        if(!System.isBatch()){
            if (triggerOrder == 'POST') {
                Set<Id> extIdHistIdsForPENotify = new Set<Id>();
                if (triggerContext.contains('Insert') ){
                    for(SObject newExtIdHistRecord: records){
                        extIdHistIdsForPENotify.add((Id)newExtIdHistRecord.get('Id'));
                    }
                    //new PlatformEventHelper().publishObject('INSERT',records);
                }
                if(triggerContext.contains('Update')){
                    List<SObject> extIdHistForPENotify = new List<SObject>();
                    for(SObject newExtIdHistRecord: records){
                        SObject oldAccRecord = oldRecordMap.get((Id)newExtIdHistRecord.get('Id'));
                       
                            extIdHistIdsForPENotify.add((Id)newExtIdHistRecord.get('Id'));
                               continue; 
                        //}
                    }
                }
                System.debug('DynamicBusinessRuleExternalIdHistory:: processRecords :: extIdHistForPENotify ::'+JSON.serialize(extIdHistIdsForPENotify));
                if(!extIdHistIdsForPENotify.isEmpty()){
                    Map<String, Schema.SObjectField> fieldMap = External_ID_History__c.sObjectType.getDescribe().fields.getMap();
                    // Get all of the fields on the object
                    Set<String> fieldNames = new Set<String>();
                    for(string fld:fieldMap.keySet())fieldNames.add(fld);
                   
                    String queryFields = String.join(new List<String>(fieldNames), ',');
                    List<External_ID_History__c> extIdHistListForPENotify = Database.query('select ' + queryFields + ' from External_ID_History__c where id in: extIdHistIdsForPENotify');
                    System.debug('DynamicBusinessRuleExternalIdHistory:: processRecords :: accountsForPENotify ::'+JSON.serialize(extIdHistIdsForPENotify));
                    if(!extIdHistListForPENotify.isEmpty()){
                        if (triggerContext.contains('Insert')){
                            new PlatformEventHelper().publishObject('INSERT',extIdHistListForPENotify);
                        }
                        if(triggerContext.contains('Update')){
                            new PlatformEventHelper().publishObject('UPDATE',extIdHistListForPENotify);
                        }
                    }
                }
            }
        }
    }
}