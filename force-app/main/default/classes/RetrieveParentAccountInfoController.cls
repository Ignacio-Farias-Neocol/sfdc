public with sharing class RetrieveParentAccountInfoController {
    @AuraEnabled(cacheable=true)
    public static Contact getParentAccount(Id contactId) {
        Contact contact = [SELECT Account.Name,Account.Technical_Alert__c,Account.Contact_Center_Alert__c,Contact_Alert__c FROM Contact WHERE Id = :contactId];
        return contact;
    }
}