/**
 * Created by: Salesforce Services
 * Date: 03/17/2021
 * 
 * Description: Dynamic validation rule to prevent users from Renewing a contract
 */
public with sharing class DynamicValidationContractEOLProducts implements DynamicValidationRule{
  public Set<String> getExpectedFields() {  
    return new Set<String> {}; // not used in bulk validation in trigger context
  } 
    
  /* Evaluation of rule
    * Logic for evaluation: 
    * 1. For each contract get its subs and assets
    * 2. Check if all Subs are EOL and all Assets are EOL
    * 3. If all subs and assets are EOL then prevent renewal
    * */
  public Map<SObject,Boolean> evaluateRule(List<SObject> records) {

    //Map of Contracts eligible for validation check
    Map<Id, Contract> eligibleContractMap = new Map<Id, Contract>();

    //Result to be sent
    Map<SObject, Boolean> results = new Map<SObject, Boolean>();

    //Get list of Contract Id
    for (SObject o : records) {
      Contract con = (Contract) o;
      if ((con.SBQQ__RenewalForecast__c || con.SBQQ__RenewalQuoted__c) && con.Business_Group__c == 'Core') {
        eligibleContractMap.put(con.Id, con);
      }
    } //END OF OPP LOOP

    if(eligibleContractMap!=null && !eligibleContractMap.isEmpty()){
      //Run an aggregate query to get Subs for contracts
      for(Contract currentContract: [SELECT Id,
                                            (SELECT SBQQ__RequiredByProduct__r.End_of_Life__c 
                                             FROM SBQQ__Subscriptions__r),
                                            (SELECT Product2.End_of_Life__c 
                                             FROM Assets__r) 
                                     FROM Contract 
                                     WHERE Id in :eligibleContractMap.keyset()]){

        //Define boolean values
        Boolean allSubsEOL   = true; //All subs are EOL
        Boolean noSubs      = false; //No subs available in a contract
        Boolean allAssetsEOL = true; //All assets are EOL
        Boolean noAssets    = false; //No assets available in a contract
        
        //Check Subs
        if(currentContract.SBQQ__Subscriptions__r == null || currentContract.SBQQ__Subscriptions__r.isEmpty()){
          noSubs = true;
        }
        else{
          for(SBQQ__Subscription__c sub: currentContract.SBQQ__Subscriptions__r){
            if(!sub.SBQQ__RequiredByProduct__r.End_of_Life__c){
              allSubsEOL = false;
              break;
            }
          }
        }

        //Check Assets
        if(currentContract.Assets__r == null || currentContract.Assets__r.isEmpty()){
          noAssets = true;
        }
        else{
          for(Asset currentAsset: currentContract.Assets__r){
            if(!currentAsset.Product2.End_of_Life__c){
                allAssetsEOL = false;
                break;
            }
          }
        }        

        //Determine if contract renewal needs to be stopped
        /**
         * Prevent renewal if one of the following conditions are true
         * 1. All Subs in a contract are EOL and there are no Assets in a contract
         * 2. All Subs and all assets in a contract are EOL
         * 3. All assets in a contract are EOL and there are no subs
         */
        if((allSubsEOL && noAssets) || 
           (allSubsEOL && allAssetsEOL) || 
           (noSubs && allAssetsEOL)){
          results.put(eligibleContractMap.get(currentContract.Id), false);
        }
      } //END OF ELIGIBLE CONTRACT LOOP
    }

    return results;
  }
}