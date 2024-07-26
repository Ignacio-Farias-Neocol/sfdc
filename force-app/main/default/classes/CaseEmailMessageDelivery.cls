public class CaseEmailMessageDelivery {
    
    @InvocableMethod(label='Send Email from Apex New')
    public static void sendEmail(List<FlowInputs> inputs) {
        System.debug('###inputs:: ' + JSON.serialize(inputs));
        LogModel log = LogModel.startLog('CaseEmailMessageDeliveryNew', 'sendEmail');
        try{
            // set to address
            List<String> toAddresses = new List<String>();               
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>(); 
            FlowInputs input = inputs[0];
            Case caseRecord = [Select Id, CaseNumber, Alt_Email_in_use__c, Alternate_Email__c,
                               Additional_Recipient_Email__c, SuppliedEmail, ContactEmail, ContactId from Case where Id =: input.caseId];
            if(String.isNotBlank(caseRecord.ContactEmail) && !caseRecord.Alt_Email_in_use__c){
                toAddresses.add(caseRecord.ContactEmail);
            }
            
            if(caseRecord.Alt_Email_in_use__c && String.isNotBlank(caseRecord.SuppliedEmail)){
                toAddresses.add(caseRecord.SuppliedEmail);
            } 
            
            Messaging.SingleEmailMessage mail = generateMail(caseRecord, input.emailTemplateName, toAddresses);
            mails.add(mail);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mails);
            
            if (results[0].success) {
                System.debug('The email was sent successfully.');
            } else {
                System.debug('The email failed to send: ' + results[0].errors[0].message);
                log.endLog(results[0].errors[0].message);
            }           
        } Catch(Exception e){
            System.debug('**Error Message: ' + e.getMessage() + '\n LineNumber: ' + e.getLineNumber() + '\n Exception Type: ' + e.getTypeName() + '\n Cause: ' + e.getCause() + '\nStack Trace ' + e.getStackTraceString());
            log.addExceptionLog(e);
        }           
    }
    
    private static Messaging.SingleEmailMessage generateMail(Case c, String emailTemplateName, List<String> toAddresses){
    	Map<String, EmailTemplate> emailTemplatesMap = new Map<String, EmailTemplate>();
    	List<OrgWideEmailAddress> owea = new List<OrgWideEmailAddress>();        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // get org wide email id
        owea = [select Id from OrgWideEmailAddress where Address =: Label.Core_Support_Email];
        if (owea.size() > 0) {
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
        }     
        
        // get email template id
        List<EmailTemplate> etList = [Select Id, Name, DeveloperName, Subject, Body from EmailTemplate where DeveloperName =: emailTemplateName];            
        for(EmailTemplate et: etList){
            emailTemplatesMap.put(et.DeveloperName, et);
        }
       
        List<String> ccAddresses = new List<String>();
        if(c.Additional_Recipient_Email__c != null){
            for(String emailId: c.Additional_Recipient_Email__c.split(';')){
                ccAddresses.add(emailId.trim());
            }
        } 
        mail.setCcAddresses(ccAddresses);
        // if(c.SuppliedEmail != null) toAddresses.add(c.SuppliedEmail);
        System.debug('####toAddresses::: ' + JSON.serialize(toAddresses));
        mail.setToAddresses(toAddresses) ;
        
        mail.setTemplateId(emailTemplatesMap.get(emailTemplateName).Id);
        mail.setTargetObjectId(c.ContactId);
        mail.setWhatId(c.Id); 
        mail.setTreatTargetObjectAsRecipient(false);
		return mail;        
    }    
    
    public class FlowInputs{
    
        @InvocableVariable
        public Id caseId;
        
        @InvocableVariable
        public String emailTemplateName;
        
    }    
}