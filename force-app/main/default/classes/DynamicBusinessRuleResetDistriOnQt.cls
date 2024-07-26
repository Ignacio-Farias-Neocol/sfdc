/****
 * Class Name: DynamicBusinessRuleResetDistriOnQt
 * 
 * Description:
 *  This class resets the field, "SBQQ__Distributor__c" on SBQQ__Quote__c 
 *  with respect to it's parent Opportunity's Distributor__c value. 
 *  If Opportunity's Distributor__c is NULL, then SBQQ__Distributor__c will be NULL.
 * 
 *  This code logic gets invoked only when a SBQQ__Quote__c record gets created.
 * 
 * @author Dilowar Hussain
 * @createdDate 12-04-2023
 * 
 * Jira ticket: SFDC-19097
 */
public with sharing class DynamicBusinessRuleResetDistriOnQt implements DynamicBusinessRuleAction{
    /***
     * Method Name:  processRecords
     * @return : void
     * */
	public void processRecords(Map<Id,SObject> newRecordMap, 
                                                            Map<Id,SObject> oldRecordMap,
                                                            List <SObject> records, 
                                                            String jsonParameter, 
                                                            String triggerOrder, 
                                                            String triggerContext) {
             LogModel log = LogModel.startLog('DynamicBusinessRuleResetDistriOnQt', 'processRecords', LogModel.LOG_CATEGORY_APEX);                                                  
             try{
                   List<Opportunity> lstOpp = new List<Opportunity>();
                 	Set<ID> opIDs = new Set<ID>();
                    Map<String, SBQQ__Quote__c> mapQt = new Map<String, SBQQ__Quote__c>();
                 	Map<Id, Opportunity> mapOPP = new Map<Id,Opportunity>();
                    if(triggerContext.contains('Insert')){
                       for(SObject rec: records){
                            SBQQ__Quote__c qt01 = (SBQQ__Quote__c)rec;
                            SBQQ__Quote__c qt02 = oldRecordMap == null ? null : (SBQQ__Quote__c)oldRecordMap.get(qt01.Id);
                            if (qt02 == null){qt02 = new SBQQ__Quote__c();}
                           opIDs.add(qt01.SBQQ__Opportunity2__c);
                           mapQt.put(qt01.SBQQ__Opportunity2__c, qt01);
                       }
                       //system.debug('mapQt is:' +mapQt);
                       if(!mapQt.isEmpty()){
                           lstOpp = [select id, Distributor__c from Opportunity where id in :mapQt.keySet()];
                           //system.debug('lstOpp is:' +lstOpp);
                           for(Opportunity opp :lstOpp ){
                               mapOPP.put(opp.id, opp);
                           }
                           //system.debug('mapOPP is:' +mapOPP);
                           if(!mapOPP.isEmpty()&& !mapQt.isEmpty()){
                               for(SObject rec: records){
                                   SBQQ__Quote__c qt011 = (SBQQ__Quote__c)rec;
                                   //system.debug('Distributor of the Opp is:' +mapOPP.get(qt011.SBQQ__Opportunity2__c).Distributor__c);
                                   qt011.SBQQ__Distributor__c = mapOPP.get(qt011.SBQQ__Opportunity2__c).Distributor__c != NULL ? mapOPP.get(qt011.SBQQ__Opportunity2__c).Distributor__c : NULL;
                                   /*if((mapOPP.get(qt011.SBQQ__Opportunity2__c).Distributor__c) != NULL){
                                       system.debug('Distributor value exists in Oppty');
                                       qt011.SBQQ__Distributor__c = mapOPP.get(qt011.SBQQ__Opportunity2__c).Distributor__c;
                                   }else{
                                       system.debug('Distributor value is NULL in Oppty');
                                       qt011.SBQQ__Distributor__c = NULL;
                                   }*/
                                   //system.debug('Distributor of the Quote is:' +qt011.SBQQ__Distributor__c);
                               }
                           }
                       }
                           
                   }
             }Catch(Exception e){
                 log.addExceptionLog(e);
            	system.debug('Exception'+e.getMessage()+ 'occurred:' +e.getStackTraceString());
             }                                                      	
      }
}