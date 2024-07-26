/**
* @author Dilowar Hussain
* @date 2023-03-03
*
* @description 
* 
*
* 
* This has been added as a part of SFDC-17119
*/
public with sharing class DynamicBusinessRuleActivateConOwner implements DynamicBusinessRuleAction{
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
        LogModel log = LogModel.startLog('DynamicBusinessRuleActivateConOwner', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        try{
            Set<Id> ownerIds = new Set<Id>();
            Set<Id> accOwnerIds = new Set<Id>();
            Map<id, Account> mapAccount = new Map<Id, Account>();
            Map<Id, Contact> mapContact = new Map<Id, Contact>();
            List<User> lstUSR = new List<User>();
            Map<Id, User> mapUser = new Map<Id, User>();
            List<User> lstUSR02 = new List<User>();
            Map<Id, User> mapUser02 = new Map<Id, User>();
            Set<Id> accIDs = new Set<Id>();
            List<User> lstUser = [select id, name, email, username, profile.Name from User where name like '%Admin Salesforce%' and profile.Name like '%System Administrator%'];
            if((triggerContext.contains('Update') || triggerContext.contains('Insert'))){
                for(SObject rec: records){
                    Contact con = (Contact)rec;
                    Contact con02 = oldRecordMap == null ? null : (Contact)oldRecordMap.get(con.Id);
                    if (con02 == null){con02 = new Contact();}
                    System.debug('Contact Owner is active?' +con.Owner_IsActive__c);
                    if(con.OwnerId != NULL && con.Owner_IsActive__c == FALSE || (con.OwnerId != NULL && con.Owner_IsActive__c == FALSE && con.OwnerId != con02.OwnerId)){
                        System.debug('Contact Update Operation');
                        //ownerIds.add(con.OwnerId);
                        mapContact.put(con.id, con);
                        accIDs.add(con.accountId);
                    }
                }
                if(!accIDs.isEmpty()){
                    for(Account acc : [select id, ownerId, Owner_IsActive__c from Account where id in :accIDs and Owner_IsActive__c = TRUE]){
                        //accOwnerIds.add(acc.ownerId);
                        mapAccount.put(acc.id, acc);
                    }
                    System.debug('mapAccount' +mapAccount);
                    for(SObject rec: records){
                        Contact con03 = (Contact)rec;
                        Contact con04 = oldRecordMap == null ? null : (Contact)oldRecordMap.get(con03.Id);
                        if (con04 == null){con04 = new Contact();}
                        if(!mapAccount.isEmpty() && mapAccount.containsKey(con03.accountId)){
                            con03.ownerId = mapAccount.get(con03.accountId).ownerId;
                        }else if(!test.isRunningTest()){
                            con03.OwnerId = lstUser[0].id;
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