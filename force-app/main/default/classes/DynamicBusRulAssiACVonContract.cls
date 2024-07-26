/**
* @author Dilowar
* @date 2024
*
* @group DynmaicBusinessRuleAction
*
* @description This apex class contains the logic to assign ACV field value on Contract
* when an amendment gets created on it. 
*
* This has been implemented as part of SFDC-20558.
*/
public with sharing class DynamicBusRulAssiACVonContract implements DynamicBusinessRuleAction{
    public void processRecords( Map<Id,SObject> newRecordMap, 
                                Map<Id,SObject> oldRecordMap, 
                                List <SObject> records, 
                                String jsonParameter, 
                                String triggerOrder, 
                                String triggerContext) {
        Set<ID> oppIds = new Set<ID>();
        try{
            if(triggerContext.contains('Insert') || triggerContext.contains('Update')) {
                for(Opportunity opp : (List<Opportunity>)records){
                    Opportunity oppOld = oldRecordMap == null ? new Opportunity() : (Opportunity)oldRecordMap.get(opp.Id);
                    if (oppOld == null)
                    oppOld = new Opportunity();
                    if(opp.SBQQ__AmendedContract__c != NULL && opp.Business_Group__c == 'Core' || 
                    	(oppOld.SBQQ__AmendedContract__c != NULL && opp.Business_Group__c == 'Core' 
                         && oppOld.SBQQ__AmendedContract__c != opp.SBQQ__AmendedContract__c)){
                             system.debug('Intial conditions satisfied');
                             if(opp.SBCF_Annual_Contract_Value2__c != NULL && oppOld.SBCF_Annual_Contract_Value2__c == NULL
                                || (opp.SBCF_Annual_Contract_Value2__c != NULL && oppOld.SBCF_Annual_Contract_Value2__c != NULL && opp.SBCF_Annual_Contract_Value2__c != oppOld.SBCF_Annual_Contract_Value2__c)){
                                     oppIds.add(opp.id);
                                }
                        	//mapOppCon.put(opp.SBQQ__AmendedContract__c, opp);
                    }
               	}if(!oppIds.isEmpty()){
                    //String jsonBody = JSON.serialize(mapOppCon);
                    system.debug('Call the future method');
                    calculateACVAmendContrat(oppIds);
                }
            }
        }Catch(Exception e){
            system.debug('Exception' +e.getMessage()+ 'Occurred At' +e.getStackTraceString());
        }                       
    }
    @future
     private static void calculateACVAmendContrat(Set<Id> opIDs){
         Map<ID, Opportunity> mapOppCon = new Map<ID, Opportunity>();
         List<Contract> lstContractUpdate = new List<Contract>();
         try{
             for(Opportunity opp : [select id,SBCF_Annual_Contract_Value2__c, SBQQ__AmendedContract__c from Opportunity where id in:opIDs]){
                mapOppCon.put(opp.SBQQ__AmendedContract__c, opp);
             }
             system.debug('mapOppCon is:' +mapOppCon);
             if(!mapOppCon.isEmpty()){
                 for(Contract contr : [select id, Annual_Contract_Value__c from Contract where id in :mapOppCon.keySet()]){
                     if(mapOppCon.containsKey(contr.id)){
                         system.debug('Final condition satisfied');
                        contr.Annual_Contract_Value__c = contr.Annual_Contract_Value__c + (mapOppCon.get(contr.id).SBCF_Annual_Contract_Value2__c != NULL ? mapOppCon.get(contr.id).SBCF_Annual_Contract_Value2__c : 0.00);
                        lstContractUpdate.add(contr);
                     }
             	 }
                 if(!lstContractUpdate.isEmpty()){
                     system.debug('lstContractUpdate is:' +lstContractUpdate);
                	update lstContractUpdate;
             	 }
             }
         }Catch(Exception e){
             system.debug('Exception' +e.getMessage()+ 'Occurred At' +e.getStackTraceString());
         }                                
     }
}