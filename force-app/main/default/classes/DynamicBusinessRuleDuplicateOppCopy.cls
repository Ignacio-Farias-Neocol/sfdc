/****
 * Class Name: DynamicBusinessRuleDuplicateOppCopy
 * Description:
 *  This class gets invoked when an Opportunity is marked as Closed Lost.
 * 
 * @author Dilowar Hussain
 * @createdDate 15-11-2022
 *  
 *  Jira ticket: SFDC-17211
 */
public with sharing class DynamicBusinessRuleDuplicateOppCopy implements DynamicBusinessRuleAction{
    /**
     * 
     */
    public static void processRecords(Map<Id,SObject> newRecordMap, 
                                                            Map<Id,SObject> oldRecordMap,
                                                            List <SObject> records, 
                                                            String jsonParameter, 
                                                            String triggerOrder, 
                                                            String triggerContext) {
        LogModel log = LogModel.startLog('DynamicBusinessRuleDuplicateOppCopy', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        Map<id, Opportunity> mapClosedOpp = new Map<Id, Opportunity>();
        Map<String, String> mapDupOpp = new Map<String, String>();
        try{
            if(triggerContext.contains('Update')){
                for(SObject rec: records){
                    Opportunity opp = (Opportunity)rec;
                    Opportunity opp2 = oldRecordMap == null ? null : (Opportunity)oldRecordMap.get(opp.Id);
                    if (opp2 == null){opp2 = new Opportunity();}
                    if((opp.stageName == 'Closed Lost' && opp.Closed_Lost_Reason__c == 'Duplicate' && opp.Duplicate_Opportunity__c != NULL)
                        && (opp.stageName != opp2.stageName || opp.Closed_Lost_Reason__c != opp2.Closed_Lost_Reason__c || opp.Duplicate_Opportunity__c != opp2.Duplicate_Opportunity__c)){
                        //System.debug('Initial Consitions');
                        mapClosedOpp.put(opp.id, opp);
                        mapDupOpp.put(opp.Duplicate_Opportunity__c, opp.id);
                    }
                }
                //System.debug('mapClosedOpp is:' +mapClosedOpp);
                //System.debug('mapDupOpp is:' +mapDupOpp);
                if(!mapClosedOpp.isEmpty() && !mapDupOpp.isEmpty()){
                    System.enqueueJob(new DuplicateOpportunityFieldsMapQueue(mapClosedOpp, mapDupOpp));
                }
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
    }
    
}