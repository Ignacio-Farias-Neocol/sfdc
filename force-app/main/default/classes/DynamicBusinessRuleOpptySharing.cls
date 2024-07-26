public without sharing class DynamicBusinessRuleOpptySharing implements DynamicBusinessRuleAction {  

  public static Map<Id, List<User>> mAccUser =new Map<Id, List<User>>();

  static {

    for( User u : [Select id, contact.AccountId from User where isActive=true and IsPortalEnabled=true and UserType ='PowerPartner']) {

      if(mAccUser.containsKey(u.contact.AccountId)){
    
        mAccUser.get(u.contact.AccountId).add(u);
      }
      else {
    
        mAccUser.put(u.contact.AccountId, new List<User> { u });
      }
    }
  }  
  
  public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records,
   String jsonParameter, String triggerOrder, String triggerContext) {

        if(triggerContext.contains('Insert') && triggerOrder.contains('POST')) {
         
         identifyOppstoShare(newRecordMap, oldRecordMap,triggerContext);        
        }

        if(triggerContext.contains('Update') && triggerOrder.contains('POST')) {
               
          identifyOppstoShare(newRecordMap, oldRecordMap,triggerContext);
        }
 }

 private void identifyOppstoShare(Map<Id,SObject> newRecordMap, Map<Id, SObject> oldRecordMap,String triggerContext){

  List<User> oldUserIdList=new List<User> ();
  List<Id> oldResellerIds=new List<Id>();
  List<User> newUserIdList=new List<User> ();
  List<Id> newResellerIds=new List<Id>();
  Map<Id, Id> oldOpptyResellerMap= new Map<Id, Id>(); 
  Map<Id, Id> newOpptyResellerMap= new Map<Id, Id>(); 

  for(Opportunity currentOpp: (List<Opportunity>) newRecordMap.values()){   

    if(triggerContext.contains('Insert')) {   

      if(currentOpp.Reseller__c!=null &&  currentOpp.Distributor__c!=null){ // Insert

        System.debug(' Insert' );
        oldOpptyResellerMap=null;                  
        newOpptyResellerMap.put(currentOpp.Id,currentOpp.Reseller__c);       
      }
    }
    else  if(triggerContext.contains('Update')) {

      Opportunity oldOpp = (Opportunity)oldRecordMap.get(currentOpp.Id);

       if( currentOpp.Reseller__c!=null &&  currentOpp.Distributor__c!=null){  //  Distributor Present      
       
        if(oldOpp.Reseller__c!=null && (oldOpp.Reseller__c!=currentOpp.Reseller__c)) {    // Means Reseller Changed ;; Delete Old Reseller Users from Opp Sharing and add new Reseller Users           

         System.debug('Means Reseller Changed ;; Delete Old Reseller Users from Opp Sharing and add new Reseller Users ');      
     
          oldOpptyResellerMap.put(currentOpp.Id,oldOpp.Reseller__c);  
       
          newOpptyResellerMap.put(currentOpp.Id,currentOpp.Reseller__c);       
        } 

         else if(oldOpp.Reseller__c==null) {  // Means Reseller Added ;; // Add New Reseller Users to Opp Share, Nothing to delete from Opp Share
         
          System.debug(' Means Reseller Added ;; // Add New Reseller Users to Opp Share, Nothing to delete from Opp Share ');      
          oldOpptyResellerMap=null;         

          newOpptyResellerMap.put(currentOpp.Id,currentOpp.Reseller__c);        
         }

         else if(oldOpp.Distributor__c==null && oldOpp.Reseller__c!=null) {  // Means Distributor  Added when Reseller was already present
          System.debug(' Means Distributor  Added when Reseller was already present ');    
            
          oldOpptyResellerMap.put(currentOpp.Id,oldOpp.Reseller__c);  
       
          newOpptyResellerMap.put(currentOpp.Id,currentOpp.Reseller__c);      
         }
      }

      else if( currentOpp.Reseller__c==null &&  currentOpp.Distributor__c!=null){

        if(oldOpp.Reseller__c!=null) {  //  Reseller Removed ;; Delete from Opp Sharing
          System.debug(' Reseller Removed ;; Delete from Opp Sharing ');  

          newOpptyResellerMap=null;        

          oldOpptyResellerMap.put(currentOpp.Id,oldOpp.Reseller__c);          
        }
      }

      else if( currentOpp.Reseller__c==null &&  currentOpp.Distributor__c==null){ 

        if(oldOpp.Reseller__c!=null && oldOpp.Distributor__c!=null) {  // Reseller and Distributor Removed;; Remove Old Reseller from Opp Share
          System.debug(' Reseller and Distributor Removed;; Remove Old Reseller from Opp Share ');  
          newOpptyResellerMap=null;
       
          oldOpptyResellerMap.put(currentOpp.Id,oldOpp.Reseller__c);         
        }
      }

      else if( currentOpp.Reseller__c!=null &&  currentOpp.Distributor__c==null){  

       // Distributor Removed and Reseller changed
       // No Need to Share With Current Reseller as Bill to Account will Be Current Reseller
       
        if((oldOpp.Reseller__c!=currentOpp.Reseller__c) && oldOpp.Distributor__c!=null) {

          System.debug(' Distributor Removed and Reseller change ;  No Need to Share With Current Reseller as Bill to Account will Be Current Reseller');  
          newOpptyResellerMap=null;      

          oldOpptyResellerMap.put(currentOpp.Id,oldOpp.Reseller__c);         
        } 

       else if((oldOpp.Reseller__c==currentOpp.Reseller__c) && oldOpp.Distributor__c!=null) {

          System.debug(' Distributor Removed and Reseller Same ;  No Need to Share With Current Reseller as Bill to Account will Be Current Reseller');  
          newOpptyResellerMap=null;
       
          oldOpptyResellerMap.put(currentOpp.Id,oldOpp.Reseller__c);          
        } 
      }
  }
}

   System.debug('newOpptyResellerMap::' + newOpptyResellerMap);
   System.debug('oldOpptyResellerMap::' + oldOpptyResellerMap);    
  
  addManualSharing(newOpptyResellerMap,oldOpptyResellerMap);
}  

// public static void addManualSharing( Map<Id, Id> opptyNewResellerMap,Map<Id, Id> opptyOldResellerMap) {

//   ID jobID = System.enqueueJob(new AsyncAddOpptySharing(opptyNewResellerMap,opptyOldResellerMap));
//   System.debug('Job to update Subs triggered with jobID::'+jobID);       
// }

public static void addManualSharing( Map<Id, Id> opptyNewResellerMap,Map<Id, Id> opptyOldResellerMap) {

  System.debug('opptyNewResellerMap::' + opptyNewResellerMap);
  
  System.debug('opptyOldResellerMap::' + opptyOldResellerMap);   
  
  System.debug('mAccUser::'+ mAccUser);

  List<OpportunityShare> oppShareAddList = new List<OpportunityShare>();
  Map<Id, Id> x=new Map<Id, Id>();
  Map<Id, List<Id>> y=new Map<Id, List<Id>>();
  List<OpportunityShare> oppShareDelList = new List<OpportunityShare>();

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