public class ManageSubcriptionsController {
    @AuraEnabled
    public static List<String> getAnnoReasons(){
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = SBQQ__Subscription__c.AnnotationReason__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            options.add(p.getLabel());
        }
        system.debug('options'+options);
        return options;
    }
    @auraEnabled
    public static list<SBQQ__Subscription__c> getSubscriptions(String quoteId){
        system.debug('in getSubscriptions');
        list<SBQQ__Subscription__c> subscriptions = new list<SBQQ__Subscription__c>();
        if(quoteId != null){
            String oppId = [SELECT Id,SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE Id = :quoteId].SBQQ__Opportunity2__c;
            List<Contract> contracts = [SELECT Id FROM Contract WHERE SBQQ__RenewalOpportunity__c = :oppId];
            subscriptions = [SELECT Id, Name,  AnnotationReason__c,SBCF_Serial_Number__c,Product_Code__c, SBQQ__EndDate__c, SBQQ__QuoteLine__c FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c IN : contracts];
            system.debug('subscriptions'+subscriptions);
        }
        return subscriptions;
    }
    
    @auraEnabled
    public static String updateSubscriptions(list<SBQQ__Subscription__c> upSubscriptions){
        system.debug('upSubscriptions'+upSubscriptions);
        try{
            Update upSubscriptions;
          
            Set<Id> subIds = new Set<Id>();
            for(SBQQ__Subscription__c sub :upSubscriptions){
                if(sub.AnnotationReason__c != null && string.isNotBlank(sub.AnnotationReason__c)){
                        subIds.add(sub.id);
                }
            }
            System.debug('Subscriptions' +subIds);
            if(!subIds.isEmpty()){
               List<SBQQ__QuoteLine__c> quoteLines = [SELECT ID FROM SBQQ__QuoteLine__c WHERE SBQQ__RenewedSubscription__c IN :subIds ];                 
                Delete quoteLines;
            }
        } catch(exception ex){
            return ex.getMessage();
        }
        
        return null;   
    }
}