global class UpdateACVforContract implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date today = Date.today();
        return Database.getQueryLocator([
            SELECT Id, SBQQ__Opportunity__c, SBQQ__Opportunity__r.SBCF_Annual_Contract_Value__c,Annual_Contract_Value__c 
            FROM Contract
            WHERE Annual_Contract_Value__c =null 
            and SBQQ__Opportunity__c != null 
            and Business_Group__c = 'Core'
            and SBQQ__RenewalOpportunity__r.StageName != 'Closed Won'
            and SBQQ__RenewalOpportunity__r.StageName != 'Closed Lost' 
            and SBQQ__Opportunity__r.SBQQ__AmendedContract__c = null
         ]);
    }

    global void execute(Database.BatchableContext BC, List<Contract> scope) {
        Map<Id, Decimal> contractAnnualValueMap = new Map<Id, Decimal>();
       
        // Step 2: Storing the Value of annual contract value against contracts
        for (Contract con : scope) {
            contractAnnualValueMap.put(con.Id, con.SBQQ__Opportunity__r.SBCF_Annual_Contract_Value__c);
        }
       
        // Step 3 & 4: Finding out amendment opportunities against the Contract
        List<Opportunity> amendmentOpportunities = [
            SELECT Id, SBCF_Annual_Contract_Value__c, SBQQ__AmendedContract__c
            FROM Opportunity
            WHERE SBQQ__AmendedContract__c IN :contractAnnualValueMap.keySet() and StageName = 'Closed Won'
        ];
       
        // Step 5: Summing the values from step 2 and step 3 for the same contract
        for (Opportunity opp : amendmentOpportunities) {
            Id contractId = opp.SBQQ__AmendedContract__c;
            Decimal annualContractValue = contractAnnualValueMap.get(contractId) != null ? contractAnnualValueMap.get(contractId) : 0;
            annualContractValue += opp.SBCF_Annual_Contract_Value__c;
            contractAnnualValueMap.put(contractId, annualContractValue);
        }
       
        // Step 6: Updating the Annual_Contract_Value__c on the corresponding contract
        List<Contract> contractsToUpdate = new List<Contract>();
        for (Id conId : contractAnnualValueMap.keySet()) {
            contractsToUpdate.add(new Contract(
                Id = conId,
                Annual_Contract_Value__c = contractAnnualValueMap.get(conId)
            ));
        }
        update contractsToUpdate;
    }

    global void finish(Database.BatchableContext BC) {
        
    }
}