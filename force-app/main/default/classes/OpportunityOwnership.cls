/**
* @author Salesforce Services
* @date 10/29/2020
*
* @group Rule Engine
*
* @description: Rule engine used to determine the Opportunity ownership based on Territory
*/
public with sharing class OpportunityOwnership {

    //Invocable method to determine and set the opportunity owner
    @InvocableMethod(label='Set Opportunity Owner' description='Sets owner based on rule engine')
    public static void setOpportunityOwner(List<Opportunity> opportunities) {
        //Log instance to capture logs
        LogModel log = LogModel.startLog('OpportunityOwnership', 'setOpportunityOwner');
        try{
            invokeOppOwnershipEngine(opportunities, null, log);
            log.endLog('End: OpportunityOwnership');
        }
        catch(Exception e){
            log.addExceptionLog(e);
        }
    }

    public static void invokeOppOwnershipEngine(List<Opportunity> opportunities, List<Opportunity_Ownership_Rule__c> rules, LogModel logInstance) {
	
        //Create an instance of the Opportunity Ownership Rule Engine
        OpportunityOwnershipRuleEngine oppRuleEngineInstance = new OpportunityOwnershipRuleEngine();
		
        //Assign owners
        List<Opportunity> oppsToBeUpdated = oppRuleEngineInstance.assignOwners(opportunities,rules);
        
        //Update Opportunity
        if(oppsToBeUpdated!=null && !oppsToBeUpdated.isEmpty()){
            List<Id> updatedOpptyIdList = updateOpportunity(oppsToBeUpdated, logInstance);

            if(updatedOpptyIdList!=null && !updatedOpptyIdList.isEmpty()){
                updateOpportunityQuoteOwner(updatedOpptyIdList, logInstance);
            }
        }
    }


    //Update owner on the list of opportunities passed as parameter
    public static List<Id> updateOpportunity(List<Opportunity> oppsToBeUpdated, LogModel logInstance){
        logInstance.addLog('Oppty ' + oppsToBeUpdated.size());
        Database.SaveResult[] srList = Database.update(oppsToBeUpdated, false);

        //List of Opportunity Ids successfully updated
        List<Id> updatedOppList = new List<Id>();
        //Index to access opportunity row in the OppsToBeUpdated list
        Integer oppIndex = 0;

        for(Database.SaveResult sr: srList){
            if(!sr.isSuccess()){
                //Operation failed
                for(Database.Error err : sr.getErrors()) {
                    logInstance.addErrorLog('Opp failed' + err.getMessage());
                }
            }
            else{
                logInstance.addLog(sr.getId());
                //Prepare a map of Opportunity and its owner.
                //Will use this map to update Quote owner and sales rep
                updatedOppList.add(sr.getId());                       
            }
            oppIndex++;
        } //END FOR

        return updatedOppList;
    }

    //Update owner on the list of opportunities passed as parameter
    public static void updateOpportunityQuoteOwner(List<Id> oppsUpdatedIdList, LogModel logInstance){
        logInstance.addLog('Quote owner update for Oppties ' + oppsUpdatedIdList.size());
        //For the updated opps update related quotes
        //Get Quotes tied to Opportunity. Prepare the list of quotes to be updated
        List<SBQQ__Quote__c> quotesToBeUpdated = new List<SBQQ__Quote__c>();
        for(Opportunity opp : [SELECT Id, 
                                        OwnerId, 
                                        (SELECT Id, 
                                                OwnerId, 
                                                SBQQ__SalesRep__c 
                                        FROM SBQQ__Quotes2__r) 
                                FROM Opportunity 
                                WHERE Id in :oppsUpdatedIdList]){
            //Set the quote owner and sales rep for related quotes
            for(SBQQ__Quote__c q: opp.SBQQ__Quotes2__r){
                if(q.OwnerId!=opp.OwnerId || q.SBQQ__SalesRep__c!=opp.OwnerId){
                    q.OwnerId = opp.OwnerId;
                    q.SBQQ__SalesRep__c = opp.OwnerId;
                    quotesToBeUpdated.add(q);
                }
            } //END FOR - QUOTE
        } //END FOR - OPPORTUNITY

        //If there are quotes to be updated then update quotes
        if(quotesToBeUpdated!=null && !quotesToBeUpdated.isEmpty()){
            Database.SaveResult[] qsrList = Database.update(quotesToBeUpdated);

            for(Database.SaveResult qsr: qsrList){
                if(!qsr.success){
                    //Operation failed
                    for(Database.Error err : qsr.getErrors()) {
                        logInstance.addErrorLog('Quote failed: ' + err.getMessage());
                    }
                }
            }
        }
    }    
}