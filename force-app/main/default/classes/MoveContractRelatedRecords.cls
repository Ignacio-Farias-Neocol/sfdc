public with sharing class MoveContractRelatedRecords {

    @AuraEnabled
    public static MoveContractRelatedRecords.moveContractRecordsResult initiateMoveProcess(string sourceContractNumber,Id currentContractId)
    {
      
      MoveContractRelatedRecords.moveContractRecordsResult updateResult = new MoveContractRelatedRecords.moveContractRecordsResult(); 
        updateResult.result  = true;  
        updateResult.message='';
        LogModel log = LogModel.startLog('MoveContractRelatedRecords','initiateMoveProcess');

      try {        
        
        System.debug('sourceContractNumber::'+ sourceContractNumber);
        System.debug('currentContractId::'+ currentContractId);

        Contract currentCon= [Select Id, AccountId from Contract where Id=:currentContractId];
        Contract sourceCon=  [Select Id, AccountId from Contract where ContractNumber=:sourceContractNumber];

        System.debug('sourceContractId::'+ sourceCon.Id);
        List<SBQQ__Subscription__c> sourceSubstoUpdate=new List<SBQQ__Subscription__c>();
        List<Asset> sourceAssetstoUpdate=new List<Asset>();
        List<Assigned_Serial__c > sourceAStoUpdate=new List<Assigned_Serial__c >();
        Set<Id> assetIds=new Set<Id>();
        Set<Id> subIds=new Set<Id>();

        if(!checkSameContract(sourceCon.Id,currentCon.Id)){

          if(currentCon.AccountId!=sourceCon.AccountId)
          {                      
            // Subs
          System.debug('In Subs');
           for(SBQQ__Subscription__c sub : [Select Id, SBQQ__Account__c,SBQQ__RootId__c,SBQQ__Contract__c from SBQQ__Subscription__c where SBQQ__Contract__c =:sourceCon.Id])
            {              
              sub.SBQQ__Contract__c=currentCon.Id;
              sub.SBQQ__Account__c=currentCon.AccountId;
              sourceSubstoUpdate.add(sub);
              assetIds.add(sub.SBQQ__RootId__c);
              subIds.add(sub.Id);
            }

            System.debug('Subs Complete');
            
            // Assets
            System.debug('In  Assets');
            for(Asset assts :  [Select Id, AccountId from Asset where Id in :assetIds])
            {
              assts.AccountId=currentCon.AccountId;
              sourceAssetstoUpdate.add(assts);             
            }

            System.debug('Assets Complete');

            // Assigned Serials

            System.debug('In  AS');

            for(Assigned_Serial__c  assrs :  [Select Id, End_User_Account__c from Assigned_Serial__c where Subscription__c in :subIds])
            {
              assrs.End_User_Account__c=currentCon.AccountId;
              sourceAStoUpdate.add(assrs);             
            }     

            System.debug('AS Complete');
            
            if(sourceSubstoUpdate.size()==0 && sourceAssetstoUpdate.size()==0 && sourceAStoUpdate.size()==0){
              updateResult.result =false;
              updateResult.message='There are no records to be moved to the current contract';
            }

            else if((sourceSubstoUpdate.size() + sourceAssetstoUpdate.size() + sourceAStoUpdate.size())>10000) { //10000
              //updateResult.result =false;
              updateResult.message='All the Records will not be moved due to Salesforce Technical Limitations.'+
              'Please Rerun the process again to move the remaining records';

              //Send Lists to Queueable  Job

              System.debug('Sub Size ::'+ sourceSubstoUpdate.size());
              System.debug('Asst Size ::'+ sourceAssetstoUpdate.size());
              System.debug('AS Size ::'+ sourceAStoUpdate.size());
            }
              AsyncMoveContractRelatedRecords jinst= new AsyncMoveContractRelatedRecords(sourceSubstoUpdate,
              sourceAssetstoUpdate,sourceAStoUpdate);
             
              ID jobID = System.enqueueJob(jinst);       

              log.addLog('Job Trigerred with Id : ' + jobID);       

              System.debug('Job triggered with Id::'+ jobID);
              
              updateResult.result =true;
              updateResult.message= jobID;
              // updateResult.succesSubCount=AsyncMoveContractRelatedRecords.subListUpdater.size();
              // updateResult.succesAsstCount=AsyncMoveContractRelatedRecords.asstListUpdater.size();
              // updateResult.succesAsCount=AsyncMoveContractRelatedRecords.asListUpdater.size();      
              
              updateResult.succesSubCount=sourceSubstoUpdate.size();
              updateResult.succesAsstCount=sourceAssetstoUpdate.size();
              updateResult.succesAsCount=sourceAStoUpdate.size();   

              // System.debug('succesSubCount::'+updateResult.succesSubCount);
              // System.debug('succesAsstCount::'+updateResult.succesAsstCount);
              // System.debug('succesAsCount::'+updateResult.succesAsCount);
              
              //log.endlog();
                     
          }
          else {            
            updateResult.result =false;
            updateResult.message='Same Account on both Contracts. Cant Proceed Further';
          }
        }   
        
        else {

          updateResult.result =false;
          updateResult.message='You must select a different source contract than the current contract';          
        }
          
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }

      return updateResult;
    }
    
    @AuraEnabled
    public static string checkJobStatus(Id jobID)
    {
      AsyncApexJob jobInfo = [SELECT Status, NumberOfErrors,JobItemsProcessed,TotalJobItems FROM AsyncApexJob WHERE Id = :jobID];
      return jobInfo.status;
    }
  
    public static Boolean checkSameContract(Id sourceContractId,Id currentContractId){
        
      Boolean isSame=false;
      try {

            System.debug('In checkSameContract');
            LogModel log = LogModel.startLog('MoveContractRelatedRecords','checkSameContract');
            log.addLog('MoveContractRelatedRecords checkSameContract method');
            log.addLog('Recepient Contract Id : ' + currentContractId);
            log.addLog('source Contract Id : ' + sourceContractId);          

            isSame= currentContractId!=sourceContractId ?  false:  true;

            System.debug('isSame::' + isSame);

            log.endLog();
            
        } catch (Exception e) {       

        }
        return isSame;
    }

    public class moveContractRecordsResult {
  
        @AuraEnabled
        public String message;
      
        @AuraEnabled
        public Boolean result;    

        @AuraEnabled
        public Integer succesSubCount;  

        @AuraEnabled
        public Integer succesAsstCount;  

        @AuraEnabled
        public Integer succesAsCount;  
      }  
}