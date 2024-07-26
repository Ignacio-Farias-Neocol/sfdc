/**
* @author Rahul M
* @date 5/16/2022
*
* @group DynamicBusinessRuleAsset 
* */

public  class DynamicBusinessRuleAsset implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {

        System.Debug('processRecords');
       
        if (triggerOrder == 'POST') { 

            if (triggerContext.contains('Update')) {

               rmaReplaceSubUpdate(records, oldRecordMap,triggerContext);
            }           
        }
    }

    private void rmaReplaceSubUpdate(List<SObject> records, Map<Id,SObject> oldRecordMap, String triggerContext){

        System.Debug('rmaReplaceSubUpdate');

        Set<Id> assetIds = new Set<Id>();
        for (Asset record : (List<Asset>)records) {

            if(triggerContext.contains('Update'))  {

                SObject oldRecord = oldRecordMap.get((Id)record.get('Id'));

                if(oldRecord!=null){

                    if((record.get('SBCF_Serial_Number__c')!=oldRecord.get('SBCF_Serial_Number__c')
                     || record.get('Product2Id')!=oldRecord.get('Product2Id'))
                     && !String.isEmpty(record.Product2Id) &&   !String.isEmpty(record.SBCF_Serial_Number__c)){

                        assetIds.add(record.Id);
                        System.Debug('assetIds::'+ assetIds);
                }
               }
            }
        }

        if(assetIds!=null && !assetIds.isEmpty())
          updateSubs(assetIds);
    } 

    private void updateSubs(Set<Id> assetIds){

      ID jobID = System.enqueueJob(new AsyncUpdateSubs(assetIds));
      System.debug('Job to update Subs triggered with jobID::'+jobID);       
    } 
}