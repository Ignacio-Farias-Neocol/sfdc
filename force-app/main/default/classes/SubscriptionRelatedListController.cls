// Test Class - DynamicBusinessRuleFeedCommentTest
public class SubscriptionRelatedListController {  
    
    @AuraEnabled  
    public static List<SBQQ__Subscription__c> fetchRecs(Id recordId) {  
        List<SBQQ__Subscription__c> subscriptionList = [Select Id, Name, SBQQ__Account__c, SBQQ__ProductName__c, 
                                                        SBCF_Serial_Number__c, SBQQ__SubscriptionEndDate__c 
                                                        from SBQQ__Subscription__c where SBQQ__Account__c in 
                                                        (Select AccountId from Case where Id =: recordId) and
                                                        (SBQQ__SubscriptionEndDate__c >= LAST_n_DAYS:180 or
                                                        Active__c = true)
                                                        order by CreatedDate desc];        
        return subscriptionList;
    } 
    @AuraEnabled 
    public static List<SBQQ__Subscription__c> fetchActiveRecs( String serialNumber, String accountId) {  
        List<SBQQ__Subscription__c> subscriptionList = new  List<SBQQ__Subscription__c>();

        for(SBQQ__Subscription__c sub : [Select Id, Name, SBQQ__Account__c, SBQQ__ProductName__c, 
                                        SBCF_Serial_Number__c, SBQQ__SubscriptionEndDate__c 
                                        from SBQQ__Subscription__c where SBQQ__Account__c=:accountId AND Active__c = true
                                        order by CreatedDate desc]){
                    if(serialNumber!= null && sub.SBCF_Serial_Number__c == serialNumber)
                        subscriptionList.add(sub);
            }        
            return subscriptionList;
    }   
}