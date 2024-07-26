/***** SFDC-18733*****/
public class Serialsharingrecalc implements Database.Batchable<sObject> {
    public Set<String> statusset = new Set<String>{'Draft','In Approval Process','Activated'};
    public String message = 'Success';
    String stryear ='';
    String strmin='';
    String strmax = '';
    
    
      public Serialsharingrecalc(String yr,string min,String max){
          stryear = yr;
          strmin = min;
          strmax = max;
      
      }
    
      public Database.QueryLocator start(Database.BatchableContext BC){
       /*return Database.getQueryLocator([Select Id,(select Subscription__r.SBQQ__Contract__r.Distributor__c, Subscription__r.SBQQ__Contract__r.Reseller__c, 
                                    Subscription__r.SBQQ__Contract__r.AccountId from Assigned_Serials__r where Subscription__r.SBQQ__Contract__r.NOC_Expired__c = false limit 1) from Serial__c
                                    where Is_Terminated__c = false and CALENDAR_YEAR(CreatedDate) =2023 ]);*/
                                    //Expire_Date__c <LAST_N_YEARS:1 ]); 
                                    
      string query = 'Select Id,(select Subscription__r.SBQQ__Contract__r.Distributor__c,Subscription__r.SBQQ__Contract__r.Reseller__c,Subscription__r.SBQQ__Contract__r.AccountId from Assigned_Serials__r where Subscription__r.SBQQ__Contract__r.NOC_Expired__c = false limit 1) from Serial__c where Is_Terminated__c = false';
      
      if(stryear!='')
        query += ' and CALENDAR_YEAR(CreatedDate) ='+stryear;
      
      if(strmin!='')
       query += ' and CALENDAR_MONTH(CreatedDate) >'+strmin;
      
      if(strmax!='')
       query += ' and CALENDAR_MONTH(CreatedDate) <'+strmax; 
                                 
      return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Serial__c> scope){
        Map<Id,Set<Id>> mapAccountIds = new Map<Id,Set<Id>>();
        Set<Id> setAccounts = new Set<Id>();
        List<Serial__share> listshareupds = new List<Serial__share>();
        Map<Id,Set<Id>> mapAccUserIds = new Map<Id,Set<Id>>();
        Database.SaveResult[] srList;
        
        try{
         for(Serial__c oserial : scope){
             for(Assigned_Serial__c oassignedser : oserial.Assigned_Serials__r){
                 if(!mapAccountIds.containskey(oserial.Id)){
                     Set<Id> setids = new Set<Id>();
                     if(oassignedser.Subscription__r.SBQQ__Contract__r.AccountId!=null)
                       setids.add(oassignedser.Subscription__r.SBQQ__Contract__r.AccountId);
                     
                     if(oassignedser.Subscription__r.SBQQ__Contract__r.Distributor__c!=null)
                        setids.add(oassignedser.Subscription__r.SBQQ__Contract__r.Distributor__c);
                     
                     if(oassignedser.Subscription__r.SBQQ__Contract__r.Reseller__c!=null)
                        setids.add(oassignedser.Subscription__r.SBQQ__Contract__r.Reseller__c);
                     
                     mapAccountIds.put(oserial.Id,setids);
                     setAccounts.addall(setids);
                 
                 }
            }
            
         }
         System.debug('***'+setAccounts);
         System.debug('***'+mapAccountIds);
         
         if(!setAccounts.IsEmpty()){
             for(User ouser : [Select Id,Contact.AccountId from User where Contact.AccountId IN : setAccounts and 
             IsActive=true and profile.UserLicense.Name Not IN ('Guest User License','Chatter Free','Customer Community')]){
                   if(mapAccUserIds.containskey(ouser.Contact.AccountId))
                      mapAccUserIds.get(ouser.Contact.AccountId).add(ouser.Id);
                    else
                      mapAccUserIds.put(ouser.Contact.AccountId,new Set<Id>{ouser.Id});
                       
                }
          } 
          System.debug('***'+mapAccUserIds);
             
         for(Id serialId : mapAccountIds.keyset()){
                for(Id accid : mapAccountIds.get(serialId)){
                    if(mapAccUserIds.containskey(accid )){
                        for(Id userId : mapAccUserIds.get(accid)){
                            if(userId !=null)
                            listshareupds.add(new Serial__share(ParentId=serialId, UserOrGroupId = userId, RowCause=Schema.Serial__share.RowCause.Community_Share__c, AccessLevel='Edit'));
                        }
                    }
                }
                
            }
            
                        
            if(listshareupds!=null && !listshareupds.Isempty()){
                srList = Database.insert(listshareupds);
                for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    message = 'Failed';
                    // Operation failed, so get all errors                
                    /*for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }*/
                }
             }
            }
            
            
            
         
           
        }catch(Exception Ex){
            AppLog__c log = new AppLog__c(Is_Error__c = true,message__c = Ex.getMessage()+Ex.getStackTraceString()+Ex.getlinenumber(),apexClassName__c = 'SerialSharinghelper',endTime__c = System.now());
           
            Insert log;
        }
               
    }
    
    public void finish(Database.BatchableContext BC){  
        sendEmail(message);
    
    } 
    
    
    
    public static void sendEmail(String Message){
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMEssage>();
       
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {'nshet@barracuda.com','apadhy@barracuda.com'};
            mail.setToAddresses(toAddresses);
            mail.setSenderDisplayName('Serial Sharing Process');
            String htmlBody = '';
            if(Message == 'Success'){
                htmlBody += '<font face="arial" size="2"> <p>Serial Sharing Processed Successfully</p></font> ';
            }else{
                htmlBody += '<font face="arial" size="2"> <p>Serial Sharing Processed with errors.';
                //htmlBody += totalrecs +'Quotes Failed </p></font> ';
            }
            mail.setSubject('Serial Sharing Process');
            mail.setHtmlBody(htmlBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
        if(mails.size() > 0){
            Messaging.sendEmail(mails);
        }
    }


}