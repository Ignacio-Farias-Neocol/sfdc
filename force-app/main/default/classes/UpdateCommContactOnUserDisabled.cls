Public with sharing class UpdateCommContactOnUserDisabled implements DynamicBusinessRuleAction  {

 public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
 
if(!System.isBatch()){
   if (triggerOrder == 'POST') {
      if(triggerContext.contains('Update')){
            Set<Id> contactIds = new Set<Id>();
            Set<Id> conUpdate=new Set<Id>();
            for(SObject newAccRecord: records){
            SObject oldAccRecord = oldRecordMap.get((Id)newAccRecord.get('Id'));
            
               if(newAccRecord.get('IsPortalEnabled')==false )
                  {
                     contactIds.add((Id)oldAccRecord.get('ContactId'));
                  }
                }
                
                if (contactIds.size() > 0) {
                    updateContacts(contactIds);
                }
            }
        }
  }
}

@future
Public static void updateContacts(Set<Id> contactIds)
{
      System.Debug('contactIds::'+contactIds);
      List <Contact> lstcontacts = [select id, Community_Enabled__c from Contact where Id in: contactIds];
            for (Contact c: lstcontacts ) {
                c.Community_Enabled__c= 'Community Disabled';
             
           }
            
    update lstcontacts;
}
}