public class LiveChatTranscriptUserAccepted implements DynamicBusinessRuleAction
{
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List<SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        
        if (records == null || records.size() == 0 ) {
            return;
        }
        
        try {
            List<Case> lCase = new List<Case>();
            for(Sobject lc:records) {
                LiveChatTranscript lct = (LiveChatTranscript) lc;
                if(String.isNotBlank(String.valueOf(lct.CaseId)) && 'InProgress'.equalsIgnoreCase(lct.Status)) {
                    Case c = new Case();
                    c.Id = lct.Caseid;
                    system.debug('@@CaseId:' + c.Id);
                    c.Is_User_Accepted__c = true;
                    c.OwnerId = lct.OwnerId;
                    lCase.add(c);
                }else {
                    system.debug('@@CaseId is blank' + String.valueOf(lct.CaseId) +' chat status:' + lct.Status);
                }
            }
            
            if(!lCase.isEmpty()) {
                system.debug('@@Cases to be updated:' + lCase.size());
                update lCase;       
            }
        }catch(Exception e) {
            System.debug('@@Case updation failed: ' + e);
            
        }
    }
}