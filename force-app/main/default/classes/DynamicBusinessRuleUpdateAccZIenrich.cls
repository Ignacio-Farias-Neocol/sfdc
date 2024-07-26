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
public with sharing class DynamicBusinessRuleUpdateAccZIenrich implements DynamicBusinessRuleAction{

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
        LogModel log = LogModel.startLog('DynamicBusinessRuleUpdateAccZIenrich', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        try{
            //system.debug('Test Invoke');

            List<Id> listcontactId = new List<Id>();
            
            if((triggerContext.contains('Update') || triggerContext.contains('Insert'))){
                //system.debug('Test Trigger Context');
                for(SObject rec: records){
                    Contact con01 = (Contact)rec;
                    Contact con02 = oldRecordMap == null ? null : (Contact)oldRecordMap.get(con01.Id);
                    if (con02 == null){
                        con02 = new Contact();
                        listcontactId.add(con01.id);
                    }else{
                        if(con01.DOZISF__ZoomInfo_Id__c!=con02.DOZISF__ZoomInfo_Id__c)
                           listcontactId.add(con01.id);
                    }
            
                }
           }
           
            if(!listcontactId.IsEmpty())
               updateAccount(listcontactId);

        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
    }
    
    @future
    public static void updateAccount(List<Id> ContactIds){
        try{
            Map<Id,Account> MapAccountupd = new map<Id,Account>();
            for(Contact ocon : [Select Id,AccountId,DOZISF__ZoomInfo_Id__c from Contact where Id IN : ContactIds]){
                if(ocon.DOZISF__ZoomInfo_Id__c != NULL){
                    Account oacc = new Account(Id=ocon.AccountId,ZI_Enriched__c = TRUE);
                    MapAccountupd.put(ocon.AccountId,oacc);
                }else{
                    if(!MapAccountupd.containskey(ocon.AccountId)){
                        Account oacc = new Account(Id=ocon.AccountId,ZI_Enriched__c = FALSE);
                        MapAccountupd.put(ocon.AccountId,oacc);
                    }
                }
            }
            
            if(!MapAccountupd.IsEmpty()){
               Database.update(MapAccountupd.values(),false);
            }
        }catch(Exception ex){
            system.debug('Exception occurred:' +ex.getStackTraceString());
        }
    }
    
}