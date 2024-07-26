public class UpdContractHasSaaSProductQueueable implements Queueable {
    private Set<String> eligibleContracts;

    public UpdContractHasSaaSProductQueueable(Set<String> eligibleContracts) {
        this.eligibleContracts = eligibleContracts;
    }
    public void execute(System.QueueableContext qc) {
        
    //Create log instance
    LogModel log = LogModel.startLog('DynamicBusinessRuleSubscription', 'updateContractHasSaaSProduct');

    try{
      log.addLog('Start: Queueable class');
      Map<String, Set<Id>> eligibleContractsMap = new Map<String, Set<Id>>{'SAAS' => new Set<Id>(),
                                                                           'RMA' => new Set<Id>()};
      if(eligibleContracts!=null && !eligibleContracts.isEmpty()){
        //prepare the map of type of update needed and eligible contracts
        for(String currentEntry: eligibleContracts){
          String[] tokens = currentEntry.split('_');
          if(tokens!=null && !tokens.isEmpty()){
            eligibleContractsMap.get(tokens[0]).add(tokens[1]);
          }
        }
        //If eligible accounts are present then get contracts
        if(eligibleContractsMap!=null && !eligibleContractsMap.isEmpty()){
    
          //List of contracts to be updated
          Map<Id,Contract> contractsToBeUpdatedMap = new Map<Id,Contract>();

          //HAS SAAS Products Contract
          log.addLog('Fetching Contract Subcriptions to determine Saas Contract');
          //Fetch contract subscriptions where Is_SaaS_Subscription__c = true
          if(eligibleContractsMap.containsKey('SAAS')){
              for(AggregateResult aggResult : [SELECT COUNT(Id),
                                                      SBQQ__Contract__c
                                              FROM SBQQ__Subscription__c
                                              WHERE SBQQ__Contract__c in :eligibleContractsMap.get('SAAS')
                                              AND Is_SaaS_Subscription__c = TRUE
                                              GROUP BY SBQQ__Contract__c])
              {
                  if((Integer)aggResult.get('expr0')>0){
                      //Get contract Id
                      Id contractId = (Id)aggResult.get('SBQQ__Contract__c');
                      if(contractsToBeUpdatedMap.containsKey(contractId)){
                          contractsToBeUpdatedMap.get(contractId).Has_SaaS_Products__c = TRUE;
                      }
                      else{
                          //Prepare contract to be updated
                          contractsToBeUpdatedMap.put(contractId, new Contract(Id = contractId,
                                                                              Has_SaaS_Products__c = TRUE)); 
                      }

                      //Remove this contract Id from the eligibleContracts set. 
                      //Later we will loop through remaining contracts and set their Has SaaS value to false
                      eligibleContractsMap.get('SAAS').remove(contractId);
                  }                           
              }
          }

          //Loop through remaining eligible contracts to set remaining contracts Has Saas value to false
          for(Id contractId: eligibleContractsMap.get('SAAS')){
              //The if check is redundant here because in the previous step we added eligible contracts.
              //Adding if check to keep it consistent
              if(contractsToBeUpdatedMap.containsKey(contractId)){
                  contractsToBeUpdatedMap.get(contractId).Has_SaaS_Products__c = FALSE;
              }
              else{
                  //Prepare contract to be updated
                  contractsToBeUpdatedMap.put(contractId, new Contract(Id = contractId,
                                                                      Has_SaaS_Products__c = FALSE)); 
              }
          }
          
          //RMA Detected Contract
          log.addLog('Fetching Contract Subcriptions to determine RMA Contract');
          //Fetch contract subscriptions where Active__c == FALSE && SBQQ__TerminatedDate__c != ""
          if(eligibleContractsMap.containsKey('RMA')){
              for(AggregateResult aggResult : [SELECT COUNT(Id),SBQQ__Contract__c FROM SBQQ__Subscription__c WHERE (Active__c = TRUE OR SBQQ__TerminatedDate__c = NULL) 
                                               AND SBQQ__Contract__c in :eligibleContractsMap.get('RMA') GROUP BY SBQQ__Contract__c])
              {
                  if((Integer)aggResult.get('expr0')>0){
                      //Get contract Id
                      Id contractId = (Id)aggResult.get('SBQQ__Contract__c');
                      if(contractsToBeUpdatedMap.containsKey(contractId)){
                          contractsToBeUpdatedMap.get(contractId).RMA_Detected__c = FALSE;
                      }
                      else{
                          //Prepare contract to be updated
                          contractsToBeUpdatedMap.put(contractId, new Contract(Id = contractId,
                                                                              RMA_Detected__c = FALSE)); 
                      }

                      //Remove this contract Id from the eligibleContracts set. 
                      //Later we will loop through remaining contracts and set their RMA detected value to false
                      eligibleContractsMap.get('RMA').remove(contractId);
                  }                           
              }
          }

          //Loop through remaining eligible contracts to set remaining contracts RMA detected value to false
          for(Id contractId: eligibleContractsMap.get('RMA')){
              //If check is important here because there could be overlap between Has SaaS and RMA
              if(contractsToBeUpdatedMap.containsKey(contractId)){
                  contractsToBeUpdatedMap.get(contractId).RMA_Detected__c = TRUE;
              }
              else{
                  //Prepare contract to be updated
                  contractsToBeUpdatedMap.put(contractId, new Contract(Id = contractId,
                                                                      RMA_Detected__c = TRUE)); 
              }
          }

          //Update Has Saas products value on contracts
          if(contractsToBeUpdatedMap!=null && !contractsToBeUpdatedMap.isEmpty()){
            Database.SaveResult[] srList = Database.update(contractsToBeUpdatedMap.values());
      
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
      }    
      log.endLog('End: Queueable Class');
    }
    catch(DmlException de){
      log.addExceptionLog(de);
    }
    catch(Exception ex){
      log.addExceptionLog(ex);
    }
    }
}