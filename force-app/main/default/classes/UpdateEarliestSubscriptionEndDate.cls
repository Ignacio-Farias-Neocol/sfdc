global class UpdateEarliestSubscriptionEndDate implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, SBQQ__RenewedContract__c, Business_Group__c   
            FROM Opportunity 
            WHERE SBQQ__RenewedContract__c != null
            AND Earliest_Subscription_End_Date__c= null
            AND StageName != 'Closed Lost'
            AND StageName != 'Closed Won'
            AND Business_Group__c = 'Core'
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> records) {
        Set<Id> contractIds = new Set<Id>();

        for (Opportunity opp : records) {
            if (opp.SBQQ__RenewedContract__c != null && opp.Business_Group__c == 'Core') {
                contractIds.add(opp.SBQQ__RenewedContract__c);
                system.Debug('Renew--> '+opp.SBQQ__RenewedContract__c);
            } 
        }
          
        if (!contractIds.isEmpty()) {
            Map<Id, Date> contractToMinEndDate = new Map<Id, Date>();

            List<AggregateResult> results = [
                SELECT SBQQ__Contract__c, MIN(SBQQ__SubscriptionEndDate__c) minEndDate
                FROM SBQQ__Subscription__c
                WHERE SBQQ__Contract__c IN :contractIds 
                    AND SBQQ__RenewalQuantity__c >= 1
                GROUP BY SBQQ__Contract__c
            ];

            for (AggregateResult result : results) {
                system.Debug('Con===> '+result.get('SBQQ__Contract__c'));
                system.Debug('EndDate===> '+result.get('minEndDate'));
                Id contractId = (Id)result.get('SBQQ__Contract__c');
                Date minEndDate = (Date)result.get('minEndDate');
                contractToMinEndDate.put(contractId, minEndDate);
            }

            for (Opportunity opp : records) {
                Id contractId = opp.SBQQ__RenewedContract__c;
                system.Debug('ContractID===> '+contractToMinEndDate.get(contractId));
                if (contractToMinEndDate.containsKey(contractId)) {
                    opp.Earliest_Subscription_End_Date__c = contractToMinEndDate.get(contractId);
                }
                
               
            }
            try {
                Database.update(records);
            } catch (Exception e) {
                System.debug('Error updating Opportunities: ' + e.getMessage());
            }
            
        }
        
    }

    global void finish(Database.BatchableContext bc) {

    }
}