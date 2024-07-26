/****SFDC-19804****/
public without sharing class DynamicBusinessRuleOppSharing implements DynamicBusinessRuleAction {  

  
  public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records,
   String jsonParameter, String triggerOrder, String triggerContext) {
       
       List<Id> ListOpptoshare = new List<Id>();
       List<Id> ListOpptosharedel = new List<Id>();
       List<String> ListResellerId = new List<String>();
       
       try{
            if(triggerContext.contains('Insert') && triggerOrder.contains('POST')) {
             
             for(Opportunity currentOpp: (List<Opportunity>) newRecordMap.values()){  
                 if(currentOpp.Reseller__c!=null &&  currentOpp.Distributor__c!=null){
                     ListOpptoshare.add(currentOpp.Id);
                 
                 }    
             
             }      
            }
    
            if(triggerContext.contains('Update') && triggerOrder.contains('POST')) {
               for(Opportunity currentOpp: (List<Opportunity>) newRecordMap.values()){  
                   Opportunity oldOpp = (Opportunity)oldRecordMap.get(currentOpp.Id);
                   if(currentOpp.Distributor__c!=null){
                       if(currentOpp.Reseller__c!=oldOpp.Reseller__c){
                           if(currentOpp.Reseller__c!=null)
                              ListOpptoshare.add(currentOpp.Id);
                           if(oldOpp.Reseller__c!=null){
                               ListOpptosharedel.add(currentOpp.Id);
                               ListResellerId.add(currentOpp.Id +'-'+oldOpp.Reseller__c); 
                           }    
                       
                       }
                       if(currentOpp.Distributor__c!=oldOpp.Distributor__c){
                           if(currentOpp.Reseller__c!=null)
                              ListOpptoshare.add(currentOpp.Id);                   
                       }             
                   
                   }
                   else if(currentOpp.Distributor__c == null){
                       if(oldOpp.Distributor__c!=null && currentOpp.Reseller__c!=null){
                           ListOpptosharedel.add(currentOpp.Id);
                           ListResellerId.add(currentOpp.Id +'-'+currentOpp.Reseller__c);
                       
                       } else if(oldOpp.Distributor__c!=null && oldOpp.Reseller__c!=null){
                           ListOpptosharedel.add(currentOpp.Id);
                           ListResellerId.add(currentOpp.Id +'-'+oldOpp.Reseller__c);
                       
                       }             
                   }
               
               }
              
            }
            
            if(ListResellerId!=null && !ListResellerId.IsEmpty()){
                AsyncOpptySharing.delmanualsharingOpp(ListOpptosharedel,ListResellerId);
            }
            
            if(ListOpptoshare!=null && !ListOpptoshare.IsEmpty()){
                AsyncOpptySharing.addmanualsharingOpp(ListOpptoshare);
            
            }
         }catch(Exception Ex){
             AppLog__c log = new AppLog__c(Is_Error__c = true,message__c = Ex.getMessage(),apexClassName__c = 'DynamicBusinessRuleOppSharing');
            
            Insert log;
         }
 }

 
}