/**
* @author Dilowar Hussain
* @date 2023-03-23
*
* @group DynmaicBusinessRuleAction
*
* @description:
*   Written as a part of SFDC-18848 
*/
public with sharing class DynamicBusinessRuleSetSalesRwOnCs implements DynamicBusinessRuleAction{
    /**
    * Method description:
    * @param
    * @Return
    * This has been added as a part of SFDC-18427
    */
    public static void processRecords(Map<Id,SObject> newRecordMap, 
                                                            Map<Id,SObject> oldRecordMap,
                                                            List <SObject> records, 
                                                            String jsonParameter, 
                                                            String triggerOrder, 
                                                            String triggerContext) {
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('DynamicBusinessRuleSetSalesRwOnCs', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        try{
            Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Request Quote').getRecordTypeId();
            if(triggerContext.contains('Insert') || triggerContext.contains('Update')) {
                for(SObject rec: records){
                    Case cs01 = (Case)rec;
                    Case cs02 = oldRecordMap == null ? null : (Case)oldRecordMap.get(cs01.Id);
                    if (cs02 == null){cs02 = new Case();}
                    if(String.valueOf(cs01.RecordTypeId).equals(String.valueOf(caseRecordTypeId)) && cs01.Region_Theatre__c != NULL
                        || (String.valueOf(cs01.RecordTypeId).equals(String.valueOf(caseRecordTypeId)) && cs01.Region_Theatre__c != NULL && cs01.Region_Theatre__c != cs02.Region_Theatre__c)){
                        if(cs01.Region_Theatre__c == 'EMEA' || cs01.Region_Theatre__c == 'APAC'){
                            cs01.Sales_Review__c = 'Yes';
                        }
                    }
                }
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
    }
    
}