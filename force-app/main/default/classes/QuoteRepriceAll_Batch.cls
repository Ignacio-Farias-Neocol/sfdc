/******************************************************

SFDC-17186 - Automate Price Change

*******************************************/

global class QuoteRepriceAll_Batch implements Database.Batchable<SObject>,Database.Stateful {
     String region = '';
     Set<Id> QuoteIds = new Set<Id>();

     public QuoteRepriceAll_Batch(String strregion) {
     
         region = strregion;
         RepriceQuoteStart__c otime = RepriceQuoteStart__c.getInstance(strregion);
         otime.Starttime__c = System.now();
        //User u = [select firstname,username from user where id=:userinfo.getuserid()];
        //otime.User_Name__c = u.username;//UserInfo.getUserId();     
         otime.User_Name__c =  UserInfo.getUserId(); 
         update otime;
     
     }
     
      public Database.QueryLocator start(Database.BatchableContext BC) {
        try{
            String SOQL = 'SELECT SBQQ__Status__c,ReCalToggle__c, SBQQ__LastCalculatedOn__c, Repriced_Date__c,Pricing_Region_CPQList__c from SBQQ__Quote__c where SBQQ__Primary__c = true';
            SOQL += ' and SBQQ__Opportunity2__r.Oppty_Status__c =\''+ 'Open'+'\'';
            SOQL += ' and Pricing_Region__c =: region';
            
            System.debug('SOQL...'+SOQL);
            return Database.getQueryLocator(SOQL);
          }catch(Exception Ex){
            AppLog__c log = new AppLog__c(Is_Error__c = true,message__c = Ex.getMessage(),apexClassName__c = 'QuoteRepriceAll_Batchstrt',Region__c =  region,endTime__c = System.now());
            
            Insert log;
           return Database.getQueryLocator('');
        } 
    }    
    
    
    public void execute(Database.BatchableContext BC, List<SBQQ__Quote__c> quoterecords){
        try{
         RepriceQuoteStart__c otime1 = RepriceQuoteStart__c.getInstance(region);
         
         for(SBQQ__Quote__c oquote : quoterecords){
            if(oquote.Repriced_Date__c == null || oquote.Repriced_Date__c < otime1.Starttime__c){
                if(!QuoteIds.contains(oquote.Id)){
                    QuoteIds.add(oquote.Id);
                    SBQQ__Quote__c quote = new SBQQ__Quote__c(Id=oquote.Id);
                    quote.Repriced_Date__c = System.now();
                    quote.ReCalToggle__c = oquote.ReCalToggle__c == true ? false :true;
                    Update quote;
            }
           }         
         }
        }catch(Exception Ex){
            AppLog__c log = new AppLog__c(Is_Error__c = true,message__c = Ex.getMessage(),apexClassName__c = 'QuoteRepriceAll_Batchexec',Region__c =  region,endTime__c = System.now());
           
            Insert log;
        }
    
    }    
    
    
     public void finish(Database.BatchableContext BC){
      try{
         // System.debug('****finish****'+ QuoteIds.size()+'*****'+starttime);
          List<AppLog__c> appLogList = new  List<AppLog__c>();
           RepriceQuoteStart__c otime = RepriceQuoteStart__c.getInstance(region);
            Datetime timestamp = otime.Starttime__c;
            String RepriceBatchstart = timestamp.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
            
           Map<Id,SBQQ__Quote__c> mapquotesrepriced = new Map<Id,SBQQ__Quote__c>([Select Id,Name from SBQQ__Quote__c where Pricing_Region_CPQList__c=: region 
                                                      and SBQQ__LastCalculatedOn__c >=: timestamp]);
            
            Set<Id> SetQuoteRepriced = mapquotesrepriced.keySet();
                                                     
            if(QuoteIds.size() > SetQuoteRepriced.size()){
             Integer total = QuoteIds.size();
             
             QuoteIds.removeall(SetQuoteRepriced);
             System.debug('Failed Quotes'+QuoteIds);
             String recordsfail = JSON.serialize(QuoteIds);
             
             while(recordsfail.length() > 1){
                AppLog__c log = new AppLog__c();
                log.Is_Error__c = true;
                String strrecord = JSON.serialize(QuoteIds);
                if(recordsfail.length() > 131070){
                    log.Records__c = strrecord.substring(0, 131070); 
                    recordsfail = strrecord.substring(131070,strrecord.length());
                }else{
                   log.Records__c = strrecord;
                   recordsfail = '';
                }
                log.apexClassName__c = 'QuoteRepriceBatch-Finish';
                log.Region__c = region;
                log.endTime__c = System.now();
                appLogList.add(log);
             }
                Insert appLogList;
                //sendEmail('Failure'+ String.valueof(total) ,SetQuoteTotal.size());
             
             
         }else if(QuoteIds.size() == SetQuoteRepriced.size()){
             System.debug('Success');
             sendEmail('Success',QuoteIds.size());
         }else{
            System.debug('Success');
              sendEmail('Success',QuoteIds.size());
         }
        }catch(Exception ex){
        
         AppLog__c log = new AppLog__c(Is_Error__c = true,message__c = Ex.getMessage(),apexClassName__c = 'QuoteReprice_Batch-Finish',Region__c =  region,endTime__c = System.now());
           
            Insert log;
        }                                     
     
 }    


    public static void sendEmail(String Message,Integer totalrecs){
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMEssage>();
       
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            //String[] toAddresses = new String[] {'nshet@barracuda.com','apadhy@barracuda.com'};
            String[] toAddresses = Label.QuoteRepriceemails.split(',');
            mail.setToAddresses(toAddresses);
            mail.setSenderDisplayName('Price List Change Process');
            String htmlBody = '';
            if(Message == 'Success'){
                htmlBody += '<font face="arial" size="2"> <p>Quote reprice completed Successfully</p></font> ';
            }else{
                htmlBody += '<font face="arial" size="2"> <p>Quote reprice completed with errors.';
                htmlBody += totalrecs +'Quotes Failed </p></font> ';
            }
            mail.setSubject('Price List Change Process - Quote Update');
            mail.setHtmlBody(htmlBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
        if(mails.size() > 0){
            Messaging.sendEmail(mails);
        }
    }


}