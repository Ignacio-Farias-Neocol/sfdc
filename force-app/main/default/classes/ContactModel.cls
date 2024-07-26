public without sharing class ContactModel {
    
    public static void afterUpdate(){
        Map<Id, Contact> oldConMap = (Map<Id, Contact>) Trigger.oldMap;
        Set<Id> contactIdSet = new Set<Id>();
        for(Contact con: (List<Contact>) Trigger.new){
            if(con.Security_Notice_Contact__c != oldConMap.get(con.Id).Security_Notice_Contact__c){
                contactIdSet.add(con.Id);
            }
        }
        
        if(!contactIdSet.isEmpty()) updateAccountSecurityCheckbox(contactIdSet);
    }
    
    public static void updateAccountSecurityCheckbox(Set<Id> contactIdSet){
        LogModel log = LogModel.startLog('ContactModel', 'updateAccountSecurityCheckbox');
        try {
            Set<Id> accountIdSet = new Set<Id>();
            for(AccountContactRelation acr: [Select AccountId from AccountContactRelation where ContactId =: contactIdSet]){
                accountIdSet.add(acr.AccountId);
            }
            Map<Id, List<AccountContactRelation>> acrMap = new Map<Id, List<AccountContactRelation>>();
            List<AccountContactRelation> acrList = [SELECT AccountId, ContactId,
                                                    Account.Security_Notice_Contact_Provided__c, 
                                                    Contact.Security_Notice_Contact__c
                                                    FROM AccountContactRelation 
                                                    where AccountId =: accountIdSet];
            for(AccountContactRelation acr: acrList){
                if(!acrMap.containsKey(acr.AccountId)){
                    acrMap.put(acr.AccountId, new List<AccountContactRelation>());
                }
                acrMap.get(acr.AccountId).add(acr);
            }
            
            List<Account> accountList = new List<Account>();
            for(Id accountId: acrMap.keySet()){
                Boolean isSecurityContact = false;            
                for(AccountContactRelation acr: acrMap.get(accountId)){
                    if(acr.Contact.Security_Notice_Contact__c){
                        isSecurityContact = true;
                        break;
                    }
                }
                
                if(isSecurityContact != acrMap.get(accountId)[0].Account.Security_Notice_Contact_Provided__c){
                    Account acc = new Account();
                    acc.Id = accountId;
                    acc.Security_Notice_Contact_Provided__c = isSecurityContact;
                    accountList.add(acc);
                }              
                          
            }   
            if(!accountList.isEmpty()) update accountList;          
        } catch (Exception e) {
            log.addExceptionLog(e);
        }        
    }
}