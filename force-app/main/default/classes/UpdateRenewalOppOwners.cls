/**
* @author Dilowar
* @date 2024
*
* Class Name: UpdateRenewalOppOwners
*
* @description This batch class helps to make owner assignment for existing Renewal opportunities.
*              The internal logic follows the same as the flow, "Ownership Management - Renewal Opportunities".
*
* This has been implemented as part of SFDC-20514.
*/
global class UpdateRenewalOppOwners implements Database.Batchable<sObject> {
	/**
	 * Start Method
	 * */
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //String recordId = '006f2000021s0YsAAI';
        return Database.getQueryLocator([
            select id, name, Territory_ID__c, ownerId from Opportunity where (RecordType_Name__c = 'Renewal' OR RecordType_Name__c = 'Locked Renewal') 
            and Territory_ID__c != NULL and stageName != 'Closed Won' and stageName != 'Closed Lost' and Elligible_for_Renewal_Owner_assignme__c = TRUE
            and owner.name = 'System Renewal User' and Business_Group__c  = 'Core'
         ]);
        /*return Database.getQueryLocator([
            select id, name, Territory_ID__c, ownerId from Opportunity where (RecordType_Name__c =:rType_01 OR RecordType_Name__c =:rType_01) 
            and Territory_ID__c != NULL and stageName !=:stg_01 and stageName != :stg_02 and Elligible_for_Renewal_Owner_assignme__c = TRUE
            and id = :recordId
         ]);*/
    }
	/**
	 * Execute Method
	 * */
    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        //system.debug('Scope is:' +scope);
        //system.debug('Scope size is:' +scope.size());
        Set<ID> terrIDs = new Set<ID>();
        Map<id, Opportunity> mapOpp = new Map<Id, Opportunity>();
        Map<String, String> mapPrimaryUser = new Map<String, String>();
        Map<String, String> mapBackupUser = new Map<String, String>();
        Map<String, String> mapOppTerr = new Map<String, String>();
        List<Opportunity> lstOpp = new List<Opportunity>();
        try{
        for (Opportunity opp : scope) {
            terrIDs.add(opp.Territory_ID__c);
            mapOpp.put(opp.id, opp);
           // mapOppTerr.put(opp.id, opp.Territory_ID__c);
        }
        if(!terrIDs.isEmpty()){
            for(UserTerritory2Association uta : [select id, userId, isActive, user.IsActive, Territory2Id, RoleInTerritory2 from UserTerritory2Association where Territory2Id in :terrIDs 
                                                 and (RoleInTerritory2 = 'Renewals' OR RoleInTerritory2 = 'Renewal - Backup Owner')]){
                if(uta.RoleInTerritory2 == 'Renewals' && uta.user.isActive == TRUE && uta.isActive == TRUE){
                    //system.debug('Primary user is available');
                    mapPrimaryUser.put(uta.Territory2Id, uta.userId);
                }else if(uta.RoleInTerritory2 == 'Renewal - Backup Owner' && uta.user.isActive == TRUE && uta.isActive == TRUE){
                    //system.debug('BackUP user is available');
                    mapBackupUser.put(uta.Territory2Id, uta.userId);
                }
            }if(!mapOpp.isEmpty()){
                for(Opportunity opp02 : mapOpp.values()){
                    if(mapPrimaryUser.containsKey(opp02.Territory_ID__c) && opp02.OwnerId != NULL 
                        && String.valueOf(opp02.OwnerId) != String.valueOf(mapPrimaryUser.get(opp02.Territory_ID__c))){
                            //System.debug('Assign Primary User');
                            opp02.OwnerId = mapPrimaryUser.get(opp02.Territory_ID__c);
                            lstOpp.add(opp02);
                    }else if(mapBackupUser.containsKey(opp02.Territory_ID__c) && opp02.OwnerId != NULL
                        && String.valueOf(opp02.OwnerId) != String.valueOf(mapBackupUser.get(opp02.Territory_ID__c))
                        && String.valueOf(opp02.OwnerId) != String.valueOf(mapPrimaryUser.get(opp02.Territory_ID__c))){
                            //System.debug('Assign Backup User');
                            opp02.OwnerId = mapBackupUser.get(opp02.Territory_ID__c);
                            lstOpp.add(opp02);
                    }
                } 
                if(!lstOpp.isEmpty()){
                    //system.debug('lstOpp size is:' +lstOpp.size());
                    Database.SaveResult[] srList = Database.update(lstOpp, false);
                    for (Integer i = 0; i < srList.size(); i++) {
                        Opportunity o = new Opportunity(ID = lstOpp[i].Id);
                        Database.SaveResult sr = srList[i];
                        if (!sr.isSuccess()) {
                             String errorMsg = '';
                    		 for(Database.Error err : sr.getErrors()) {
                        		errorMsg = errorMsg + err.getMessage() + '\n';
                    		 }
							 System.Debug('*** error Renewal Opportunity ' + o.Id + ', errorMsg ' + errorMsg);
                        }
                    }
                }
            }
        }
        }Catch(Exception e){
          system.debug('Exception' +e.getMessage()+ 'Occurred At' +e.getStackTraceString());
        }
    }
     

    global void finish(Database.BatchableContext BC) {
        
    }
}