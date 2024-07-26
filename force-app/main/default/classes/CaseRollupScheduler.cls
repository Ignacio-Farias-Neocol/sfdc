public class CaseRollupScheduler implements Schedulable {

    public CaseRollupScheduler(){}
    public static List<Id> caseIds;
    public void execute(SchedulableContext ctx) {
        try{
        Case_Rollup__mdt caseRollup = 
            [
                SELECT 
                    Id,
                    Hour__c
                FROM Case_Rollup__mdt
                LIMIT 1
            ];
        
        List<AggregateResult> caseRollupList;
        List<AggregateResult> caseTotalRollupList;
        List<Account> accList;
        DateTime dt = System.Now().addHours(-Integer.valueOf(caseRollup.Hour__c));

        if(CaseRollupScheduler.caseIds != null && !caseIds.isEmpty()){
            List<Case> caseList = 
                [
                    SELECT 
                        Id,
                        AccountId
                    FROM Case
                    WHERE Id IN: CaseRollupScheduler.caseIds AND AccountId != null
                    AND (RecordType.DeveloperName = 'Community_Help' OR RecordType.DeveloperName = 'Technical_Support')
                ];
            List<String> accIds = new List<String>();
            for(Case caseObj : caseList){
                accIds.add(caseObj.AccountId);
            }
            caseRollupList =
                [
                    SELECT 
                        count(Id) total,
                        AccountId accId
                    FROM Case
                    Where AccountId != null
                    AND CreatedDate >=: dt
                    AND AccountId IN: accIds
                    AND (RecordType.DeveloperName = 'Community_Help' OR RecordType.DeveloperName = 'Technical_Support')
                    GROUP BY AccountId
                ];
            accList = 
                [
                    SELECT 
                        Id,
                        New_Cases_Last_72_Hours__c,
                        Total_Cases__c
                    FROM Account
                    WHERE Id IN :accIds for Update
                ];

            caseTotalRollupList =
                [
                    SELECT 
                        count(Id) total,
                        AccountId accId
                    FROM Case
                    Where AccountId != null
                    AND AccountId IN: accIds
                    AND (RecordType.DeveloperName = 'Community_Help' OR RecordType.DeveloperName = 'Technical_Support')
                    GROUP BY AccountId
                ];
        }else{
            caseRollupList =
                [
                    SELECT 
                        count(Id) total,
                        AccountId accId
                    FROM Case
                    Where AccountId != null AND CreatedDate >=: dt
                    AND (RecordType.DeveloperName = 'Community_Help' OR RecordType.DeveloperName = 'Technical_Support')
                    GROUP BY AccountId
                ];
            accList = 
                [
                    SELECT 
                        Id,
                        New_Cases_Last_72_Hours__c,
                        Total_Cases__c
                    FROM Account 
                    WHERE Id IN 
                        (SELECT AccountId FROM Case 
                            WHERE AccountId != null AND CreatedDate >=: dt AND (RecordType.DeveloperName = 'Community_Help' OR RecordType.DeveloperName = 'Technical_Support')) 
                    for Update
                ];

            caseTotalRollupList =
                [
                    SELECT 
                        count(Id) total,
                        AccountId accId
                    FROM Case
                    Where AccountId != null
                    AND AccountId IN: accList
                    AND (RecordType.DeveloperName = 'Community_Help' OR RecordType.DeveloperName = 'Technical_Support')
                    GROUP BY AccountId
                ];
        }

        Map<String, Integer> accIdTotalCasesMap = new Map<String, Integer>();
        for(AggregateResult caseTotalRollupObj : caseTotalRollupList){
            String accId = (String)caseTotalRollupObj.get('accId');
            accIdTotalCasesMap.put(accId, (Integer) caseTotalRollupObj.get('total'));
        }
       
        for(Account accObj : accList){
            for(AggregateResult caseRollupObj : caseRollupList){
                if(accObj.Id == (String)caseRollupObj.get('accId')){
                    accObj.New_Cases_Last_72_Hours__c = (Decimal) caseRollupObj.get('total');
                    if(accIdTotalCasesMap.containsKey(accObj.Id)){
                        accObj.Total_Cases__c = (Decimal) accIdTotalCasesMap.get(accObj.Id);
                    }                    
                }
            }
        }
        
        if(!accList.isEmpty()){
            update accList;
        }
    }catch(exception e) {
        System.debug('Error------------------>' + e);
    }
    }
    @future
    public static void performCaseRollup(List<Id> caseIds) {
        System.debug('caseIds------------------>' + caseIds);
        CaseRollupScheduler.caseIds = caseIds;
        new CaseRollupScheduler().execute(null);
    }

    @InvocableMethod(label='Case Rollup' description='Case Rollup' category='Account')
    public static List<ID> performCaseRollupInvocable(List<ID> ids) {
        System.debug('ids------------------>' + ids);
        CaseRollupScheduler.performCaseRollup(ids);
        return ids;
    }
}