/**
* @author Dilowar Hussain
* @date 2023-07-11
*
* @description 
* 
*
* 
* This has been added as a part of SFDC-19424
*/
public with sharing class DynamicBusinessRuleUpdateAccZIField implements DynamicBusinessRuleAction{

    /**
    * Method description: This method enhances the Judge API integration.
    * @param
    * @Return
    * This has been added as a part of SFDC-19424
    */
    //public static Boolean publishEvent = FALSE;
    public void processRecords(Map<Id,SObject> newRecordMap, 
                                                            Map<Id,SObject> oldRecordMap,
                                                            List <SObject> records, 
                                                            String jsonParameter, 
                                                            String triggerOrder, 
                                                            String triggerContext) {
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('DynamicBusinessRuleUpdateAccZIField', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        try{
            //system.debug('Test Invoke');
            Set<ID> accountIDs = new Set<ID>();
            Map<String, String> accConMap = new Map<String, String>();
            List<Account> lstAccUpdate = new List<Account>();
            Map<Id, Account> mapAcc = new Map<Id, Account>();
            if((triggerContext.contains('Update') || triggerContext.contains('Insert'))){
                //system.debug('Test Trigger Context');
                for(SObject rec: records){
                    Contact con01 = (Contact)rec;
                    Contact con02 = oldRecordMap == null ? null : (Contact)oldRecordMap.get(con01.Id);
                    if (con02 == null){con02 = new Contact();}
                    //if(con01.DOZISF__ZoomInfo_Id__c != NULL){
                        //system.debug('Zoom Info available');
                        accountIDs.add(con01.AccountId);
                        accConMap.put(con01.id, con01.AccountId);
                    //}
                }
                if(!accountIDs.isEmpty()){
                    for(Account acc: [select id, name, ZI_Enriched__c from Account where Id in :accountIDs FOR UPDATE]){
                        mapAcc.put(acc.id, acc);
                    }
                }
                //system.debug('mapAcc is:' +mapAcc);
                //system.debug('accConMap is:' +accConMap);
                for(SObject rec: records){
                    Contact con011 = (Contact)rec;
                    if(accConMap.containsKey(con011.id) && mapAcc.containsKey(accConMap.get(con011.id))){
                        if(con011.DOZISF__ZoomInfo_Id__c != NULL){
                            //system.debug('Check ZI Enriched');
                            mapAcc.get(accConMap.get(con011.id)).ZI_Enriched__c = TRUE;
                            lstAccUpdate.add(mapAcc.get(accConMap.get(con011.id)));
                        }else{
                            //system.debug('Do not Check ZI Enriched');
                            mapAcc.get(accConMap.get(con011.id)).ZI_Enriched__c = FALSE;
                            lstAccUpdate.add(mapAcc.get(accConMap.get(con011.id)));
                        }
                    }
                }
                if(!lstAccUpdate.isEmpty()){
                    //system.debug('lstAccUpdate is:' +lstAccUpdate);
                    update lstAccUpdate;
                }
            }

        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
    }
    
}