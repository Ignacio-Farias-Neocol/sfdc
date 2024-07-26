public class LiveChatTranscriptOwnerHandler implements DynamicBusinessRuleAction
{
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List<SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        
        if (records == null || records.size() == 0 ) {
            return;
        }
        
        try {
            Id americasQueue = [SELECT Id,DeveloperName FROM Group WHERE DeveloperName='Contact_Center_Americas' AND Type = 'Queue' LIMIT 1].Id;
            List<Case> lCase = new List<Case>();
            for(Sobject lc:records) {
                LiveChatTranscript lct = (LiveChatTranscript) lc;
                if(String.isNotBlank(String.valueOf(lct.CaseId)) && 'Missed'.equalsIgnoreCase(lct.Status)) {
                    Case c = new Case();
                    c.Id = lct.Caseid;
                    system.debug('@@CaseId:' + c.Id);
                    c.Chat_Missed__c = true;
                    c.OwnerId = americasQueue;
                    c.Web_Region__c = 'Americas';
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