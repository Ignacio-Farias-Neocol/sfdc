public class  SendOrderTrackingEmailController {
    @auraEnabled
    public static ErrorOrSuccessResponse sendEmailMessge(String userName, String recordId){
        List<String> lstOfEmailAddresses = userName.split(',');
        Set<String> setOfEmailAddresses = new Set<String>(lstOfEmailAddresses);
        Map<String, Contact> mapofContactsWithEmailAddresses = new Map<String, Contact>();
        
        for(Contact con : [SELECT Id, Email FROM Contact WHERE Email IN: setOfEmailAddresses]){
            mapofContactsWithEmailAddresses.put(con.Email, con);
        }
        
        List <Messaging.SingleEmailMessage> mailList = new List <Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail;
        Contact con;
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'CPQ_Order_Tracking_Details'];
        String errorMsg = 'No Contact exists in Salesforce for the following email address(es): ';
        List<String> lstOfContactNotFoundEmailAddresses = new List<String>();
        Map<Id, String> mapOfConIdWithEmailAddress = new Map<Id, String>();
        for(String emailAddress : setOfEmailAddresses){
            if(mapofContactsWithEmailAddresses.keyset().contains(emailAddress)){
                con = mapofContactsWithEmailAddresses.get(emailAddress);
                mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(et.id);
                mail.setWhatId(recordId);
                mail.setTargetObjectId(con.Id);
                mail.setSaveAsActivity(true);
                mailList.add(mail);
                mapOfConIdWithEmailAddress.put(con.Id, emailAddress);
            }else{
                lstOfContactNotFoundEmailAddresses.add(emailAddress);
            }
        }
        
        if(!lstOfContactNotFoundEmailAddresses.isEmpty()){
            
            String emailAddressesNotFound = String.join(lstOfContactNotFoundEmailAddresses, ',');
            errorMsg += '<b>'+emailAddressesNotFound+'</b>'+'<br/>Please ensure a Contact is in the system with this email address. If a Contact exists in Salesforce and you are receiving this error message, please open an internal ticket.';
            
            return new ErrorOrSuccessResponse('500',errorMsg);
        }
        
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(mailList);
        errorMsg = '';
        for(Messaging.SendEmailResult res : results){
            if(!res.isSuccess()){
                errorMsg += mapOfConIdWithEmailAddress.get(res.getErrors()[0].TargetObjectId) + ':' + res.getErrors()[0].getMessage() + '\n';
            }
        }
        if(String.isNotBlank(errorMsg))
            return new ErrorOrSuccessResponse('500',errorMsg);
        
        return new ErrorOrSuccessResponse('200','Email Sent Successfully.');
    }
    
    public class ErrorOrSuccessResponse {
        @auraEnabled
        public String statusCode;
        @auraEnabled
        public String message;
        public ErrorOrSuccessResponse(String statusCode,String message){
            this.statusCode = statusCode;
            this.message = message;
        }
    }
}