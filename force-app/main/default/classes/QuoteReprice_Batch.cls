/******************************************************

SFDC-17186 - Automate Price Change

*******************************************/

global class QuoteReprice_Batch implements Database.Batchable<SObject>,Database.Stateful {
    List<CPQ_List_Price__c> CPQlistPrice = new List<CPQ_List_Price__c>();
    Set<Id> QuoteIds = new Set<Id>();
    Date todayDate = Date.today() ;
    Set<String> regionSet = new Set<String>();
    Set<String> currencyCodeSet = new Set<String>();
    Set<Id> prodIdsSet = new Set<Id>();
    String region = '';
    Datetime starttime = System.now();
    
    public QuoteReprice_Batch(String strregion,String strDate) {
        if(strDate!=null && strDate!='')
            todayDate = Date.valueof(strDate);
        region = strregion;
        
        RepriceQuoteStart__c otime = RepriceQuoteStart__c.getInstance(strregion);
        otime.Starttime__c = System.now();
        //User u = [select firstname,username from user where id=:userinfo.getuserid()];
        //otime.User_Name__c = u.username;//UserInfo.getUserId();     
        otime.User_Name__c =  UserInfo.getUserId(); 
        update otime;
    
        for(CPQ_List_Price__c oListPrice : [Select Product__c,CurrencyIsoCode from CPQ_List_Price__c where 
        Valid_Start_Date__c =: todayDate and Region__c=:region and Active__c =true]){
            prodIdsSet.add(oListPrice.Product__c);
            currencyCodeSet.add(oListPrice.CurrencyIsoCode);
                    
        }
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        try{
            String SOQL = 'SELECT Id,SBQQ__Product__c,SBQQ__Quote__c,SBQQ__Quote__r.Name,SBQQ__Quote__r.SBQQ__Status__c,SBQQ__Quote__r.ReCalToggle__c,  ';
            SOQL += 'SBQQ__Quote__r.Pricing_Region_CPQList__c,SBQQ__Quote__r.Repriced_Date__c FROM SBQQ__QuoteLine__c ';
            SOQL += 'WHERE SBQQ__Product__c  IN :prodIdsSet ';
            SOQL += 'AND SBQQ__Quote__r.Pricing_Region_CPQList__c =: region AND  SBQQ__Quote__r.SBQQ__Opportunity2__r.CurrencyIsoCode IN :currencyCodeSet ';
            SOQL += ' AND SBQQ__Quote__r.SBQQ__Opportunity2__r.Oppty_Status__c =\''+ 'Open'+'\''+' and SBQQ__Quote__r.SBQQ__Primary__c =true'+' order by SBQQ__Quote__r.Name desc';
            
            System.debug('SOQL...'+SOQL);
            return Database.getQueryLocator(SOQL);
            
            
        /*
        String stropen = 'Open';
        //RepriceQuoteStarttime__c otime1 = RepriceQuoteStarttime__c.getInstance('00ef2000001s8BK');
        //Datetime timestamp = otime1.Job_Start_time__c;
        
        RepriceQuoteStart__c otime1 = RepriceQuoteStart__c.getInstance(region);
        Datetime timestamp = otime1.Starttime__c;
        
        String RepriceBatchstart = timestamp.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        Set<Id> recordIds = new Set<Id>();
        System.debug('****start');
        try{
            for(SBQQ__QuoteLine__c olineitem : [SELECT Id,SBQQ__Product__c,SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Status__c From SBQQ__QuoteLine__c 
                                            WHERE SBQQ__Product__c  IN : prodIdsSet AND SBQQ__Quote__r.SBQQ__Opportunity2__r.CurrencyIsoCode IN : currencyCodeSet
                                            AND SBQQ__Quote__r.Pricing_Region_CPQList__c =: region
                                            and SBQQ__Quote__r.SBQQ__Opportunity2__r.Oppty_Status__c =:stropen 
                                            and SBQQ__Quote__r.SBQQ__Primary__c =true limit 1]){
                if(olineitem.SBQQ__Quote__c != null ){
                 System.debug('olineitem .SBQQ__Quote__c'+olineitem.SBQQ__Quote__c);
                   if(!QuoteIds.contains(olineitem .SBQQ__Quote__c)){
                       QuoteIds.add(olineitem.SBQQ__Quote__c);
                       recordIds.add(olineitem.SBQQ__Quote__c);
                   }
                }
            }
           
        //String SOQL = 'SELECT Id,Pricing_Region__c,Name,SBQQ__Status__c FROM SBQQ__Quote__c where ID IN : recordIds and Repriced_Date__c=null and Repriced_Date__c <' + RepriceBatchstart;
        String SOQL = 'SELECT Id,Pricing_Region_CPQList__c,Name,Repriced_Date__c,ReCalToggle__c,SBQQ__Status__c FROM SBQQ__Quote__c where ID IN : recordIds';
        System.debug('SOQL....'+SOQL+recordIds);
          return Database.getQueryLocator(SOQL);*/
        }catch(Exception Ex){
            AppLog__c log = new AppLog__c(Is_Error__c = true,message__c = Ex.getMessage(),apexClassName__c = 'QuoteReprice_Batch',Region__c =  region,endTime__c = System.now());
            
            Insert log;
           return Database.getQueryLocator('');
        } 
    }

 public void execute(Database.BatchableContext BC, List<SBQQ__QuoteLine__c> quoteLineItems){
 //public void execute(Database.BatchableContext BC, List<SBQQ__Quote__c> quoterecords){
   
    System.debug('****'+quoteLineItems.size());
    try{
         RepriceQuoteStart__c otime1 = RepriceQuoteStart__c.getInstance(region);
        
        //Datetime timestamp = otime1.Job_Start_time__c;
        //String RepriceBatchstart = timestamp.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        
        for(SBQQ__QuoteLine__c oquoteline : quoteLineItems){
            if(oquoteline.SBQQ__Quote__r.Repriced_Date__c == null || oquoteline.SBQQ__Quote__r.Repriced_Date__c < otime1.Starttime__c){
                if(!QuoteIds.contains(oquoteline.SBQQ__Quote__c)){
                    QuoteIds.add(oquoteline.SBQQ__Quote__c);
                    SBQQ__Quote__c oquote = new SBQQ__Quote__c(Id=oquoteline.SBQQ__Quote__c);
                    oquote.Repriced_Date__c = System.now();
                    oquote.ReCalToggle__c = oquoteline.SBQQ__Quote__r.ReCalToggle__c == true ? false :true;
                    Update oquote;
                    
                    Task completionTask = new Task();
                    completionTask.Subject = 'Quote Recalculation Completed for '+oquoteline.SBQQ__Quote__r.Name;
                    completionTask.Status = 'Completed';
                    completionTask.Priority = 'Normal';
                    completionTask.WhatId = oquoteline.SBQQ__Quote__r.Id;
                    INSERT completionTask;
                
                }
               
            }
            
        /*for(SBQQ__QuoteLine__c olineitem : quoteLineItems){
            if(olineitem .SBQQ__Quote__c != null ){
               if(!QuoteIds.contains(olineitem .SBQQ__Quote__c)){
                   System.debug('olineitem .SBQQ__Quote__c'+olineitem .SBQQ__Quote__c);
                   QuoteIds.add(olineitem .SBQQ__Quote__c);
                   QuoteReader qr = new QuoteReader();
                   QuoteModel quoteModel = qr.read(String.valueOf(olineitem .SBQQ__Quote__c));
                   CPQ_QuoteCalculator calculator = new CPQ_QuoteCalculator ();
                        calculator.calculate(quoteModel, 'CalculatePricecallback');
                }
            }*/
        }
     }catch(Exception Ex){
         AppLog__c log = new AppLog__c(Is_Error__c = true,message__c = Ex.getMessage(),apexClassName__c = 'QuoteReprice_Batch',Region__c =  region,endTime__c = System.now());
           
            Insert log;
     }
 }
 
 public void finish(Database.BatchableContext BC){
      System.debug('****finish****'+ QuoteIds.size()+'*****'+starttime);
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
            log.apexClassName__c = 'QuoteRepriceBatch';
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
                                                 
      //QuoteRepriceTaskCreate_Batch  Quotetaskbatch  = new QuoteRepriceTaskCreate_Batch(QuoteIds,String.valueof(starttime));
      //System.scheduleBatch(Quotetaskbatch,'QuoteTAskBatch', 5);
      //ID jobID = System.enqueueJob(new QuoteTaskjobqueue(QuoteIds,region));
            
      /*Integer jobs = [Select count() From AsyncApexJob Where JobType = 'BatchApex' and ( Status = 'Queued' or Status = 'Processing' or Status = 'Preparing' )];
        if( jobs > 4 ){
             QuoteRepriceTaskCreate_Batch  Quotetaskbatch  = new QuoteRepriceTaskCreate_Batch(QuoteIds,String.valueof(starttime));
            
            System.scheduleBatch(Quotetaskbatch,'QuoteTAskBatch', 2 );  //execute batch job after 2 minute              
        }
        else
        {
            QuoteRepriceTaskCreate_Batch  Quotetaskbatch  = new QuoteRepriceTaskCreate_Batch(QuoteIds,String.valueof(starttime));
            //Database.executeBatch( Quotetaskbatch, 1000 );//execute batch job now
            System.scheduleBatch(Quotetaskbatch,'QuoteTAskBatch', 2 );  //execute batch job after 2 minute 
        }*/
 }
 public static void sendEmail(String Message,Integer totalrecs){
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMEssage>();
       
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {'nshet@barracuda.com','apadhy@barracuda.com'};
            //String[] toAddresses = new String[] {'apadhy@barracuda.com'};
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