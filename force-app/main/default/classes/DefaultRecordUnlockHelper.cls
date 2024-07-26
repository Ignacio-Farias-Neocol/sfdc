/**
* Invocable apex class used to set unlock records from Process Builder
*
* @Author Pradeep Shetty
* @Date 2019/09/30
* @Group Helper
*
* @description
* This helper class helps unlock a record locked due to approval process. 
* This is done by calling an invocable method from process builder. : List<Response> execute(List<Request> requests)
* We are using Without sharing to allow all users to unlock record. Else this method fails. 
*/
public without sharing class DefaultRecordUnlockHelper{

  //Establish variables that will be passed in by Process Builder
  public class Request {
    @InvocableVariable(
      label = 'Record ID'
      description = 'ID of the record that needs to be unlocked'
      required = true
    )
    public Id recordId;

    @InvocableVariable(
      label = 'Flag Field Name'
      description = 'Developer name of the flag field that is used to identify records to be unlocked'
      required = true
    )
    public String unlockFlagFieldName;
  }

  //Invocable method to be called by Process Builder for unlocking record
  @InvocableMethod(
    label = 'Unlock Records'
    description = 'Unlock records based on a flag'
  )
  /***********************************************************************
  * @description Method to execute logic to unlock records identified by a flag
  *
  * @param Requests
  * @return void
  */
  public static void unlockRecords(List<Request> requests) {

    //Instantiate the log class to capture logs for error conditions
    LogModel log = LogModel.startLog('DefaultRecordUnlockHelper', 'Starting Record Unlocking', LogModel.LOG_CATEGORY_APEX);    
     
    //List of record ids to be unlocked
    List<Id> unlockRecordsList = new List<Id>();

    //Map of sobjects to be used to reset the flag
    Map<Id, SObject> recordsUnlockedMap = new Map<Id, SObject>();

    //List of sobjects to be used to reset the flag
    List<SObject> recordsUnlockedList = new List<SObject>();

    try {
      if (requests != null && !requests.isEmpty()) {
        //Loop through all rows passed by the process builder and check if they are locked or not
        for (Request req : requests) {
          if(Approval.isLocked(req.recordId)){
            //If record is locked,add it to the list to be used with Approval.unlock() method
            //Else skip it
            unlockRecordsList.add(req.recordId);

            //Create an SObject instance to be used to reset the flag
            SObject unlockedRecord = req.recordId.getSobjectType().newSObject(req.recordId);
            unlockedRecord.put(req.unlockFlagFieldName, false);
            recordsUnlockedMap.put(req.recordId,unlockedRecord);             
          }
        }
      }

      //Unlock records if there are records that are locked
      if(unlockRecordsList!=null && !unlockRecordsList.isEmpty()){
        //Unlock records using Approval class methods. This returns a list of results of the unlocking operation
        List<Approval.UnlockResult> unlockResultList = Approval.unlock(unlockRecordsList);

        //Loop through the result to determine which records were unlocked and reset the flag accordingly
        for(Approval.UnlockResult ur: unlockResultList){
          //Check Approval result
          if(ur.isSuccess()){
            //Add the record for which the flag needs to be reset
            recordsUnlockedList.add(recordsUnlockedMap.get(ur.getId()));       
          }
          else{
            //Operation failed.
            //Get all errors
            String lockErrorMesssage = 'Following error has occured.';
            for(Database.Error err: ur.getErrors()){
              lockErrorMesssage += err.getStatusCode() + ': ' + err.getMessage();
            }
            //Add to log
            log.addLog('DefaultRecordUnlockHelper', lockErrorMesssage, Logmodel.LOG_TYPE_ERROR, ur.getId());
          }
        }

        if(recordsUnlockedList!=null && !recordsUnlockedList.isEmpty()){
          //Reset flag on records
          Database.SaveResult[] srList = Database.update(recordsUnlockedList, false);

          //Loop through save result to see if any update failed
          for(Database.SaveResult sr: srList){
            if(!sr.isSuccess()){
              //Update operation failed
              //Get all errors
              String updateErrorMesssage = 'Following error has occured.';
              for(Database.Error err: sr.getErrors()){
                updateErrorMesssage += err.getStatusCode() + ': ' + err.getMessage();
              }
              //Add to log
              log.addLog('DefaultRecordUnlockHelper', updateErrorMesssage, Logmodel.LOG_TYPE_ERROR, sr.getId());                        
            }
          }          
        }
      }
      log.endLog();
    } catch (Exception ex){
      //Log the error
      log.addExceptionLog(ex);
    }
  }
}