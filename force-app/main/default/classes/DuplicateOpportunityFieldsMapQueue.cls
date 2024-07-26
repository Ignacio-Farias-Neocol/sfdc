/****
 * Class Name: DuplicateOpportunityFieldsMapQueue
 * Description:
 *  Queueable batch gets invoked from the class, DynamicBusinessRuleDuplicateOppCopy
 * 
 * @author Dilowar Hussain
 * @createdDate 15-11-2022
 *  
 *  Jira ticket: SFDC-17211
 */
public with sharing class DuplicateOpportunityFieldsMapQueue implements Queueable{
    //Member variables
    public Map<Id, Opportunity> oppMap;
    public Map<String, String> dupOppMap;
   
    //Construtor to populate member variables
    public DuplicateOpportunityFieldsMapQueue(Map<Id, Opportunity> oppMap, Map<String, String> dupOppMap){
        this.oppMap = oppMap;
        this.dupOppMap = dupOppMap;
    }
    /**
     * Execute Method
     * @Param QueueableContext context
     */
    public void execute(QueueableContext context) {
        LogModel log = LogModel.startLog('DuplicateOpportunityFieldsMapQueue', 'execute', LogModel.LOG_CATEGORY_APEX);
        List<Opportunity> lstOppUpdate = new List<Opportunity>();
        //System.debug('oppMap is:' +oppMap);
        //System.debug('oppMap is:' +oppMap);
        try{
            if(!dupOppMap.isEmpty() && !oppMap.isEmpty()){
                System.debug('Final conditions');
                for(Opportunity dOpp: [select id, POC_Stage__c, POC_Summary__c, POC_Deployment_Type__c, Primary_SE__c, Secondary_SE__c, POC_Start_Date__c, POC_End_Date__c, Date_SE_Notes_Last_Updated__c, SE_Notes__c, Technical_Success_Criteria__c from Opportunity where id in :dupOppMap.keySet()]){
                    if(dOpp.POC_Stage__c == NULL){
                        dOpp.POC_Stage__c = oppMap.get(dupOppMap.get(dOpp.id)).POC_Stage__c != NULL ? oppMap.get(dupOppMap.get(dOpp.id)).POC_Stage__c : '';
                        //System.debug('POC Stage is:' +dOpp.POC_Stage__c);
                    }if(dOpp.POC_Summary__c == NULL){
                        dOpp.POC_Summary__c = oppMap.get(dupOppMap.get(dOpp.id)).POC_Summary__c != NULL ? oppMap.get(dupOppMap.get(dOpp.id)).POC_Summary__c : '';
                        //System.debug('POC Summary is:' +dOpp.POC_Summary__c);
                    }if(dOpp.POC_Deployment_Type__c == NULL){
                        dOpp.POC_Deployment_Type__c = oppMap.get(dupOppMap.get(dOpp.id)).POC_Deployment_Type__c != NULL ? oppMap.get(dupOppMap.get(dOpp.id)).POC_Deployment_Type__c : '';
                        //System.debug('POC Deployment Type is:' +dOpp.POC_Deployment_Type__c);
                    }if(dOpp.Primary_SE__c == NULL){
                        dOpp.Primary_SE__c = oppMap.get(dupOppMap.get(dOpp.id)).Primary_SE__c != NULL ? oppMap.get(dupOppMap.get(dOpp.id)).Primary_SE__c : NULL;
                        //System.debug('Primary SE is:' +dOpp.Primary_SE__c);
                    }if(dOpp.Secondary_SE__c == NULL){
                        dOpp.Secondary_SE__c = oppMap.get(dupOppMap.get(dOpp.id)).Secondary_SE__c != NULL ? oppMap.get(dupOppMap.get(dOpp.id)).Secondary_SE__c : NULL;
                        //System.debug('Secondary SE is:' +dOpp.Secondary_SE__c);
                    }if(dOpp.POC_Start_Date__c == NULL){
                        dOpp.POC_Start_Date__c = oppMap.get(dupOppMap.get(dOpp.id)).POC_Start_Date__c != NULL ? oppMap.get(dupOppMap.get(dOpp.id)).POC_Start_Date__c : NULL;
                        //System.debug('POC_Start_Date__c is:' +dOpp.POC_Start_Date__c);
                    }if(dOpp.POC_End_Date__c == NULL){
                        dOpp.POC_End_Date__c = oppMap.get(dupOppMap.get(dOpp.id)).POC_End_Date__c != NULL ? oppMap.get(dupOppMap.get(dOpp.id)).POC_End_Date__c : NULL;
                        //System.debug('POC_End_Date__c is:' +dOpp.POC_End_Date__c);
                    }if(dOpp.SE_Notes__c == NULL){
                        dOpp.SE_Notes__c = oppMap.get(dupOppMap.get(dOpp.id)).SE_Notes__c != NULL ? oppMap.get(dupOppMap.get(dOpp.id)).SE_Notes__c : NULL;
                        //System.debug('SE_Notes__c is:' +dOpp.SE_Notes__c);
                    }if(dOpp.Technical_Success_Criteria__c == NULL){
                        dOpp.Technical_Success_Criteria__c = oppMap.get(dupOppMap.get(dOpp.id)).Technical_Success_Criteria__c != NULL ? oppMap.get(dupOppMap.get(dOpp.id)).Technical_Success_Criteria__c : NULL;
                        //System.debug('Technical_Success_Criteria__c is:' +dOpp.Technical_Success_Criteria__c);
                    }
                    lstOppUpdate.add(dOpp);
                    //system.debug('lstOppUpdate is:' +lstOppUpdate);
                }if(!lstOppUpdate.isEmpty()){
                    update lstOppUpdate;
                }
            }
        }Catch (Exception e) {
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
    }
}