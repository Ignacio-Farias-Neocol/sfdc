/**
 * Author: 
 * Date: 
 * Description: Class to fetch Contracts for a given serial.
 *              Used by Subscription Management Upsell Downsell flow.
 */
public with sharing class ContractIdentification {
  @InvocableMethod (label='Fetch Contracts For Serial' description='Fetches Contracts for a given Serial')
  //The input parameter needs to be a list for invocable methods, but this method will always get one Serial Id
  public static List<ContractIdentification.ContractFetchResult> fetchContracts(List<Id> serialIdList){

    //Map of Contract Id and related record
    Set<Id> activeContractIdSet = new Set<Id>();
    Set<Id> inactiveContractIdSet = new Set<Id>();
    //Query list of Assigned Serials using the Serial list provided.
    // Loop through assigned serials to fetch distinct contracts
    
    for(Assigned_Serial__c currentAS : [SELECT Id,
                                              Subscription__r.SBQQ__Contract__c,
                                              Asset__r.Contract__c,
                                        	  Subscription__r.SBQQ__Contract__r.SBQQ__ActiveContract__c ,
                                              Asset__r.Contract__r.SBQQ__ActiveContract__c ,
                                              /**Added as a part of SFDC-18249 */
                                              Subscription__r.Renewed_By_Subscription__c,
                                              Subscription__r.Renewed_By_Subscription__r.Name
                                        FROM Assigned_Serial__c 
                                        WHERE Serial__c =: serialIdList[0] 
                                        AND ((Subscription__c != NULL) OR (Asset__c != NULL))]){
      //Contract Id variable
      Id activeContractId;
	    Id inactiveContractId;
      //First check subscription. If subscripition is present then get the contract details.
      if(currentAS.Subscription__c != NULL){
          /**Added as a part of SFDC-18249: START */
          if(currentAS.Subscription__r.Renewed_By_Subscription__c == NULL && currentAS.Subscription__r.SBQQ__Contract__r.SBQQ__ActiveContract__c == 1){
          /**Added as a part of SFDC-18249: END */
            //Get the subscription contract id
        	activeContractId = currentAS.Subscription__r.SBQQ__Contract__c;
          }else{
            inactiveContractId = currentAS.Subscription__r.SBQQ__Contract__c;  
          }
      }
      //If only Asset is present then get the contract details.
      else if(currentAS.Asset__c != NULL){
        if(currentAS.Asset__r.Contract__r.SBQQ__ActiveContract__c == 1){  
        	//Get the subscription contract id
        	activeContractId = currentAS.Asset__r.Contract__c;
        }
          else{
            inactiveContractId = currentAS.Asset__r.Contract__c;  
          }
      }

      if(String.isNotBlank(activeContractId)){
        //If contract is not present in the set, then add it
        activeContractIdSet.add(activeContractId);
      }
      if(String.isNotBlank(inactiveContractId)){
        //If contract is not present in the set, then add it
        inactiveContractIdSet.add(inactiveContractId);
      }                                     
    } //END OF ASSIGNED SERIAL LOOP
    
    //Prepare the return value
    ContractIdentification.ContractFetchResult resultObj = new ContractIdentification.ContractFetchResult();
    //Check if any contracts were found
    if(activeContractIdSet!=null && !activeContractIdSet.isEmpty()){
      System.debug('Contract Set: ' + activeContractIdSet + ' Size: ' + activeContractIdSet.size());
      //Fetch contract details
      resultObj.contractList = [SELECT Id,   
                                       ContractNumber, SBQQ__ActiveContract__c   
                                FROM Contract 
                                WHERE Id in :activeContractIdSet];
      //If more than one contract was identified, then pass the result as false and send corresponding message
      if(activeContractIdSet.size()>1){
        resultObj.result = false;
        resultObj.message = Label.SubMgmt_Multiple_Contract_Message;
      }
      //If only one contract was identified, then pass the result as true and send corresponding message
      else{
        resultObj.result = true;
        resultObj.message = Label.SubMgmt_One_Contract_Message;
        for(Id cId: activeContractIdSet){
          resultObj.contractId = cId;
        }
          
      }
    }
    else if(inactiveContractIdSet!=null && !inactiveContractIdSet.isEmpty()){
resultObj.contractList = [SELECT Id,   
                                       ContractNumber, SBQQ__ActiveContract__c   
                                FROM Contract 
                                WHERE Id in :inactiveContractIdSet];  
        if(inactiveContractIdSet.size()>1){
        resultObj.result = false;
        resultObj.message = Label.SubMgmt_multiple_Inactive_Contract_Message;
      	}
        else{
        resultObj.result = true;
        resultObj.message = Label.SubMgmt_One_Contract_Message;
        for(Id cId: inactiveContractIdSet){
          resultObj.contractId = cId;
        }
          
      }
    }
    //If no contract was identified, then pass the result as false and send corresponding message
    else{
      resultObj.result = false;
      resultObj.message = Label.SubMgmt_No_Contract_Message;
    }

    return new List<ContractIdentification.ContractFetchResult>{resultObj};
  }

  public class ContractFetchResult {

    @InvocableVariable
    public List<Contract> contractList;

    @InvocableVariable
    public String message;

    @InvocableVariable
    public Boolean result; 
    
    @InvocableVariable
    public Id contractId; 
  }  
}