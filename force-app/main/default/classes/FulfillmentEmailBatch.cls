/**
* @author Salesforce Services
* @date 07/15/2020
*
* @group Batch
*
* @description: Batch job to send license token and tracking information for orders
*/

global class FulfillmentEmailBatch implements Database.Batchable<sObject>,Schedulable, Database.Stateful {
    //Stateful processedOrderIds to prevent sending email for the same Order in multiple batches
    private Set<Id> processedOrderIds = new Set<Id>();

    //Start method
    global Database.QueryLocator start(Database.BatchableContext BC){        
        String query='SELECT id,Order__c,Order__r.ShipToContactId, Order__r.EffectiveDate'+
                     ' FROM Serial__c' +
                     ' WHERE Order__c != null' +
                     ' AND Send_Fulfillment_Email__c = True' +
                     ' AND Business_Group__c = \'MSP\'' + 
                     ' AND (Order__r.EffectiveDate = LAST_N_DAYS:7 OR Order__r.EffectiveDate = NEXT_N_DAYS:3)';
        return Database.getQueryLocator(query);
    }

    //Execute
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        LogModel log = LogModel.startLog(
                'FulfillmentEmailBatch',
                'Processing fulfillment email batches'
        );
        try{
            //List of serials to be updated to reset the flag
            List<Serial__c> serialUpdateList = new List<Serial__c>();

            //Set of Order Id for which email message has already been created
            Set<Id> orderEmailSet = new Set<Id>();

            //Additional CC address
            List<String> ccAddresses = new List<String>();

            //Additional BCC address
            List<String> bccAddresses = new List<String>();

            //Get template Id for sending CPQ Fulfillment emails
            List<EmailTemplate> fulfillmentTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'CPQ_Shipment_Confirmation' LIMIT 1];

            //Get Org Wide email address
            List<OrgWideEmailAddress> emailSender = [SELECT Id from OrgWideEmailAddress WHERE Address = 'partnermanagement@barracuda.com' LIMIT 1];

             //List of singlemailmessage
            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

            //Loop through metadata to determine additional emails
            for(Additional_Email_Address__mdt additionalEmail : [SELECT Email__c,
                                                                       Email_Type__c
                                                                FROM Additional_Email_Address__mdt 
                                                                WHERE Active__c = true 
                                                                AND Email_Application__c = 'Order Fulfillment'
                                                                AND Email_Type__c in ('CC', 'BCC')]){
                if(additionalEmail.Email_Type__c == 'CC'){
                    ccAddresses.add(additionalEmail.Email__c);
                }
                else if(additionalEmail.Email_Type__c == 'BCC'){
                    bccAddresses.add(additionalEmail.Email__c);
                }                                      
            }

            for(Serial__c serial: (List<Serial__c>)scope){
               if(serial.Order__c != null){
                    //Reset the flag
                    serialUpdateList.add(new Serial__c(Id = serial.id, Send_Fulfillment_Email__c = false));

                    if(!processedOrderIds.contains(serial.Order__c) && 
                       !orderEmailSet.contains(serial.Order__c)){
                        //Prepare email message
                        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            
                        //Set Target Object
                        emailMessage.setTargetObjectId(serial.Order__r.ShipToContactId);
            
                        //Set Template Id
                        emailMessage.setTemplateId(fulfillmentTemplate[0].Id);

                        //Set Template Id
                        emailMessage.setWhatId(serial.Order__c);         

                        //Set sender address
                        emailMessage.setOrgWideEmailAddressId(emailSender[0].Id);

                        //Set additional cc address
                        if(ccAddresses!=null && !ccAddresses.isEmpty()){
                            emailMessage.setCcAddresses(ccAddresses);
                        }
                        
                        //Set additional bcc address
                        if(bccAddresses!=null && !bccAddresses.isEmpty()){
                            emailMessage.setBccAddresses(bccAddresses);
                        }

                        //Add it to the list
                        emailMessages.add(emailMessage);

                        //Add Order Id to processedOrderIds and OrderEmailSet
                        processedOrderIds.add(serial.Order__c);
                        orderEmailSet.add(serial.Order__c);

                        //Add log message 
                        log.addLog('Email Message: Order Id - ' + serial.Order__c + ' ' + 'Contact Id - ' + serial.Order__r.ShipToContactId);
                    }
                }
            }
            
            //If email messages are present then send emails
            if(emailMessages!=null && !emailMessages.isEmpty()){
                Messaging.SendEmailResult[] emailResults = Messaging.sendEmail(emailMessages, false);

                //Loop through errors to log them for troubleshooting
                for(Messaging.SendEmailResult result: emailResults){
                    if(!result.isSuccess()){
                        String errormessage = '';
                        for(Messaging.SendEmailError error:result.getErrors()){
                            errormessage += error.getMessage() + ' Object Id: ' + error.getTargetObjectId();
                        }
                        log.addLog(errormessage);
                    }
                }                
            }

            //Update serials to reset the flag
            withoutSharingDML.save(serialUpdateList);

            //End log
            log.endLog('End of FulfillmentEmailBatch log');

        }
        catch(System.DmlException de){
            System.debug('Exception updating serials' +  de.getMessage());
        }
        catch(Exception e){
            log.addExceptionLog(e);
        }
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC){}

    //Schedulable execute method
    global void execute(SchedulableContext sc){
        Database.executeBatch(new FulfillmentEmailBatch(),1000);
    }           
}