global with sharing class  OpptySharingResellerBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Integer defaultBatchSize = 1;
    private Integer defaultLoadSize = null;
    global Map<Id, List<User>> mAccUser=new  Map<Id, List<User>>();    


    public String SOQL = 'Select Id , AccountId ,Distributor__c,Reseller__c from Opportunity where Distributor__c!=null and Reseller__c!=null and  Oppty_Status__c =\'Open\' and CloseDate >=today  and Oppty_Record_Type__c =\'New Business\'';

    public OpptySharingResellerBatch() {

        List<Batch_Job_System_Property__mdt> props = [Select ID, DeveloperName, MasterLabel, Value__c, Business_Group__c From Batch_Job_System_Property__mdt];

        for (Batch_Job_System_Property__mdt prop : props) {
            if ((prop.DeveloperName == 'Oppty_Sharing_Status_Load_Size' && !String.isEmpty(prop.Value__c))) {
                try {
                    defaultLoadSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
            
            if ((prop.DeveloperName == 'Oppty_Sharing_Status_Batch_Size' && !String.isEmpty(prop.Value__c))) {
                try {
                    defaultBatchSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
        }
    
        if (defaultLoadSize != null)
                SOQL += ' LIMIT ' + String.valueOf(defaultLoadSize);

        for( User u : [Select id, contact.AccountId from User where isActive=true and IsPortalEnabled=true and UserType ='PowerPartner' order by Contact.Account.Name]) {

            if(mAccUser.containsKey(u.contact.AccountId)){
            
             mAccUser.get(u.contact.AccountId).add(u);
            }
            else {
                System.Debug('*** u.contact.AccountId ' + u.contact.AccountId);
                mAccUser.put(u.contact.AccountId, new List<User> { u });
               System.Debug('*** mAccUser *** ' + mAccUser);
             }
            }

            System.Debug('*** mAccUser ' + mAccUser);
     }

    
     global Database.QueryLocator start(Database.BatchableContext bc) {
        System.Debug('*** defaultBatchSize ' + defaultBatchSize);
        System.Debug('*** SOQL ' + SOQL);
        return Database.getQueryLocator(SOQL);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> oList){

        LogModel log = LogModel.startLog('OpptySharingResellerBatch','execute');  
        List<OpportunityShare> oppShareAddList = new List<OpportunityShare>();
       
        try {
        for (Opportunity o: oList){
            if (mAccUser.containsKey(o.Reseller__c)){

              for(User u : mAccUser.get(o.Reseller__c)) {   

                OpportunityShare oppShare = new OpportunityShare();
                oppShare.OpportunityAccessLevel = 'Edit';
                oppShare.OpportunityId = o.Id;
                oppShare.UserOrGroupId = u.Id;
                oppShare.RowCause = 'Manual';
                oppShareAddList.add(oppShare);
            }
        }
        }

        if(oppShareAddList!=null && !oppShareAddList.isEmpty()){
            log.addLog('oppShareDelList::'  + oppShareAddList);
            Database.SaveResult[] srList = Database.insert(oppShareAddList, false);
            for(Database.SaveResult sr: srList){
              if(!sr.isSuccess()){
                String errorMessage =  'Error While Inserting Oppty in OpportunityShare Table : ' + sr.getId();
                for(Database.Error error: sr.getErrors()){
                  errorMessage += error.getMessage();
                }      
                log.addLog(errorMessage);        
                System.Debug(errorMessage);
              }    
              else if(sr.isSuccess())   {
                System.Debug('Successfully shared Opportunity. OpptyShareId : ' + sr.getId());
                log.addLog('Successfully shared Opportunity. OpptyShareId : ' + sr.getId());     
              }
            }
          }

        }
        catch (Exception ex) {
            log.addExceptionLog(ex);  
        }
        log.endLog();
    }

    global void finish(Database.BatchableContext BC){}
}