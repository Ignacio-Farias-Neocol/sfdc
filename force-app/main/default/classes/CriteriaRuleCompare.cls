public class CriteriaRuleCompare implements Comparable {

     public criteria_rule__mdt criteria;
    
    // Constructor
    public CriteriaRuleCompare(criteria_rule__mdt crRule) {
    	// Guard against wrapping a null 
    	if(crRule != null)
        criteria = crRule;
    }
    
    // Compare opportunities based on the opportunity amount.
    public Integer compareTo(Object compareTo) {
        // Cast argument to OpportunityWrapper
        CriteriaRuleCompare compareToCrRule = (CriteriaRuleCompare)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if ((criteria.Order__c == null) && (compareToCrRule.criteria.Order__c == null)) {
            // both wrappers have null Amounts
            returnValue = 0;
        } else if ((criteria.Order__c == null) && (compareToCrRule.criteria.Order__c != null)){
            // nulls-first implementation
            returnValue = -1;
        } else if ((criteria.Order__c != null) && (compareToCrRule.criteria.Order__c == null)){
            // nulls-first implementation
            returnValue = 1;
        } else if (criteria.Order__c > compareToCrRule.criteria.Order__c) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (criteria.Order__c < compareToCrRule.criteria.Order__c) {
            // Set return value to a negative value.
            returnValue = -1;
        } 
        return returnValue;
    }
    
}