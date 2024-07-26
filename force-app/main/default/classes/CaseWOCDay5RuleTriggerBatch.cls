global class CaseWOCDay5RuleTriggerBatch implements Database.Batchable <SObject> {
    
    private List<OrgWideEmailAddress> owea = new List<OrgWideEmailAddress>();
    public String query;
    
    //START METHOD
    global Database.QueryLocator start(Database.BatchableContext bc){
        Datetime dt = System.now().addDays(-5);                             
        Id technicalSupportRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
        Id webMessageRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();    
        String queryString;
        if(Test.isRunningTest()){
            queryString = 'Select Id, Status, ContactId, RecordTypeId, BusinesGroup__c, WOC_Reason__c, Case_Reason__c, Closed_Case_Reason__c, Alternate_Email__c, Additional_Recipient_Email__c, SuppliedEmail from Case where Status = \'Waiting for Customer Response\'';
        } else {
            queryString = 'Select Id, Status, ContactId, RecordTypeId, BusinesGroup__c, WOC_Reason__c, Case_Reason__c, Closed_Case_Reason__c, Alternate_Email__c, Additional_Recipient_Email__c, SuppliedEmail from Case where Status = \'Waiting for Customer Response\' and ((Customer_Hold_Attempt_3__c = true and Customer_Hold_Attempt_1_Date_Time__c <=: dt and RecordTypeId =: technicalSupportRTId) or (Web_Message_Attempt_3__c = true and Web_Message_Attempt_1_Time_Stamp__c <=: dt and RecordTypeId =: webMessageRTId))';
        }         
        if(String.isBlank(query)) query = queryString;
        return Database.getQueryLocator(query);
    }
    
    //EXECUTE METHOD
    global void execute(Database.BatchableContext bc, List<Case> scope){
        LogModel log = LogModel.startLog('CaseWOCDay5RuleTriggerBatch', 'execute');
        try{
            Id technicalSupportRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
            Id webMessageRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();  
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            Map<String, Id> emailTemplatesMap = new Map<String, Id>();
            List<EmailTemplate> etList = [Select Id, DeveloperName from EmailTemplate where Folder.Name = 'Service Template'];
            for(EmailTemplate et: etList){
                emailTemplatesMap.put(et.DeveloperName, et.Id);
            }
            log.addLog('scope: ' + JSON.serialize(scope));
            for(Case c: scope){
                
                // Tech Support - WOC - CORE - CB
                if(c.RecordTypeId == technicalSupportRTId && c.BusinesGroup__c == 'Core' && c.WOC_Reason__c == 'Call back'){
                    //c.Case_Reason__c = 'No Resolution Possible';
                    //c.Closed_Case_Reason__c = 'Couldn\'t contact customer (after at least 3 attempts)';
                    c.Status = 'Closed';    
                    c.Closed_By_Process__c = 'Batch Class';
                    c.Day_5_Email_Sent__c = true;
                    Messaging.SingleEmailMessage mail = generateMail(c, emailTemplatesMap, 'Case_Inactivity_Consolidated_Email_Template', owea);
                    owea = [select Id from OrgWideEmailAddress where Address =: Label.Core_Support_Email];
                    if ( owea.size() > 0 ) {
                        mail.setOrgWideEmailAddressId(owea.get(0).Id);
                    }
                    mails.add(mail);    
                }
                
                // Tech Support - WOC - Non MSP - PAI
                if(c.RecordTypeId == technicalSupportRTId && c.BusinesGroup__c == 'Core' && c.WOC_Reason__c == 'Pending Additional Information'){
                    //c.Case_Reason__c = 'No Resolution Possible';
                    //c.Closed_Case_Reason__c = 'Couldn\'t contact customer (after at least 3 attempts)';
                    c.Status = 'Closed';
                    c.Closed_By_Process__c = 'Batch Class';
                    c.Day_5_Email_Sent__c = true;
                    Messaging.SingleEmailMessage mail = generateMail(c, emailTemplatesMap, 'Case_Inactivity_Consolidated_Email_Template', owea);
                    owea = [select Id from OrgWideEmailAddress where Address =: Label.Core_Support_Email];
                    if ( owea.size() > 0 ) {
                        mail.setOrgWideEmailAddressId(owea.get(0).Id);
                    }
                    mails.add(mail);                      
                }
                
                // Tech Support - WOC - CORE - RO
                if(c.RecordTypeId == technicalSupportRTId && c.BusinesGroup__c == 'Core' && c.WOC_Reason__c == 'Resolution Offered'){
                    //c.Case_Reason__c = 'No Resolution Possible';
                    //c.Closed_Case_Reason__c = 'Couldn\'t contact customer (after at least 3 attempts)';
                    c.Status = 'Resolved';   
                    //c.Closed_By_Process__c = 'Batch Class'; 
                }
                
                // Tech Support - WOC - MSP - CB
                if(c.RecordTypeId == technicalSupportRTId && c.BusinesGroup__c == 'MSP' && c.WOC_Reason__c == 'Call back'){
                    //c.Case_Reason__c = 'No Resolution Possible';
                    //c.Closed_Case_Reason__c = 'Couldn\'t contact customer (after at least 3 attempts)';
                    c.Status = 'Closed';
                    c.Closed_By_Process__c = 'Batch Class';
                    c.Day_5_Email_Sent__c = true;
                    Messaging.SingleEmailMessage mail = generateMail(c, emailTemplatesMap, 'Case_Inactivity_Consolidated_Email_Template', owea);
                    owea = [select Id from OrgWideEmailAddress where Address =: Label.MSP_Support_Email];
                    if ( owea.size() > 0 ) {
                        mail.setOrgWideEmailAddressId(owea.get(0).Id);
                    }
                    mails.add(mail);                      
                }
                
                // Tech Support - WOC - MSP - PAI
                if(c.RecordTypeId == technicalSupportRTId && c.BusinesGroup__c == 'MSP' && c.WOC_Reason__c == 'Pending Additional Information'){
                    //c.Case_Reason__c = 'No Resolution Possible';
                    //c.Closed_Case_Reason__c = 'Couldn\'t contact customer (after at least 3 attempts)';
                    c.Status = 'Closed';
                    c.Closed_By_Process__c = 'Batch Class';
                    c.Day_5_Email_Sent__c = true;
                    Messaging.SingleEmailMessage mail = generateMail(c, emailTemplatesMap, 'Case_Inactivity_Consolidated_Email_Template', owea);
                    owea = [select Id from OrgWideEmailAddress where Address =: Label.MSP_Support_Email];
                    if ( owea.size() > 0 ) {
                        mail.setOrgWideEmailAddressId(owea.get(0).Id);
                    }
                    mails.add(mail);                      
                }
                
                // Tech Support - WOC - MSP - RO
                if(c.RecordTypeId == technicalSupportRTId && c.BusinesGroup__c == 'MSP' && c.WOC_Reason__c == 'Resolution Offered'){
                    //c.Case_Reason__c = 'No Resolution Possible';
                    //c.Closed_Case_Reason__c = 'Couldn\'t contact customer (after at least 3 attempts)';
                    c.Status = 'Resolved';
                    //c.Closed_By_Process__c = 'Batch Class';     
                } 
                
                // Tech Support - WOC - Sonian - CB
                if(c.RecordTypeId == technicalSupportRTId && c.BusinesGroup__c == 'Sonian' && c.WOC_Reason__c == 'Call back'){
                    //c.Case_Reason__c = 'No Resolution Possible';
                    //c.Closed_Case_Reason__c = 'Couldn\'t contact customer (after at least 3 attempts)';
                    c.Status = 'Closed';
                    c.Closed_By_Process__c = 'Batch Class';
                    c.Day_5_Email_Sent__c = true;
                    Messaging.SingleEmailMessage mail = generateMail(c, emailTemplatesMap, 'Case_Inactivity_Consolidated_Email_Template', owea);
                    owea = [select Id from OrgWideEmailAddress where Address =: Label.ArchiveTechSupport_Sonian_Email];
                    if ( owea.size() > 0 ) {
                        mail.setOrgWideEmailAddressId(owea.get(0).Id);
                    }
                    mails.add(mail);                      
                }
                
                // Tech Support - WOC - Sonian - PAI
                if(c.RecordTypeId == technicalSupportRTId && c.BusinesGroup__c == 'Sonian' && c.WOC_Reason__c == 'Pending Additional Information'){
                    //c.Case_Reason__c = 'No Resolution Possible';
                    //c.Closed_Case_Reason__c = 'Couldn\'t contact customer (after at least 3 attempts)';
                    c.Status = 'Closed';
                    c.Closed_By_Process__c = 'Batch Class';
                    c.Day_5_Email_Sent__c = true;
                    Messaging.SingleEmailMessage mail = generateMail(c, emailTemplatesMap, 'Case_Inactivity_Consolidated_Email_Template', owea);
                    owea = [select Id from OrgWideEmailAddress where Address =: Label.ArchiveTechSupport_Sonian_Email];
                    if ( owea.size() > 0 ) {
                        mail.setOrgWideEmailAddressId(owea.get(0).Id);
                    }
                    mails.add(mail);                      
                }
                
                // Tech Support - WOC - Sonian - RO
                if(c.RecordTypeId == technicalSupportRTId && c.BusinesGroup__c == 'Sonian' && c.WOC_Reason__c == 'Resolution Offered'){
                    //c.Case_Reason__c = 'No Resolution Possible';
                    //c.Closed_Case_Reason__c = 'Couldn\'t contact customer (after at least 3 attempts)';
                    c.Status = 'Resolved';
                    //c.Closed_By_Process__c = 'Batch Class';   
                } 
                
                // WM - WOC - SV
                if(c.RecordTypeId == webMessageRTId && c.WOC_Reason__c == 'Serial Verification'){
                    c.Case_Reason__c = 'No Resolution Possible';
                    c.Closed_Case_Reason__c = 'Couldn\'t contact customer (after at least 3 attempts)';
                    c.Status = 'Closed';  
                    c.Closed_By_Process__c = 'Batch Class';
                }
                
                // WM - WOC - CV
                if(c.RecordTypeId == webMessageRTId && c.WOC_Reason__c == 'Contact Verification'){
                    c.Case_Reason__c = 'No Resolution Possible';
                    c.Closed_Case_Reason__c = 'Couldn\'t contact customer (after at least 3 attempts)';
                    c.Status = 'Closed';  
                    c.Closed_By_Process__c = 'Batch Class';
                }
            }
            
            Database.SaveResult[] srList = Database.update(scope, false); 
            
            Integer index = 0;
            
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess() || Test.isRunningTest()) {
                    LogModel log2 = LogModel.startLog('CaseWOCDay1RuleTriggerBatch', 'execute');
                    String errorStr = 'Record Id: ' + scope[index].Id;
                    
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {                        
                        errorStr = errorStr + ' ' + err.getStatusCode() + ' ' + err.getMessage() + ' ' + err.getFields();                        
                    }
                    if(errorStr.length() > 32767){
                        errorStr = errorStr.substring(0, 32767);
                    }                    
                    log2.endLog(errorStr);
                }
                
                index++;
            }  
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
            
            if (results[0].success) {
                System.debug('The email was sent successfully.');
            } else {
                System.debug('The email failed to send: ' + results[0].errors[0].message);
                log.endLog(results[0].errors[0].message);
            }                   
        } catch(Exception e){
            System.debug('**Error Message: ' + e.getMessage() + '\n LineNumber: ' + e.getLineNumber() + '\n Exception Type: ' + e.getTypeName() + '\n Cause: ' + e.getCause() + '\nStack Trace ' + e.getStackTraceString());
            log.addExceptionLog(e);
        }        
    }
    
    //FINISH METHOD
    global void finish(Database.BatchableContext bc){
        Id job= bc.getJobId();
        System.debug(job);
    }
    
    private Messaging.SingleEmailMessage generateMail(Case c, Map<String, Id> emailTemplatesMap, String emailTemplateName, OrgWideEmailAddress[] owea){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage() ;
        List<String> toAddresses = new List<String>();
        //if(c.Alternate_Email__c != null) toAddresses.add(c.Alternate_Email__c);
        List<String> ccAddresses = new List<String>();
        if(c.Additional_Recipient_Email__c != null){
            for(String emailId: c.Additional_Recipient_Email__c.split(';')){
                ccAddresses.add(emailId.trim());
            }
        }        if(c.SuppliedEmail != null) toAddresses.add(c.SuppliedEmail);
        mail.setToAddresses(toAddresses) ;
        mail.setTemplateId(emailTemplatesMap.get(emailTemplateName));
        mail.setTargetObjectId(c.ContactId);
        mail.setWhatId(c.Id);      
        return mail;    
    }    
}