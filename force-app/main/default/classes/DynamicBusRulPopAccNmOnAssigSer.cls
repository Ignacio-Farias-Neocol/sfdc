/**
* @author Dilowar Hussain
* @date 2024-01-11
*
* @description 
* 
*
* 
* This has been added as a part of SFDC-20384
*/
public with sharing class DynamicBusRulPopAccNmOnAssigSer implements DynamicBusinessRuleAction{
	/**
    * Method description: 
    * @param
    * @Return
    */
    public void processRecords(Map<Id,SObject> newRecordMap, 
                                                            Map<Id,SObject> oldRecordMap,
                                                            List <SObject> records, 
                                                            String jsonParameter, 
                                                            String triggerOrder, 
                                                            String triggerContext) {
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('DynamicBusRulPopAccNmOnAssigSer', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        try{
            List<Serial__c> ListSerials = new List<Serial__c>();
            Map<Id, Assigned_Serial__c> mapAssSerial = new Map<Id, Assigned_Serial__c>();
            Map<Id, Serial__c> mapSerial = new Map<Id, Serial__c>();
            Map<Id, ID> mapSerAssSerial = new Map<ID, ID>();
            if((/*triggerContext.contains('Update') ||*/ triggerContext.contains('Insert'))){
                for(SObject rec: records){
                    Assigned_Serial__c acc = (Assigned_Serial__c)rec;
                    Assigned_Serial__c acc02 = oldRecordMap == null ? null : (Assigned_Serial__c)oldRecordMap.get(acc.Id);
                    if (acc02 == null){acc02 = new Assigned_Serial__c();}
                    if((acc.End_User_Account__c != NULL && acc.Serial__c != NULL) 
                       /*||(acc.End_User_Account__c != NULL && acc.End_User_Account__c != acc02.End_User_Account__c && acc.Serial__c != NULL)
                       || (acc.End_User_Account__c != NULL && acc.Serial__c != acc02.Serial__c && acc.Serial__c != NULL)*/){
                        mapAssSerial.put(acc.Serial__c, acc);
                        //mapSerAssSerial.put(acc.id, acc.Serial__c);
                        //serialIds.add(acc.Serial__c);
                    }
                }if(!mapAssSerial.isEmpty()){
                    for(Serial__c sr: [select id, Account__c from Serial__c where id in :mapAssSerial.keySet()]){
                        if(mapAssSerial.containsKey(sr.id) && !String.valueOf(sr.Account__c).equals(String.valueOf(mapAssSerial.get(sr.id).End_User_Account__c))){
                            sr.Account__c = mapAssSerial.get(sr.id).End_User_Account__c;
                            ListSerials.add(sr);
                        }
                    }
                }if(!ListSerials.isEmpty()){
                    update ListSerials;
                }
            }                                                   
        }Catch(Exception e){
            log.addExceptionLog(e);
            system.debug('Exception occurred:' +e.getStackTraceString());
        }
     }
}