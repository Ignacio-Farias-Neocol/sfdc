public class AsyncAddOpptySharing  implements Queueable  {
 Map<Id, Id> opptyNewResellerMap= new Map<Id, Id>(); 
 Map<Id, Id> opptyOldResellerMap= new Map<Id, Id>();  
 
  public AsyncAddOpptySharing(Map<Id, Id> opptyNewResellerMap,Map<Id, Id> opptyOldResellerMap) {

    this.opptyNewResellerMap = opptyNewResellerMap ;  
    this.opptyOldResellerMap = opptyOldResellerMap ;        
 }

 public void execute(QueueableContext context){  

   System.debug('opptyNewResellerMap::' + opptyNewResellerMap);
  
   System.debug('opptyOldResellerMap::' + opptyOldResellerMap);     

   List<OpportunityShare> oppShareAddList = new List<OpportunityShare>();
   Map<Id, Id> x=new Map<Id, Id>();
   Map<Id, List<Id>> y=new Map<Id, List<Id>>();
   List<OpportunityShare> oppShareDelList = new List<OpportunityShare>();
   Map<Id, List<User>> mAccUser=new  Map<Id, List<User>>();

   for( User u : [Select id, contact.AccountId from User where isActive=true and IsPortalEnabled=true and UserType ='PowerPartner']) {

    if(mAccUser.containsKey(u.contact.AccountId)){

      mAccUser.get(u.contact.AccountId).add(u);
    }
    else {

      mAccUser.put(u.contact.AccountId, new List<User> { u });
    }
  }
  
  System.debug('mAccUser::' + mAccUser);

   if(opptyOldResellerMap!=null ) {

     deleteExistingManualSharing(opptyOldResellerMap,mAccUser);   
  }
  
  if (opptyNewResellerMap !=null ) {     

   for( Id oId : opptyNewResellerMap.keyset()) {      

    if(mAccUser.containsKey(opptyNewResellerMap.get(oId))) {   
      for(User u : mAccUser.get(opptyNewResellerMap.get(oId)) ) {   
          OpportunityShare oppShare = new OpportunityShare();
          oppShare.OpportunityAccessLevel = 'Edit';
          oppShare.OpportunityId = oId;
          oppShare.UserOrGroupId = u.Id;
          oppShare.RowCause = 'Manual';
          oppShareAddList.add(oppShare);
        }
      }
    }
  }
    System.debug('oppShareAddList::'  + oppShareAddList);   

  if(oppShareAddList!=null && !oppShareAddList.isEmpty()){
    
    LogModel log = LogModel.startLog('DynamicBusinessRuleOpptySharing','addManualSharing');  
      try {
    
      log.addLog('oppShareAddList::'  + oppShareAddList);
      Database.SaveResult[] srList = Database.insert(oppShareAddList, false);
      for(Database.SaveResult sr: srList){
        if(!sr.isSuccess()){
          String errorMessage =  'Error While Inserting in OpporttyShare Id ' + sr.getId() + ' : ';
          for(Database.Error error: sr.getErrors()){
            errorMessage += error.getMessage();
          }
          log.addLog(errorMessage);
        }    
        else if(sr.isSuccess())   {
          System.Debug('Successfully shared Opportunity. OpptyShareId : ' + sr.getId());
          log.addLog('Successfully shared Opportunity. OpptyShareId : ' + sr.getId());     
        }   
      }
      
     } catch (Exception ex) {    
      log.addExceptionLog(ex);                 
     }
     log.endLog();
  }   
 }
 
 private static void deleteExistingManualSharing( Map<Id, Id> opptyResellerMap , Map<Id, List<User>> mAccUser) {
   
    List<OpportunityShare> oppShareDelList = new List<OpportunityShare>();
    
      for(OpportunityShare oshare : [Select Id,OpportunityId,UserOrGroupId from OpportunityShare where  RowCause='Manual' and IsDeleted=false and OpportunityId in : opptyResellerMap.keyset() ]) {      
     
      if (mAccUser.containsKey(opptyResellerMap.get(oshare.OpportunityId))){
        for(User u : mAccUser.get(opptyResellerMap.get(oshare.OpportunityId))){
          if(u.Id==oshare.UserOrGroupId ){
            oppShareDelList.add(oshare);
          }
       }
     }
    }

    if(oppShareDelList!=null && !oppShareDelList.isEmpty()){  

    LogModel log = LogModel.startLog('DynamicBusinessRuleOpptySharing','deleteExistingManualSharing'); 
     try {      
      System.debug('oppShareDelList::'  + oppShareDelList);
      
      log.addLog('oppShareDelList::'  + oppShareDelList);

      delete oppShareDelList;

    }catch (Exception ex) {
      log.addExceptionLog(ex);         
    }    
    log.endLog();
   }   
  }
}