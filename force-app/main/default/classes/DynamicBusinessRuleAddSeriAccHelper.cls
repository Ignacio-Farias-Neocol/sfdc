/**
* @author Dilowar Hussain
* @date 2022-08-22
*
* @description 
* 
*
* 
* This has been added as a part of SFDC-16682 
*/
public with sharing class DynamicBusinessRuleAddSeriAccHelper implements DynamicBusinessRuleAction{

    /**
    * Method description: This method enhances the Judge API integration.
    * @param
    * @Return
    * This has been added as a part of SFDC-16682
    */
    public static Boolean publishEvent = FALSE;
    public void processRecords(Map<Id,SObject> newRecordMap, 
                                                            Map<Id,SObject> oldRecordMap,
                                                            List <SObject> records, 
                                                            String jsonParameter, 
                                                            String triggerOrder, 
                                                            String triggerContext) {
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('DynamicBusinessRuleAddSeriAccHelper', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        Set<ID> CaseIDS = new Set<ID>();
        List<Case> lstCase = new List<Case>();
        List<Case> lstCasePub = new List<Case>();
        try{
            Id caseRTTechId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
            Id caseRTWebId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();
            Id caseRTProfId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
            Id caseRTOffId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Offline').getRecordTypeId();
            Id caseRTDPAAId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('DPAAS Cases').getRecordTypeId();
            if((triggerContext.contains('Update') || triggerContext.contains('Insert')) && !publishEvent){
                for(SObject rec: records){
                    Additional_Serial_Access__c addSerAcc = (Additional_Serial_Access__c)rec;
                    Additional_Serial_Access__c addSerAcc02 = oldRecordMap == null ? null : (Additional_Serial_Access__c)oldRecordMap.get(addSerAcc.Id);
                    if (addSerAcc02 == null){addSerAcc02 = new Additional_Serial_Access__c();}
                    if((addSerAcc.Case__c != NULL && addSerAcc.Additional_Serial__c != NULL && addSerAcc02.Additional_Serial__c != NULL && addSerAcc.Additional_Serial__c != addSerAcc02.Additional_Serial__c)
                        ||(addSerAcc.Case__c != NULL && addSerAcc.Additional_Serial__c != NULL)){
                        CaseIDS.add(addSerAcc.Case__c);
                    }
                }
                //system.debug('CaseIDS is:'+CaseIDS);
                lstCase = [select id, caseNumber, RecordTypeId, (select id, Additional_Serial_Number_new__c, Additional_Serial__c from Additional_Serial_Access__r), serial_number__c, Status, Owner.Username, Case_Owner_Person__c, Engineering_Escalated_By__r.username, Escalated_To__r.username, Escalation_Approver__r.username, Escalated_to_support_escalations_by__r.username, RMA_Submitted_By__r.username, RMA_Approval_1__r.username, RMA_Approval_2__r.username, Missing_Serial_Number__c from Case where id in : CaseIDS];
                //system.debug('lstCase is:' +lstCase);
                for(Case cs01 : lstCase){
                    if((String.valueOf(cs01.RecordTypeId).equals(String.valueOf(caseRTTechId)) ||
                    String.valueOf(cs01.RecordTypeId).equals(String.valueOf(caseRTWebId)) ||
                    String.valueOf(cs01.RecordTypeId).equals(String.valueOf(caseRTProfId)) ||
                    String.valueOf(cs01.RecordTypeId).equals(String.valueOf(caseRTOffId)) ||
                    String.valueOf(cs01.RecordTypeId).equals(String.valueOf(caseRTDPAAId)))){
                        if(!String.valueOf(cs01.Status).equalsIgnoreCase('Closed')
							&& !String.valueOf(cs01.Status).equalsIgnoreCase('Resolved')){
                                lstCasePub.add(cs01);
                        } 
                    }
                }
                //system.debug('lstCasePub is:' +lstCasePub);
                if(!lstCasePub.isEmpty()){
                    new PlatformEventHelper().publishObject('JUD-UPDATE',lstCase);
                }
            }
            publishEvent = TRUE;
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
    }
    
}