global class SurveyResponseEmailService implements Messaging.InboundEmailHandler {
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env){
        
        System.debug('##CreateTaskEmailExample');
        System.debug('##email:: ' + JSON.serialize(email));
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        try {
            String myPlainText= '';    
            myPlainText = email.plainTextBody;
            Integer indexValue = myPlainText.indexOf('##$$##');
            String recId = myPlainText.substring(indexValue + 6, indexValue + 21);            
            EmailMessage emailMessage = new EmailMessage();
            emailMessage.status = '3'; // email was sent
            emailMessage.relatedToId = recId;
            emailMessage.fromAddress = email.fromAddress;
            emailMessage.fromName = email.fromName;
            emailMessage.subject = email.subject;
            emailMessage.htmlBody = email.htmlBody;
            //String[] toIds = new String[]{'0030I00002N4OTq'}; 
            //emailMessage.toIds = toIds;
            emailMessage.toAddress = email.toAddresses[0];
            insert emailMessage; // insert
        }
        catch (Exception e) {
            System.debug('Query Issue: ' + e.getMessage());
        }
        
        result.success = true;
        return result;
    }
}