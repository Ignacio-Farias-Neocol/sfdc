/**
* @author Salesforce Services
* @date 2020-11-24
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description SFDC-13091: Implementation of DynamicBusinessRuleAction interface to update contracts based on Accounts
*/
public with sharing class DynamicBusinessRuleAutoRenewal implements DynamicBusinessRuleAction {
   //Log Variable
   private LogModel log = LogModel.startLog('DynamicBusinessRuleAutoRenewal', 'processRecords');

  /******************************************************************************************************
  * Implementation of ProcessRecords method for executing logic using Business Action Rule
  *******************************************************************************************************/
  public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {

    //Call method to update contracts when auto renewal on Account is turned off or on
    this.getAccountForContractUpdates(newRecordMap, 
                                      oldRecordMap, 
                                      records, 
                                      jsonParameter, 
                                      triggerOrder, 
                                      triggerContext);
    log.endLog('End: processRecords');
              
  }    

  /**
   * Method to set Auto Renewal fields on Contract based on Account
   */
  private void getAccountForContractUpdates(Map<Id,SObject> newRecordMap, 
                                          Map<Id,SObject> oldRecordMap, 
                                          List <SObject> records, 
                                          String jsonParameter, 
                                          String triggerOrder, 
                                          String triggerContext){
    log.addLog('Start: getAccountForContractUpdates');
    try{
      //List of Account Ids for which Contract should be pulled
      List<Id> eligibleAccounts = new List<Id>();

      //Check the trigger context
      if (triggerOrder == 'POST' && triggerContext.contains('Update')) {
        for(SObject newAccRecord: records){
          //get old and new values
          Account newAccount = (Account)newAccRecord;
          Account oldAccount = (Account)oldRecordMap.get(newAccount.Id);

          if(newAccount.BusinessGroup__c == 'Core' && 
            oldAccount!=null && 
            oldAccount.Auto_Renewal_Status_Core__c != newAccount.Auto_Renewal_Status_Core__c){
            eligibleAccounts.add(newAccount.Id);
          }
        }

        if(eligibleAccounts!=null && !eligibleAccounts.isEmpty()){
            DynamicBusinessRuleAutoRenewal.updateContractAutoRenewals(eligibleAccounts);
        }
      }
      log.addLog('End: getAccountForContractUpdates' + JSON.serialize(eligibleAccounts));
    }
    catch(Exception ex){
      log.addExceptionLog(ex);
    }
  }

  @future
  public static void updateContractAutoRenewals(List<Id> eligibleAccounts){   
    //Create log instance
    LogModel log = LogModel.startLog('DynamicBusinessRuleAutoRenewal', 'updateContractAutoRenewals');
    try{
      log.addLog('Start: future method');
      //If eligible accounts are present then get contracts
      if(eligibleAccounts!=null && !eligibleAccounts.isEmpty()){
  
        //List of contracts to be updated
        List<Contract> contractsToBeUpdated = new List<Contract>();
  
        log.addLog('Fetching Contracts');
          
        for(Contract contractToBeUpdated : [SELECT Id,
                                                    Account.Auto_Renewal_Status_Core__c,
                                                    Account.Auto_Renewal_Status_Reason_Core__c 
                                                FROM Contract
                                                WHERE AccountId in :eligibleAccounts 
                                                AND SBQQ__ActiveContract__c = 1 
                                                AND Has_SaaS_Products__c = FALSE 
                                                AND RMA_Detected__c = FALSE 
                                                AND Business_Group__c = 'Core' 
                                                AND Auto_Renewal_Status_Core__c != 'Excluded - Manually'
                                                AND Demo_Opp__c != true])
        {
 
          //Prepare contract to be updated
          contractsToBeUpdated.add(new Contract(Id = contractToBeUpdated.Id,
                                                Auto_Renewal_Status_Core__c = contractToBeUpdated.Account.Auto_Renewal_Status_Core__c,
                                                Auto_Renewal_Status_Reason_Core__c = contractToBeUpdated.Account.Auto_Renewal_Status_Reason_Core__c));                                           
        }
        //Update eligible contracts
        if(contractsToBeUpdated!=null && !contractsToBeUpdated.isEmpty()){
          Database.SaveResult[] srList = Database.update(contractsToBeUpdated, false);
    
          for(Database.SaveResult sr: srList){
            if(sr.isSuccess()){
              log.addLog(sr.getId());
            }
            else{
              String errorMessage = 'Error: ';
              for(Database.Error err: sr.getErrors()){
                errorMessage+= err.getMessage();
              }
              log.addLog(sr.getId() + ' ' + errorMessage);
            }
          }
        }
      } 
      log.endLog('End: future method');
    }
    catch(DmlException de){
      log.addExceptionLog(de);
    }
    catch(Exception ex){
      log.addExceptionLog(ex);
    }
  }
}