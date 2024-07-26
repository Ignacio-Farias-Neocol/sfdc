public with sharing class AsyncMoveContractRelatedRecords  implements  Queueable { //Finalizer
    List<SBQQ__Subscription__c> subList ;
    List<Asset> asstList ;
    List<Assigned_Serial__c> asList ;
    static final Integer MAX_DML_ROWS = 10000; 
    public Integer dmlRowCounter=0;
    public  List<SBQQ__Subscription__c> subListUpdater=new List<SBQQ__Subscription__c>();
    public  List<Asset> asstListUpdater=new List<Asset>();
    public  List<Assigned_Serial__c> asListUpdater=new List<Assigned_Serial__c>();
    
    public AsyncMoveContractRelatedRecords(List<SBQQ__Subscription__c> subList,
    List<Asset> asstList,List<Assigned_Serial__c> asList) {    
        this.subList = subList ;  
        this.asstList = asstList ;  
        this.asList = asList ;     
    }

    public void execute(QueueableContext ctx) {

        LogModel log = LogModel.startLog('AsyncMoveContractRelatedRecords','execute'); 
        //log.addLog('AsyncMoveContractRelatedRecords execute method');
        String jobId = '' + ctx.getJobId();
        System.debug('Begin: executing queueable AsyncMoveContractRelatedRecords job: ' + jobId);

        try {

           // AsyncMoveContractRelatedRecords f = new AsyncMoveContractRelatedRecords();
           // System.attachFinalizer(f);

            Savepoint sp;
            Boolean transError=false;

            if((!transError && subList!=null && !subList.isEmpty())){
                
            System.debug('subList size::'+subList.size());
           
            for(Integer i=0;i<subList.size(); i++)
            {
                dmlRowCounter++;

                System.debug('dmlRowCounter::'+dmlRowCounter);

                if(dmlRowCounter==MAX_DML_ROWS)
                  break;
                else 
                  subListUpdater.add(subList.get(i));
            }

            sp = Database.setSavepoint();

            Database.SaveResult[] srList = Database.update(subListUpdater, true);
            for(Database.SaveResult sr: srList){
                if(!sr.isSuccess()){
                  Database.RollBack(sp);
                    transError=true;
                    String errorMessage =  'Error updating Sub ' + sr.getId() + ' : ';
                    for(Database.Error error: sr.getErrors()){
                      errorMessage += error.getMessage();
                    }
                    System.debug('errorMessage::'+errorMessage);
                    log.addLog(errorMessage);
                  }
                  else{
                    System.debug('Sub updated: ' + sr.getId());
                    log.addLog('Sub updated: ' + sr.getId());
                  }
            }
          }

    if((!transError && asstList!=null && !asstList.isEmpty())){      

      System.debug('asstList size: ' +asstList.size()); 
     
      for(Integer i=0;i<asstList.size(); i++)
      {
          dmlRowCounter++;

          System.debug('dmlRowCounter::'+dmlRowCounter);

          if(dmlRowCounter==MAX_DML_ROWS)
            break;
          else 
          asstListUpdater.add(asstList.get(i));

      }

      Database.SaveResult[] srList = Database.update(asstListUpdater, true);
      for(Database.SaveResult sr: srList){
          if(!sr.isSuccess()){

            Database.RollBack(sp);
              transError=true;
              String errorMessage =  'Error updating Asset ' + sr.getId() + ' : ';
              for(Database.Error error: sr.getErrors()){
                errorMessage += error.getMessage();
              }
              System.debug('errorMessage::'+errorMessage);
              log.addLog(errorMessage);
              
            }
            else{
              System.debug('Asset updated: ' + sr.getId());
              log.addLog('Asset updated: ' + sr.getId());
            }
      }
    }
     
    if((!transError && asList!=null && !asList.isEmpty())){     

        for(Integer i=0;i<asList.size(); i++)
        {
            dmlRowCounter++;
  
            System.debug('dmlRowCounter::'+dmlRowCounter);
  
            if(dmlRowCounter==MAX_DML_ROWS)
              break;
            else 
            asListUpdater.add(asList.get(i));  
        }

        Database.SaveResult[] srList = Database.update(asListUpdater, true);
        for(Database.SaveResult sr: srList){
            if(!sr.isSuccess()){

              Database.RollBack(sp);
                transError=true;
                String errorMessage =  'Error updating Assigned Serial ' + sr.getId() + ' : ';
                for(Database.Error error: sr.getErrors()){
                  errorMessage += error.getMessage();
                }
                System.debug('errorMessage::'+errorMessage);
                log.addLog(errorMessage);
              
              }
              else{
                System.debug('Assigned Serial updated: ' + sr.getId());
                log.addLog('Assigned Serial updated: ' + sr.getId());
              }
        }
      }
   }
    catch (Exception e) {

      log.addExceptionLog(e);
      log.endLog();
    } finally {
        System.debug('Completed: execution of AsyncMoveContractRelatedRecords queueable job: ' + jobId);
        log.addLog('Completed: execution of AsyncMoveContractRelatedRecords queueable job: ' + jobId);
        log.endLog();
     }
    }  
}