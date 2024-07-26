/**
 * Created by Abi A on 12/20/18.
 */
public with sharing class DynamicValidationCaseCommentDisallow implements DynamicValidationRule {

    public Set<String> getExpectedFields() {
        return new Set<String> {
        }; // not used in bulk validation in trigger context
    }

    /*******************************************************************************************************
    * @description validate if a case is closed and current user is portal user, then do not allow user to create case comment    
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */
    public Map<SObject,Boolean> evaluateRule(List<SObject> records) {

        System.debug('~~~ validation Rule DynamicValidationCaseCommentDisallow with ' + records);

        String userType = UserInfo.getUserType();
        Map<Id, CaseComment> caseIds = new Map<Id, CaseComment>();

        for (SObject o : records) {
            CaseComment c = (CaseComment) o;
            if (c.ParentId != null) {
                caseIds.put(c.ParentId, c);
            }
        }

        Map<Id, Case> closedCases = new Map<Id, Case>([Select Id, Status from Case where Status = 'Closed' and Id in :caseIds.keySet()]);

        Map<SObject, Boolean> results = new Map<SObject, Boolean>();
        
        for (SObject o : records) {
            CaseComment c = (CaseComment) o;
            results.put(c, true); // set to valid by default
            if (!closedCases.isEmpty() && closedCases.get(c.ParentId) != null 
                && (userType == 'PowerCustomerSuccess' || userType == 'PowerPartner')
                ) {
                results.put(c, false); // this case comment is associated with a closed case
            }
        }
        return results;
    }
}