/***
****
* Class Name: DynamicValChurnTypeOpptyCheck
* Description: 
** This class gets invoked when Opportunity stageName gets changed to 'Order in Process'.

* @author: Dilowar Hussain
* This has been added as a part of SFDC-19089 

**/
public with sharing class DynamicValChurnTypeOpptyCheck implements DynamicBusinessRuleAction{
   /**
	* Method Name: evaluateRule()
	* @param: List<SObject>
	* @return: Map<SObject,Boolean>
	**/
    public static Boolean avoidRecurr = FALSE;
    public void processRecords(Map<Id,SObject> newRecordMap, 
                                                            Map<Id,SObject> oldRecordMap,
                                                            List <SObject> records, 
                                                            String jsonParameter, 
                                                            String triggerOrder, 
                                                            String triggerContext) {

        LogModel log = LogModel.startLog('DynamicValChurnTypeOpptyCheck', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        Map<Id, Opportunity> distiAccIdOpp = new Map<Id, Opportunity>();
        Set<Id> distiConIds = new Set<ID>();
        Map<Id, Opportunity> resellerAccIdOpp = new Map<Id, Opportunity>();
        Set<Id> reselConIds = new Set<ID>();
		Map<Id, User> mapUser = new Map<Id, User>();
        //String errorMessage = '';
        try{	
			for(User usr : [select id, Role_Name__c from User where (Role_Name__c like '%PSM%' and isActive = TRUE) OR (Profile_Name__c like '%Sales%' and Role_Name__c like '%MSP%' and (NOT(Profile_Name__c like '%Engineer%')) and isActive = TRUE) ]){
				mapUser.put(usr.id, usr);
			}

            if(triggerContext.contains('Insert') || triggerContext.contains('Update')){
                //SetAutoRenewalfieldsonOpp(records);
                for(SObject rec: records){
                    Opportunity opp = (Opportunity)rec;
                    Opportunity opp2 = oldRecordMap == null ? null : (Opportunity)oldRecordMap.get(opp.Id);
                    if (opp2 == null){opp2 = new Opportunity();}
				/*	System.debug('Business Group is ::' + opp.Business_Group__c);
					System.debug('Churn Type is ::' + opp.Churn_Type__c);
					System.debug('Stage Name is:' + opp.stageName);
					System.debug('Opportunity Owner is PSM or not?:' + mapUser.containsKey(opp.OwnerId));*/
                
					if(mapUser.containsKey(opp.OwnerId)){
						if ((opp.stageName != opp2.stageName || opp.OwnerId != opp2.OwnerId ) && opp.Business_Group__c == 'MSP'  && opp.Churn_Type__c == NULL  && opp.MSP_Quote_Full_Amount__c <0  && (opp.stageName == 'Order in Process'  || opp.stageName == 'Closed Won')){
							//System.debug('Churn Type error');
                            //errorMessage = Label.Churn_Type_Error_message_on_Opp;
                            opp.addError(Label.Churn_Type_Error_message_on_Opp);
						}
					}    
                }
            }
            //avoidRecurr = TRUE;
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
    } 
    
}