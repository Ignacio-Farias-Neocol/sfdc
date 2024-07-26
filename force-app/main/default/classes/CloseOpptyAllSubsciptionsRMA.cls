/**
 * Created by Dilowar Hussain on 04/07/2022.
 *  @Date 04/07/2022
 *
 *  Description:
 *  
 *  
 *  Added as a part of SFDC-17285
 */
global with sharing class CloseOpptyAllSubsciptionsRMA implements Database.Batchable<SObject>{
   
    public String closedWon = 'Closed Won';
    public String closedLost = 'Closed Lost';
    public String mspBG = 'MSP';
    //Added as a part of SFDC-18981: START
    public String sonianBG = 'Sonian';
    //Added as a part of SFDC-18981: END
    public String spProdCategory = 'CR-ADJ-Other';
    //public String recordId = '0065x000027JWHaAAO';
    /**
     * START Method:
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'select id, SBQQ__AmendedContract__r.All_Subs_RMA__c, SBQQ__RenewedContract__r.All_Subs_RMA__c, StageName, Closed_Lost_Reason__c, Closed_Lost_Reason_Comment__c from Opportunity where (stageName != :closedWon AND stageName != :closedLost) AND (SBQQ__AmendedContract__r.All_Subs_RMA__c = true OR SBQQ__RenewedContract__r.All_Subs_RMA__c = true)';
        return Database.getQueryLocator(query);
    }
    /**
     * Execute Method:
     */
    global void execute(Database.BatchableContext BC, List<Opportunity> OpptyList){
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('CloseOpptyAllSubsciptionsRMA', 'executeMethod', LogModel.LOG_CATEGORY_APEX);
        List<Opportunity> lstOpptyUpdate = new List<Opportunity>();
        Map<ID, Opportunity> errors = new Map<ID, Opportunity>();
        Map<Id, Opportunity> mapOpp = new Map<id, Opportunity>();
        Set<Id> oppIds = new Set<Id>();
        List<OpportunityLineItem> lstOppLines = new List<OpportunityLineItem>();
        Map<id, List<OpportunityLineItem>> mapOppWithLines = new Map<id, List<OpportunityLineItem>>();
        List<OpportunityLineItem> lstOpLines;
        try{
            //Changes done as a part of SFDC-18242: START
            for(Opportunity opp : OpptyList){
                //oppIds.add(opp.id);
                mapOpp.put(opp.id, opp);
            }
            //System.debug('OpptyList size is:' +OpptyList.size());
            //System.debug('mapOpp is:' +mapOpp);
            if(!mapOpp.isEmpty()){
                /**
                 * Added as a part of SFDC-18981: START
                 * Added an extra condition to bypass Credit Opportunities with Sonian business group.
                 * */
                lstOppLines = [select id, Product_Category__c, OpportunityId, Opportunity.Business_Group__c from OpportunityLineItem where OpportunityId in :mapOpp.keySet() and (Opportunity.Business_Group__c = :mspBG OR Opportunity.Business_Group__c = :sonianBG) and Product_Category__c = :spProdCategory];
                //System.debug('lstOppLines size is:' +lstOppLines.size());
                ////Added as a part of SFDC-18981: END
                for(OpportunityLineItem oppLine : lstOppLines){
                    if(!mapOppWithLines.containsKey(oppLine.OpportunityId)){
                        lstOpLines = new List<OpportunityLineItem>();
                        lstOpLines.add(oppLine);
                        mapOppWithLines.put(oppLine.OpportunityId, lstOpLines);
                    }else{
                        lstOpLines = new List<OpportunityLineItem>();
                        lstOpLines = mapOppWithLines.get(oppLine.OpportunityId);
                        lstOpLines.add(oppLine);
                        mapOppWithLines.put(oppLine.OpportunityId, lstOpLines);
                    }
                }
                //System.debug('mapOppWithLines is:' +mapOppWithLines);
                //if(lstOppLines.isEmpty()){
                    for(Opportunity opp02: OpptyList){
                        //System.debug('Opp id exists?'+mapOppWithLines.containsKey(opp02.id));
                        if(!mapOppWithLines.containsKey(opp02.id)){
                            opp02.StageName = closedLost;
                            //Modified as a part of SFDC-18318: START
                            opp02.Closed_Lost_Reason__c = 'All Subs on Contract Returned';
                            //Modified as a part of SFDC-18318: END
                            opp02.Closed_Lost_Reason_Comment__c  = 'Contract RMAd';
                            lstOpptyUpdate.add(opp02);
                        }
                    }
                //}
            }
            //Changes done as a part of SFDC-18242: END
            //System.debug('lstOpptyUpdate size is:' +lstOpptyUpdate.size());
            //System.debug('lstOpptyUpdate is:' +lstOpptyUpdate);
            if(!lstOpptyUpdate.isEmpty()){
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.allowFieldTruncation = true;
                Database.SaveResult[] srList = Database.update(lstOpptyUpdate, false);
                for (Integer i = 0; i < srList.size(); i++) {
                    Opportunity opp2 = new Opportunity(ID = lstOpptyUpdate[i].Id);

                    Database.SaveResult sr = srList[i];
                    if (!sr.isSuccess()) {
                        String errorMsg = '';
                        for(Database.Error err : sr.getErrors()) {
                            errorMsg = errorMsg + err.getMessage() + '\n';
                        }
                        //System.Debug('*** Error ' + opp2.Id);
                        opp2.setOptions(dml);
                        errors.put(opp2.Id, opp2);
                    } else {
                        //System.Debug('*** success contract ' + opp2.Id);
                    }
                }
                if (errors.size() > 0)
                    //System.Debug('*** Error exists');
                    Database.update(errors.values(), false);
            }
        }Catch(Exception e){
            log.addExceptionLog(e);
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    }
    /**
     * Finish Method:
     */
    global void finish(Database.BatchableContext BC){}

}