/****SFDC-19804******/
public class AsyncOpptySharing{


    @future
    public static void addmanualsharingOpp(List<Id> opptyshareIds){
        List<OpportunityShare> oppShareAddList = new List<OpportunityShare>();
        
        Map<Id,Id> mapOppty = new Map<Id,Id>();
        
       /* if(!delshareoppIds.IsEmpty() && delshareoppIds!=null){
        
            List<OpportunityShare> delshares = [Select Id from OpportunityShare where OpportunityId IN:delshareoppIds and RowCause='Manual'];
            Database.delete(delshares,false);
        
        }*/
        
        if(opptyshareIds!=null && !opptyshareIds.IsEmpty()){
            for(Opportunity Opp : [Select Id,Reseller__c from Opportunity where Id IN : opptyshareIds]){
                  mapOppty.put(opp.Reseller__c,opp.Id);
                
            }
        
            for(User u :[Select id, contact.AccountId from User where isActive=true and IsPortalEnabled=true and UserType ='PowerPartner' and contact.AccountId IN :mapOppty.keyset()]){
                 OpportunityShare oppShare = new OpportunityShare();
                 oppShare.OpportunityAccessLevel = 'Edit';
                 oppShare.OpportunityId = mapOppty.get(u.contact.AccountId);
                 oppShare.UserOrGroupId = u.Id;
                 oppShare.RowCause = 'Manual';
                 oppShareAddList.add(oppShare);
                
            }
        
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
        
        
    }
    
    @future
    public static void delmanualsharingOpp(List<Id> delshareoppIds,List<String> opptyreseller){
        Map<Id,Id> ResellerIds = new map<Id,Id>();
      try{  
            for(String oppid : opptyreseller){
                List<String> liststr = new List<String>();
                liststr = oppid.split('-');
                ResellerIds.put(liststr[0],liststr[1]);
            }
           Map<Id,User> userIds = new Map<Id,User>([Select id from User where isActive=true and IsPortalEnabled=true and UserType ='PowerPartner' and 
                                       contact.AccountId IN :ResellerIds.values()]);
           
            if(!delshareoppIds.IsEmpty() && delshareoppIds!=null){
            
                List<OpportunityShare> delshares = [Select Id from OpportunityShare where OpportunityId IN:delshareoppIds and RowCause='Manual' and UserOrGroupId IN : userIds.KeySet()];
                Database.delete(delshares,false);
            
            }
        }catch(Exception Ex){
            AppLog__c log = new AppLog__c(Is_Error__c = true,message__c = Ex.getMessage(),apexClassName__c = 'AsyncOpptySharing');
            
            Insert log;
        }
        
    
    }
    
    



}