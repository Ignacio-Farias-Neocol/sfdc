// Test Class - DynamicBusinessRuleFeedCommentTest
public class HotlistRelatedListController {  
    
    @AuraEnabled  
    public static List<Hot_List__c> fetchRecs(Id recordId) {  
        List<Hot_List__c> hlList = [Select Id, Name, CreatedDate, Hot_List_Name__c, MQL_Reason__c,
                                    Disposition__c, Primary_Product_Family_2__c, 
                                    Reseller__r.Name, Owner_Name__c, Reseller__c
                                    from Hot_List__c where
                                    Account__c in (Select AccountId from Case where Id =: recordId)
                                    order by CreatedDate desc]; 
        return hlList;
    }      
  
}