/**
* @author Dilowar Hussain
* @date 2023-01-12
*
* @description 
* This class checks the incoming Primary_Product_Family_2__c value. 
* If the value is inactive, then the same field gets updated as empty. 
* This logic is mainly for opportunities which do get created via Contract Renewal Process.
*
* 
* This has been added as a part of SFDC-18427
*/
public with sharing class DynamicBusinessRuleOpptyPickListAssign implements DynamicBusinessRuleAction {
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
        LogModel log = LogModel.startLog('DynamicBusinessRuleOpptyPickListAssign', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        try{
            if(triggerContext.contains('Insert')) {
                Map<String, String> pickListValuesActive   = new Map<String, String>();
                Map<String, String> pickListValuesInactive = new Map<String, String>();

                Schema.DescribeFieldResult fieldResult = Opportunity.Primary_Product_Family_2__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                //System.debug('ple size is:' +ple.size());
                for(Schema.PicklistEntry pickListVal : ple) {
                if(pickListVal.isActive()) {
                    pickListValuesActive.put(pickListVal.getLabel(), pickListVal.getValue());
                } else {
                    pickListValuesInactive.put(pickListVal.getLabel(), pickListVal.getValue());
                }
                }
                //System.debug('pickListValuesActive size is:' +pickListValuesActive.size());
                //System.debug('pickListValuesActive specific value is:' +pickListValuesActive.get('SSL-VPN Vx'));
                //System.debug('pickListValuesInactive size is:' +pickListValuesInactive.size());
                for(SObject rec: records){
                    Opportunity op = (Opportunity)rec;
                    Opportunity op2 = oldRecordMap == null ? null : (Opportunity)oldRecordMap.get(op.Id);
                    if (op2 == null){op2 = new Opportunity();}
                    if(op.Primary_Product_Family_2__c != NULL || (op.Primary_Product_Family_2__c != NULL && op.Primary_Product_Family_2__c != op2.Primary_Product_Family_2__c)){
                        if(!pickListValuesActive.isEmpty() && !pickListValuesActive.containsKey(op.Primary_Product_Family_2__c)){
                            //System.debug('Picklist field value is inactive');
                            op.Primary_Product_Family_2__c = '';
                        }
                        //To be removed later
                        /*if(!pickListValuesActive.isEmpty() && pickListValuesActive.containsKey(op.Primary_Product_Family_2__c)){
                            System.debug('Picklist field value is active');
                            //op.Primary_Product_Family_2__c = '';
                        }*/
                    }
                }
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
    }
    

}