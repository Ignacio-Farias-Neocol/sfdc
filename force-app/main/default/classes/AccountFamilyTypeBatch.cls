public without sharing class AccountFamilyTypeBatch implements Database.Batchable<sObject>{

    // Use an aggregate query to find ParentIds
    // Note: returning a query with the individual child Account records could potentially
    //       split the family across two batches and produce inaccurate results
    public String query = 'SELECT ParentId FROM Account WHERE ParentId != NULL AND Parent.RecordType.DeveloperName = \'Not_Transactional\' AND Type IN :interestingTypes GROUP BY ParentId';

    public Set<String> interestingTypes = new Set<String>{ 'Partner - MSP', 'Partner - Reseller' };
    public Map<String, Object> bindMap = new Map<String, Object> {
        'interestingTypes' => interestingTypes
    };

    public Boolean doContactUpdate = true;

    public Iterable<AggregateResult> start(Database.BatchableContext bc) {
        return new AggregateResultIterable(this.query, this.bindMap, AccessLevel.SYSTEM_MODE);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        Set<Id> parentIdSet = new Set<Id>();
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        List<Database.SaveResult> saveResultList;

        for(AggregateResult aggregateResult : (List<AggregateResult>) scope) {
            parentIdSet.add((Id)aggregateResult.get('ParentId'));
        }

        for(Account parentAccount : [SELECT Id, (SELECT Id, Type, Family_Types__c FROM ChildAccounts) FROM Account WHERE Id IN :parentIdSet]) {
            String typeString = getTypeString(parentAccount.ChildAccounts);

            if(String.isBlank(typeString)) {
                System.debug('!!Blank Type!! ' + parentAccount);
                continue;
            }

            for(Account childAccount : parentAccount.ChildAccounts) {
                childAccount.Family_Types__c = typeString;
                accountsToUpdate.put(childAccount.Id, childAccount);
            }
        }

        if(accountsToUpdate.values().size() > 0) {
            Database.SaveResult[] accountResultList = Database.update(accountsToUpdate.values(), false);
            saveResultList = accountResultList;

            if(doContactUpdate) {
                Database.SaveResult[] contactResultList = Database.update([SELECT Id FROM Contact WHERE AccountId IN :accountsToUpdate.keySet()], false);
                saveResultList.addAll(contactResultList);
            }
        }

        for(Database.SaveResult saveResult : saveResultList) {
            if(!saveResult.isSuccess()) {
                System.debug(System.LoggingLevel.WARN, saveResult);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    @testVisible
    private Set<String> collectTypes(List<Account> siblingAccounts) { 
        Set<String> typeSet = new Set<String>();

        for(Account accountRecord : siblingAccounts) {
            if(this.interestingTypes.contains(accountRecord.Type)) {
                typeSet.add(accountRecord.Type);
            }
        }

        return typeSet;
    }

    @testVisible
    private String getTypeString(List<Account> siblingAccounts) {
        List<String> typeString = new List<String>(collectTypes(siblingAccounts));
        typeString.sort();
        return String.join(typeString, ' ; ');
    }

    public class AggregateResultIterator implements Iterator<AggregateResult> {
        AggregateResult[] results {get;set;}
        // tracks which result item is returned
        Integer index {get; set;}

        public AggregateResultIterator(String query) {
          index = 0;
          results = Database.query(query);
        }

        public AggregateResultIterator(String query, Map<String, Object> bindMap, System.AccessLevel AccessLevel) {
          index = 0;
          results = Database.queryWithBinds(query, bindMap, accessLevel);
        }

        public boolean hasNext(){
          return results != null && !results.isEmpty() && index < results.size();
        }

        public AggregateResult next(){
          return results[index++];
        }
    }

    public class AggregateResultIterable implements Iterable<AggregateResult> {
        private String query;
        private Map<String, Object> bindMap;
        private System.AccessLevel accessLevel;
      
        public AggregateResultIterable(String soql, Map<String, Object> bindMap, System.AccessLevel AccessLevel){
          this.query = soql;
          this.bindMap = bindMap;
          this.accessLevel = accessLevel;
        }      

        public Iterator<AggregateResult> iterator(){
          if(bindMap == NULL) {
            return new AggregateResultIterator(query);
          } else {
            return new AggregateResultIterator(query, bindMap, accessLevel);
          }
        }
    }
}