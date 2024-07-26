/**
* @author Dilowar Hussain
* @date 2022/01/05
*
* @group DynamicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to publish a platform event, "Integration_Event__e".
* The platform event will be listened by Mulesoft system further. This is a part of SFDC-16060
*/
public with sharing class DynamicBusinessRuleAPIForJudge implements DynamicBusinessRuleAction{
    
     /*******************************************************************************************************
    * @description publish a platform event, "Integration_Event__e".
    * @param trigger.new map
    * @return none, 
    * @example
    */
    public static Boolean publishEvent = FALSE;
    public void processRecords(Map<Id,SObject> newRecordMap, 
                                                            Map<Id,SObject> oldRecordMap,
                                                            List <SObject> records, 
                                                            String jsonParameter, 
                                                            String triggerOrder, 
                                                            String triggerContext) {

        LogModel log = LogModel.startLog('DynamicBusinessRuleAPIForJudge', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        List<Case> lstCase = new List<Case>();
        Set<ID> caseIDs = new Set<ID>();
        Id caseRTTechId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
        Id caseRTWebId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();
        Id caseRTProfId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        Id caseRTOffId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Offline').getRecordTypeId();
        Id caseRTDPAAId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('DPAAS Cases').getRecordTypeId();
        //System.debug('Start of the process method');
        try{
            if((triggerContext.contains('Update') || triggerContext.contains('Insert')) && !publishEvent){
                //System.debug('Start of the execution');
                for(SObject rec: records){
                    Case cs01 = (Case) rec;
                    Case cs02 = oldRecordMap == null ? null : (Case)oldRecordMap.get(cs01.Id);
                    if (cs02 == null){cs02 = new Case();}
                    /*System.debug('cs01 is:' +cs01);
                    System.debug('cs02 is:' +cs02);
                    System.debug('Cs01 RecordType is:' +cs01.RecordType.name);
                    System.debug('Cs01 Status is:' +cs01.Status);
                    System.debug('Cs02 Status is:' +cs02.Status);*/
                    if((String.valueOf(cs01.RecordTypeId).equals(String.valueOf(caseRTTechId)) ||
                    String.valueOf(cs01.RecordTypeId).equals(String.valueOf(caseRTWebId)) ||
                    String.valueOf(cs01.RecordTypeId).equals(String.valueOf(caseRTProfId)) ||
                    String.valueOf(cs01.RecordTypeId).equals(String.valueOf(caseRTOffId)) ||
                    String.valueOf(cs01.RecordTypeId).equals(String.valueOf(caseRTDPAAId)))){ 
						if(!String.valueOf(cs02.Status).equalsIgnoreCase('Closed')
							&& !String.valueOf(cs02.Status).equalsIgnoreCase('Resolved')){
							//System.debug('Initial Conditions have met');
                            /***
                             * Modified condition as a part of SFDC-16682.
                             * Added condition for the field. "Missing_Serial_Number__c"
                             */
							if((cs01.serial_number__c != NULL ||(cs02.serial_number__c != NULL && cs01.serial_number__c != cs02.serial_number__c))|| (cs01.Status != NULL || (cs02.Status!= NULL && cs01.Status != cs02.Status))|| (cs01.Case_Owner_Person__c != NULL || (cs02.Case_Owner_Person__c != NULL && cs01.Case_Owner_Person__c != cs02.Case_Owner_Person__c))|| (cs01.Engineering_Escalated_By__c != NULL || (cs02.Engineering_Escalated_By__c != NULL && cs01.Engineering_Escalated_By__c != cs02.Engineering_Escalated_By__c))|| (cs01.Escalated_To__c != NULL || (cs02.Escalated_To__c != NULL && cs01.Escalated_To__c != cs02.Escalated_To__c))|| (cs01.Escalation_Approver__c != NULL || (cs02.Escalation_Approver__c != NULL && cs01.Escalation_Approver__c != cs02.Escalation_Approver__c))|| (cs01.Escalated_to_support_escalations_by__c != NULL ||(cs02.Escalated_to_support_escalations_by__c!= NULL && cs01.Escalated_to_support_escalations_by__c != cs02.Escalated_to_support_escalations_by__c))|| (cs01.RMA_Submitted_By__c != NULL ||(cs02.RMA_Submitted_By__c != NULL && cs01.RMA_Submitted_By__c != cs02.RMA_Submitted_By__c))|| (cs01.RMA_Approval_1__c != NULL || (cs02.RMA_Approval_1__c != NULL && cs01.RMA_Approval_1__c != cs02.RMA_Approval_1__c))
                            || (cs01.RMA_Approval_2__c != NULL ||(cs02.RMA_Approval_2__c != NULL && cs01.RMA_Approval_2__c != cs02.RMA_Approval_2__c))
                            || (cs01.Missing_Serial_Number__c != NULL ||(cs02.Missing_Serial_Number__c != NULL && cs01.Missing_Serial_Number__c	!= cs02.Missing_Serial_Number__c))){
								//if((cs02.serial_number__c != NULL && cs01.serial_number__c != cs02.serial_number__c)|| (cs02.Status!= NULL && cs01.Status != cs02.Status)|| (cs02.Case_Owner_Person__c != NULL && cs01.Case_Owner_Person__c != cs02.Case_Owner_Person__c)|| (cs02.Engineering_Escalated_By__c != NULL && cs01.Engineering_Escalated_By__c != cs02.Engineering_Escalated_By__c)|| (cs02.Escalated_To__c != NULL && cs01.Escalated_To__c != cs02.Escalated_To__c)|| (cs02.Escalation_Approver__c != NULL && cs01.Escalation_Approver__c != cs02.Escalation_Approver__c)|| (cs02.Escalated_to_support_escalations_by__c!= NULL && cs01.Escalated_to_support_escalations_by__c != cs02.Escalated_to_support_escalations_by__c)|| (cs02.RMA_Submitted_By__c != NULL && cs01.RMA_Submitted_By__c != cs02.RMA_Submitted_By__c)|| (cs02.RMA_Approval_1__c != NULL && cs01.RMA_Approval_1__c != cs02.RMA_Approval_1__c)|| (cs02.RMA_Approval_2__c != NULL && cs01.RMA_Approval_2__c != cs02.RMA_Approval_2__c)){    
								//System.debug('Conditions met');
								caseIDs.add(cs01.id);
							}
						}
                    }
                }
                //System.debug('caseIDs is:' +caseIDs);
                if(!caseIDs.isEmpty()){
                   /***
                    * Changes done as a part of SFDC-16682

                    * Added an inner query to send all Additional Serial numbers from Additional Serial Access object. 
                    * Also added the Missing_Serial_Number__c to the query.
                    */
                    lstCase = [select id, caseNumber, (select id, Additional_Serial_Number_new__c, Additional_Serial__c from Additional_Serial_Access__r), serial_number__c, Status, Owner.Username, Case_Owner_Person__c, Engineering_Escalated_By__r.username, Escalated_To__r.username, Escalation_Approver__r.username, Escalated_to_support_escalations_by__r.username, RMA_Submitted_By__r.username, RMA_Approval_1__r.username, RMA_Approval_2__r.username, Missing_Serial_Number__c from Case where id in:caseIDs];
                    //System.debug('lstCase is:' +lstCase);
                    if(!lstCase.isEmpty()){
                        new PlatformEventHelper().publishObject('JUD-UPDATE',lstCase);
                    }
                }
            }
            publishEvent = TRUE;

        }Catch(Exception e){
            System.debug('Exception'+ e.getMessage()+'occurred at:' +e.getStackTraceString());
            log.addExceptionLog(e);
        }
    }
}