public with sharing class OpportunityService {
  
    public static List<Opportunity> getOpportunitysByAccount(string accountId){
        
        return new OpportunitySelector.OppSelectorWithoutSharing().getOpportunitysByAccount(accountId);
    }

}