/**
* @author Dilowar Hussain
* @date 2022-08-04
*
* @description 
* This Apex Class gets invoked by by the aura component, ResendOrderComfirmation. 
* This is the controller class.
*
* This has been added as a part of SFDC-14953
*/
public with sharing class ResendOrderNotificationController {
    /***************************
     * Method Description: 
     *  This method contains record validations required for ResendOrderComfirmation functionality.
     * 
     * @Param: String recordId
     * @return boolean
     */
    @AuraEnabled
    public static String checkResendOrderCriteria(String recordId){
        boolean isOrder = true;
        String billToConEmail = '';
        //try{
            if(String.isNotBlank(recordId)){
                
                for(Order eachO : [Select Id, Bill_To_Contact__c, BillToContactId, Bill_To_Contact_Email__c From Order Where Id =: recordId]){
                    //Check if the Order is already Cancelled.
                    if(!String.isNotBlank(eachO.Bill_To_Contact_Email__c)){
                        isOrder = false;
                        billToConEmail = '';
                        AuraHandledException e = new AuraHandledException(Label.Resend_Order_Bill_To_Email_Empty);
                        e.setMessage(Label.Resend_Order_Bill_To_Email_Empty);
                        throw e;
                    }else{
                        billToConEmail = eachO.Bill_To_Contact_Email__c;
                    }
                }
            }
        system.debug('isOrder ***'+ isOrder);
        system.debug('billToConEmail ***'+ billToConEmail);
        return billToConEmail; 
    }
     /***************************
     * Method Description: 
     *  This method invokes sending the confirmation email. 
     * The email template named as "CPQ_Order_Confirmation_Resend" has been used here.
     * 
     * @Param: String recordId
     * @return String
     */
    @AuraEnabled
    public static String resendNotification(String recordId){
        String emailStatus = '';
        String response = '';
        List<Order> lstOrder = new List<Order>();
        Map<Id, Order> mapOrder = new Map<Id, Order>();
        Map<String, String> mapEmailCon = new Map<String, String>();
        try {
            if(String.isNotBlank(recordId)){
                List<EmailTemplate> lstEmailTemplates = [SELECT Id, Body, Subject from EmailTemplate where DeveloperName = 'CPQ_Order_Confirmation'];
                List<User> loggedInUser = [select id, name, username from user where id  = :UserInfo.getUserId()];
                lstOrder = [Select Id, Bill_To_Contact__c, BillToContactId, Bill_To_Contact_Email__c From Order Where Id =: recordId];
                for(Order o : lstOrder){
                    mapOrder.put(o.id, o);
                }
                if(!mapOrder.isEmpty()){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    if(mapOrder.get(recordId).BillToContactId == NULL && mapOrder.get(recordId).Bill_To_Contact_Email__c != NULL){
                        List<contact> lstCon = [select id, name, email from Contact where email = :mapOrder.get(recordId).Bill_To_Contact_Email__c];
                        for(Contact con : lstCon){
                            mapEmailCon.put(con.email, con.id);
                        }
                    }
                    if(mapEmailCon.containsKey(mapOrder.get(recordId).Bill_To_Contact_Email__c)){
                        mail.setTargetObjectId(mapEmailCon.get(mapOrder.get(recordId).Bill_To_Contact_Email__c));// Any contact or User id of your record
                        mail.setSaveAsActivity(true);
                    }else{
                        mail.setTargetObjectId(loggedInUser[0].id);
                        mail.setSaveAsActivity(false);
                    }
                    mail.setTemplateId(lstEmailTemplates[0].Id);
                    mail.setToAddresses(new list<string>{mapOrder.get(recordId).Bill_To_Contact_Email__c});
                    mail.setWhatId(recordId); // Enter your record Id whose merge field you want to add in template
                    Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                    if (resultMail[0].isSuccess()) {
                        emailStatus = Label.Resend_Order_Confirm_Message;
                    } else {
                        emailStatus = Label.Resend_Order_Confirm_Error_Message;
                        response = resultMail[0].getErrors().get(0).getMessage();
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return emailStatus;
    }
}