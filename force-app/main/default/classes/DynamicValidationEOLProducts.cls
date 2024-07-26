/**
 * Created by: Salesforce Services
 * Date: 03/16/2021
 * 
 * Description: Dynamic validation rule to prevent users from closing an opportunity containing EOL products
 */
public with sharing class DynamicValidationEOLProducts implements DynamicValidationRule{
  public Set<String> getExpectedFields() {  
    return new Set<String> {}; // not used in bulk validation in trigger context
  } 

  /* Evaluation of rule
   * Logic for evaluation: 
   * 1. For each opportunity get opportunity products that are tied to a product with EOL status
   * 2. If an opportunity has 1 or more such products then throw an error
   * */
  public Map<SObject,Boolean> evaluateRule(List<SObject> records) {

    //Map of eligible opportunities
    Map<Id, Opportunity> eligibleOppMap = new Map<Id, Opportunity>();

    //Result to be sent
    Map<SObject, Boolean> results = new Map<SObject, Boolean>();

    //Get list of Opportunity Id
    for (SObject o : records) {
      Opportunity opp = (Opportunity) o;
      if (opp.StageName == 'Closed Won' && opp.Business_Group__c == 'Core') {
        eligibleOppMap.put(opp.Id, opp);
      }
    } //END OF OPP LOOP

    if(eligibleOppMap!=null && !eligibleOppMap.isEmpty()){
      //Run an aggregate query to get EOL products in an opportunity
      AggregateResult[] opportunityProductResults = [SELECT OpportunityId, Count(Id) 
                                                     FROM OpportunityLineItem 
                                                     WHERE OpportunityId in :eligibleOppMap.keyset() 
                                                     AND Product2.End_of_Life__c = true 
                                                     GROUP BY OpportunityId];
      for (AggregateResult ar : opportunityProductResults)  {
        if((Integer)ar.get('expr0')>0){
          // return false for the oppty record
          results.put(eligibleOppMap.get((Id)ar.get('OpportunityId')), false);
        }
      } //END OF AGGREGATE RESULT
    }

    return results;
  }
}