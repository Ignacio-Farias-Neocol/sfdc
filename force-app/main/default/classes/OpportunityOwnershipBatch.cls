/**
* @author Salesforce Services
* @date 10/31/2020
*
* @group Batch Job
*
* @description: Batch job to assign owners to Opportunity based on territories
*/
public class OpportunityOwnershipBatch implements Database.Batchable<sObject> {
    private List<Opportunity_Ownership_Rule__c> rulesToBeEvaluated;
    private Set<Id> territoryIdSet = new Set<Id>();
    private String queryString = '';

    public OpportunityOwnershipBatch(List<String> rulesIdList) {
        //Create log instance
        LogModel log = LogModel.startLog('OpportunityOwnershipBatch', 'Constructor');
        //Prepare rule Querystring
        String ruleQueryString = 'SELECT Advanced_Condition__c,Conditions_Met__c,Opportunity_Owner__c,TerritoryID__c,' + 
                                 '(SELECT Field_API_Name__c,Index__c,Operator__c,Value__c FROM Opportunity_Ownership_Condition__r)' +
                                 ' FROM Opportunity_Ownership_Rule__c' +
                                 ' WHERE Active__c = true';
        
        //Get the rules to be evaluated
        if(rulesIdList!=null && !rulesIdList.isEmpty()){
            ruleQueryString += ' AND Id in :rulesIdList';
        }
        log.addLog('***RULE QUERY***' + ruleQueryString);
        system.debug('***RULE QUERY***' + ruleQueryString);
        //Get rules
        this.rulesToBeEvaluated = Database.query(ruleQueryString);

        //Loop through rules to get territory Ids. We will use these Ids to filter opportunities
        for(Opportunity_Ownership_Rule__c rule: rulesToBeEvaluated){
            if(territoryIdSet!=null && !territoryIdSet.contains(rule.Id)){
                territoryIdSet.add(rule.TerritoryID__c);
            }
        }
        log.addLog('Territory: ' + territoryIdSet);
        //Build where clause for the queryString
        String whereClause =  'Business_Group__c = \'Core\'' + 
                              ' AND RecordType.DeveloperName = \'Renewal\'' + 
                              ' AND LeadSource = \'Renewal\'' + 
                              ' AND IsClosed = false' + 
                              ' AND CloseDate = NEXT_N_DAYS:120' +
                              ' AND (Owner.Profile.Name = \'Apollo: Custom- Renewals Profile\' OR Owner.Username LIKE \'admin.salesforce@barracuda.com.apolloprod%\' OR  Owner.Username LIKE \'renewals_team@barracuda.com.prod%\')';

        if(territoryIdSet!=null && !territoryIdSet.isEmpty()){
            whereClause += ' AND Territory2Id IN :territoryIdSet';
        }      

        //Build the queryString
        queryString = OpportunityOwnershipRuleEngine.dynamicQueryBuilder('Opportunity', 
                                                                         null, 
                                                                         whereClause);
        log.addLog('***QUERY***' + queryString);
        system.debug('***QUERY***' + queryString);
        log.endLog('End of constructor');
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        //System.debug('Q:'+OpportunityAssignmentToRenewals.dynamicQueryBuilder('Opportunity','Territory2.Name','Business_Group__c = \'Core\' AND RecordType.Name = \'Renewal\' AND LeadSource = \'Renewal\''));
        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> oppsToBeEvaluated){
        //Create log instance
        LogModel log = LogModel.startLog('OpportunityOwnershipBatch', 'Update Opportunity Owner');
        log.addLog('# of opportunities' + oppsToBeEvaluated.size());
        try{
            OpportunityOwnership.invokeOppOwnershipEngine(oppsToBeEvaluated, rulesToBeEvaluated, log);
            log.endLog('Execute Method ended');
        }
        catch(Exception e){
            log.addExceptionLog(e);
        }

    }

    public void finish(Database.BatchableContext bc){
        //Create log instance
        LogModel log = LogModel.startLog('OpportunityOwnershipBatch', 'Finish Method');

        try{
            //Send email on batch job completion
            // Get the ID of the AsyncApexJob representing this batch job
            // from Database.BatchableContext.
            // Query the AsyncApexJob object to retrieve the current job's information.
            AsyncApexJob a = [SELECT Id, 
                                    Status, 
                                    NumberOfErrors, 
                                    JobItemsProcessed,
                                    TotalJobItems, 
                                    CreatedBy.Email
                            FROM AsyncApexJob 
                            WHERE Id = :BC.getJobId()];

            // Send an email to the Apex job's submitter notifying of job completion.
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Renewal opportunity ownership assignment' + a.Status);
            mail.setPlainTextBody
            ('Territory based renewal opportunity ownership assigned is complete.' + 
            a.TotalJobItems +
            ' batches with '+ a.NumberOfErrors + ' failures.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            log.addLog('Territory based renewal opportunity ownership assigned is complete.' + 
                        a.TotalJobItems +
                        ' batches with '+ a.NumberOfErrors + ' failures.');
            log.endLog('Batch Job ended');
        }
        catch(Exception e){
            log.addExceptionLog(e);
        }

    }
}