public class OpportunityRelatedListController {  
    
    @AuraEnabled  
    public static List<Opportunity> fetchRecs(Id recordId) {  
        List<Opportunity> oppList = [Select Id, Name, StageName, Amount, CloseDate, 
                                     Owner.Name, RecordType.Name,
                                     Reseller__r.Name, Distributor__r.Name
                                     from Opportunity where
                                     AccountId in (Select AccountId from Case where Id =: recordId) and
                                     ((CloseDate >=Today and CloseDate<=NEXT_n_Months:12) OR 
                                     (CloseDate >= LAST_n_DAYS:180 and StageName ='Closed Won'))
                                     order by CreatedDate desc]; 
        return oppList;
    }      
  
}