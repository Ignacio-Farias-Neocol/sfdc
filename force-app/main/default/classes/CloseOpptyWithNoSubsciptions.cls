/**
 * Created by Rajesh Wani on 10/05/2023.
 *  @Date 10/05/2023
 *
 *  Description:
 *  Auto close renewal Opportunities with empty contracts
 *  
 *  Added as a part of SFDC-19052
 */
global class CloseOpptyWithNoSubsciptions implements Database.Batchable<SObject>{
    
 
    public String closedLost = 'Closed Lost';
    public String mspBG = 'Core';
    public String closedWon = 'Closed Won';
    public String sonianBG = 'Sonian';
   
    /**
     * START Method:
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT id,AccountId, Owner.name,Legacy_Data__c,SBQQ__RenewalOpportunity__c FROM Contract WHERE All_Subs_RMA__c=false AND SBQQ__RenewalOpportunity__r.isclosed=false AND SBQQ__RenewalOpportunity__c!=null AND Business_Group__c=:mspBG AND EndDate >today and id not in (select SBQQ__Contract__c from SBQQ__Subscription__c )';
        return Database.getQueryLocator(query);
    }
    /**
     * Execute Method:
     */
    global void execute(Database.BatchableContext BC, List<Contract> ContractList){
        //Instantiate the log class to capture logs for error conditions
        LogModel log = LogModel.startLog('CloseOpptyWithNoSubsciptions', 'executeMethod', LogModel.LOG_CATEGORY_APEX);
        List<Opportunity> lstOpptyUpdate = new List<Opportunity>();
        Map<ID, Opportunity> errors = new Map<ID, Opportunity>();
        Map<Id, Opportunity> mapOpp = new Map<id, Opportunity>();
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> lstErrorOpptyUpdate = new List<Opportunity>();
        List<Opportunity> lstSuccessOpptyUpdate = new List<Opportunity>();
      
        try{
           
            for(Contract cont : ContractList){
                Opportunity oppty = new Opportunity(id=cont.SBQQ__RenewalOpportunity__c);
                oppty.StageName = closedLost;
                oppty.Closed_Lost_Reason__c = 'All Subs on Contract Reparented';
                oppty.Closed_Lost_Reason_Comment__c  = 'Empty contract now that Subs have all been reparented.';
                lstOpptyUpdate.add(oppty);
            }
         system.debug('lstOpptyUpdate============'+lstOpptyUpdate);
            
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
                        System.Debug('*** Error ' + opp2.Id);
                        opp2.setOptions(dml);
                        errors.put(opp2.Id, opp2);
                    } else {
                        System.Debug('*** success contract ' + opp2.Id);
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