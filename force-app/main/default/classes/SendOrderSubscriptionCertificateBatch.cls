/*
 *Author: Bhavesh Jha
 * 
 * 
 */
global class SendOrderSubscriptionCertificateBatch implements Database.Batchable<sObject>,Schedulable, Database.Stateful {
    
    //Stateful processedOrderIds for the reduce duplication of sending an email.
    private Set<String> processedOrderIds = new Set<String>();
    private final static Integer PDF_PAGE_SIZE = 999;
    global Database.QueryLocator start(Database.BatchableContext BC){        
        String query='SELECT id,Order__c,Order__r.Bill_To_Account__r.Bill_To_Email__c,'+
                        'Order__r.Opportunity.Reseller_Contact_Email__c' +
                        ' FROM Serial__c' +
                        ' WHERE Order__c != null AND Activation_Date__c = TODAY' ;
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        LogModel logModel = LogModel.startLog(
                'SendOrderSubscriptionCertificateBatch',
                'Processing Daily Batches',
                LogModel.LOG_CATEGORY_ASYNCHRONOUS_PROCESS
        );
        try{
            Map<String,List<String>> orderVsEmailsMap = new Map<String,List<String>>();
            System.debug('SendSubscriptionCertificateBatch :: scope ::'+JSON.serialize(scope));
            
            Set<String> orderIds = new Set<String>();
            for(Serial__c serial: (List<Serial__c>)scope){
                System.debug('SendOrderSubscriptionCertificateBatch :: serial.Order__r.Bill_To_Account__r.Bill_To_Email__c ::'+serial.Order__r.Bill_To_Account__r.Bill_To_Email__c);
                System.debug('SendOrderSubscriptionCertificateBatch :: serial.Order__r.Opportunity.Reseller_Contact_Email__c ::'+serial.Order__r.Opportunity.Reseller_Contact_Email__c);
                if(serial.Order__c != null){
                    if(!processedOrderIds.contains(serial.Order__c)){
                        List<String> tmpEmailList = new List<String>();
                        if(serial.Order__r.Bill_To_Account__r.Bill_To_Email__c != null)
                            tmpEmailList.add(serial.Order__r.Bill_To_Account__r.Bill_To_Email__c);
                        if(serial.Order__r.Opportunity.Reseller_Contact_Email__c != null)
                            tmpEmailList.add(serial.Order__r.Opportunity.Reseller_Contact_Email__c);
                        orderVsEmailsMap.put(serial.Order__c,tmpEmailList);
                        orderIds.add(serial.Order__c);
                        processedOrderIds.add(serial.Order__c);
                    }
                }
            }
            System.debug('SendOrderSubscriptionCertificateBatch :: orderVsEmailsMap ::'+orderVsEmailsMap);
            System.debug('SendOrderSubscriptionCertificateBatch :: orderIds ::'+orderIds);
            Map<String,Order> orderMap = new Map<String,Order>([Select id,Active_Contract__r.SBQQ__Quote__r.Name,Bill_To_Account__r.id,PoNumber from Order where Id in: orderIds ]);

            Map<String,Integer> orderIdVsTotalPageMap = new Map<String,Integer>();
            Map<String,Integer> orderIdVsSerialCountMap = new Map<String,Integer>();


            AggregateResult[] groupedResults = [Select Order__c,count(Id) from Serial__c where Order__c =: orderVsEmailsMap.keyset() group by Order__c];

            for (AggregateResult ar : groupedResults){

              if(orderVsEmailsMap.containsKey((String)ar.get('Order__c'))){

                orderIdVsSerialCountMap.put((String)ar.get('Order__c'), (Integer)ar.get('expr0'));
              }

            }  
            System.debug('orderIdVsSerialCountMap :: orderIdVsSerialCountMap ::'+orderIdVsSerialCountMap);
           
            System.debug('SendOrderSubscriptionCertificateBatch :: orderVsEmailsMap ::'+orderVsEmailsMap);

            if(!orderVsEmailsMap.isEmpty()){
                for(String orderId: orderVsEmailsMap.keyset()){
                    // Integer serialCount = [Select count() from Serial__c where Order__c =: orderId];
                    // orderIdVsTotalPageMap.put(orderId,getPageCount(serialCount,PDF_PAGE_SIZE));
                    orderIdVsTotalPageMap.put(orderId,getPageCount(orderIdVsSerialCountMap.get(orderId),PDF_PAGE_SIZE));
                }
            }
            
            System.debug('SendOrderSubscriptionCertificateBatch :: orderVsEmailsMap ::'+JSON.serialize(orderVsEmailsMap));
            System.debug('SendOrderSubscriptionCertificateBatch :: orderIdVsTotalPageMap ::'+JSON.serialize(orderIdVsTotalPageMap));
            
            Map<String,List<Blob>> orderIdvsBlobsForPDFMap = new Map<String,List<Blob>>();
            if(!orderIdVsTotalPageMap.isEmpty()){
                for(String orderId: orderIdVsTotalPageMap.keyset()){
                    orderIdvsBlobsForPDFMap.put(orderId,getCertificateBlobs('OrderSubscriptionCertificate',orderId,orderIdVsTotalPageMap.get(orderId),PDF_PAGE_SIZE));
                }
            }
    
            //Map for Send the multiple Attachment for perticular order(s).
            Map<String,List<Messaging.EmailFileAttachment>> orderIdVsSingleEmailAttachmentsMap = new Map<String,List<Messaging.EmailFileAttachment>>();
            if(!orderIdvsBlobsForPDFMap.isEmpty()){
                for(String orderId: orderIdvsBlobsForPDFMap.keyset()){
                    Integer pdfCount = 1;
                    if(orderIdvsBlobsForPDFMap.get(orderId) != null){
                        List<Messaging.EmailFileAttachment> tmpEmailAttachmentList = new List<Messaging.EmailFileAttachment>();
                        for(Blob currentBlob: orderIdvsBlobsForPDFMap.get(orderId)){
                            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                            attachment.setContentType('application/pdf');
                            attachment.setFileName('OrderSubscriptionCertificate '+pdfCount+'.pdf');
                            attachment.setInline(false);
                            attachment.setBody(currentBlob);
                            tmpEmailAttachmentList.add(attachment);
                            pdfCount+=1;
                        }
                        if(!tmpEmailAttachmentList.isEmpty()){
                            orderIdVsSingleEmailAttachmentsMap.put(orderId,tmpEmailAttachmentList);
                        }
                    }
                }
            }
            
            System.debug('SendOrderSubscriptionCertificateBatch :: orderIdVsSingleEmailAttachment ::'+orderIdVsSingleEmailAttachmentsMap);
            List<EmailTemplate> emailTemplate=  [Select id from EmailTemplate where DeveloperName=:'Order_Subscription_Letter_V2' LIMIT 1];
            List<Messaging.SingleEmailMessage> sendCertificateEmailList = new List<Messaging.SingleEmailMessage>();
            if(!orderIdVsSingleEmailAttachmentsMap.isEmpty()){
                for(String orderId: orderIdVsSingleEmailAttachmentsMap.keyset()){
                    if(orderVsEmailsMap.get(orderId) != null){
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        message.setTargetObjectId(Userinfo.getUserId());
                        message.setSenderDisplayName('Barracuda'); 
                        message.setReplyTo('no-reply@barracuda.com');
                        message.setUseSignature(false); 
                        message.setBccSender(false); 
                        message.setSaveAsActivity(false); 
                        if(!emailTemplate.isEmpty()){
                            message.setTemplateId(emailTemplate[0].Id);
                        }
                        message.setWhatId(Id.valueOf(orderId));
                        if(orderIdVsSingleEmailAttachmentsMap.containsKey(orderId)){
                            message.setFileAttachments(orderIdVsSingleEmailAttachmentsMap.get(orderId));
                        }
                        message.toAddresses = orderVsEmailsMap.get(orderId);
                        message.setTreatTargetObjectAsRecipient(false);
                        
                        sendCertificateEmailList.add(message);
                    }
                }
                System.debug('SendOrderSubscriptionCertificateBatch :: sendCertificateEmailList ::'+JSON.serialize(sendCertificateEmailList));
                if(!sendCertificateEmailList.isEmpty()){
                    Messaging.SendEmailResult [] sendEmailResults = Messaging.sendEmail(sendCertificateEmailList,false);
                    for(Messaging.SendEmailResult result: sendEmailResults){
                        if(!result.IsSuccess()){
                            for(Messaging.SendEmailError  error: result.getErrors()){
                                System.debug('Error while sending email:' + error);
                            }
                        }else{
                            System.debug('Email Send Successfully');
                        }
                    }
                }
            }
        }catch(Exception e){
            
            System.debug('SendOrderSubscriptionCertificateBatch :: Exception ::'+e.getMessage());
            logModel.addExceptionLog(e);
        }
    }
    
    /*@param totalResultSize: pass total results
     * @param pageSize: pass single page page size 
     * return => total number of pages regarding to totalResultSize.
     */
    private Integer getPageCount(Integer totalResultSize, Integer pageSize){
        Integer result = 0;
        if(totalResultSize > 0){
            result = totalResultSize / pageSize;
            if(result > 0 && (totalResultSize > (pageSize * result))){
                result++;
            }
        }
        return result == 0 ? 1 : result;
    }
    
    //get the pdf blob as per the parameters.
    /*
     * @param  pageName: page name which we want to retrive.
     * @param orderId: Order Id
     * @param pageNum: total number of page
     * @param singlePageSize: single Page Size of single file.
     */
    private static List<blob> getCertificateBlobs(String pageName,String orderId,Integer pageNum,Integer singlePageSize){
        System.debug('SendOrderSubscriptionCertificateBatch :: getCertificateBlob :: MODE :: ENTER');
        LogModel logModel = LogModel.startLog(
                'SendOrderSubscriptionCertificateBatch::getCertificateBlob',
                'In Processing Daily Batches',
                LogModel.LOG_CATEGORY_ASYNCHRONOUS_PROCESS
        );
        
        List<Blob> certificateBlobList = new List<Blob>();
        System.debug('SendOrderSubscriptionCertificateBatch :: getCertificateBlob :: MODE :: orderId'+orderId);
        System.debug('SendOrderSubscriptionCertificateBatch :: getCertificateBlob :: MODE :: pageNum'+pageNum);
        System.debug('SendOrderSubscriptionCertificateBatch :: getCertificateBlob :: MODE :: singlePageSize'+singlePageSize);
        try {
            if(!Test.isRunningTest()){
                Boolean setFirstIndex = true;
                for(Integer i=0;i<=pageNum-1;i++){
                    PageReference page = new PageReference('/apex/'+pageName);
                    page.getParameters().put('id', orderId);
                    if(setFirstIndex){
                        page.getParameters().put('curserIndex', String.valueof((i)));
                        setFirstIndex = false;
                    }else{
                        page.getParameters().put('curserIndex', String.valueof((i*singlePageSize)));
                    }
                    page.getParameters().put('pageSize', String.valueof(singlePageSize));
                    Blob certificateBlob = page.getContentAsPDF();
                    certificateBlobList.add(certificateBlob);
                }
            }else{
                certificateBlobList = new List<Blob>{Blob.valueOf('BLOB')};
            }
        }
        catch (Exception e) {
            System.debug('SendOrderSubscriptionCertificateBatch :: e ::'+e.getMessage());
            logModel.addExceptionLog(e);
            return null;
        }
        System.debug('SendOrderSubscriptionCertificateBatch :: getCertificateBlob :: MODE :: EXIT');
        return certificateBlobList;
    }

    global void finish(Database.BatchableContext BC){}

    global void execute(SchedulableContext sc){
        Database.executeBatch(new SendOrderSubscriptionCertificateBatch(),200);
    }
}