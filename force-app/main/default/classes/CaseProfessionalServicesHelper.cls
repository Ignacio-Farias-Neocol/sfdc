public class CaseProfessionalServicesHelper {
    
    public static void createTaskOnCaseComment(List<WrapperObj> wrapperList){
        If(!TriggerContextVariables.RUN_CASE_TRIGGER){
            return;
        }                    
        List<Task> taskList = new List<Task>();
        CustomNotificationType notificationType = 
                [SELECT Id, DeveloperName 
                 FROM CustomNotificationType 
                 WHERE DeveloperName='Bell_Notif'];
                 
        OrgWideEmailAddress owa = [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = 'Do Not Reply @ Barracuda' limit 1];
            
                 
        for(WrapperObj obj: wrapperList){
            Task taskRecord = new Task();
            taskRecord.subject = 'Professional Service Portal Comment Posted';
            taskRecord.type = 'Portal Comment';
            taskRecord.status= 'Not Started';
            taskRecord.WhatId = obj.caseRec.Id;
            taskRecord.WhoId = obj.caseRec.ContactId;
            taskRecord.ActivityDate = System.today();
            taskRecord.OwnerId = obj.caseRec.OwnerId;
            taskList.add(taskRecord);           
            
            
            
            Messaging.CustomNotification notification = new Messaging.CustomNotification();

            if(String.valueOf(obj.caseRec.OwnerId).startsWith('00G')){
                notification.setTitle(' Professional Service Portal Comment Posted');
                notification.setBody('Case Owner: ' + obj.caseRec.Owner.Name + '\n' + ' Case Number: ' + obj.caseRec.caseNumber + '\n' + 'Account Name: ' + obj.caseRec.Account.Name + '\n' + 'Comment from portal: ' + obj.comment + '\n' + 'A Task has been assigned to you');                       
            } else {
                notification.setTitle('Professional Service Portal Comment Posted');
                notification.setBody('Case Number: ' + obj.caseRec.caseNumber + '\n' + 'Account Name: ' + obj.caseRec.Account.Name + '\n' + 'Comment from portal: ' + obj.comment + '\n' + 'A Task has been assigned to you');                   
            }            
     
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(obj.caseRec.Id);
            
            try {
                notification.send(new Set<String>{obj.caseRec.ownerId});
            }
            catch (Exception e) {
                System.debug('Problem sending notification: ' + e.getMessage());
            }   
            
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
            string emailBody = obj.caseRec.contact.Name + ' has responded via portal comment to case number ' + obj.caseRec.caseNumber + '\n' + 'Account Name: ' + obj.caseRec.Account.Name;
            emailBody = emailBody + '\n' + 'Due Date: ' + system.today();
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] { obj.caseRec.owner.email };
                message.subject = 'Professional Service Portal Comment Posted';
            message.plainTextBody = emailBody;
            message.setOrgWideEmailAddressId(owa.Id);
            
            messages.add(message);
            try{
                Messaging.sendEmail(messages);
            } catch(Exception e){
                System.debug('**Error Message: ' + e.getMessage() + '\n LineNumber: ' + e.getLineNumber() + '\n Exception Type: ' + e.getTypeName() + '\n Cause: ' + e.getCause() + '\nStack Trace ' + e.getStackTraceString());
            }            
        } 
        
        insert taskList;             
    }
    
    Public class WrapperObj{
        public Case caseRec;
        public String comment;
    }
}