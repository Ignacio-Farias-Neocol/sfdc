/**
* @author IY
* @date 2019
*
* @group DynmaicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to notify customer service team when order sync failed
*
*
*
*
*/
public with sharing class DynamicBusinessRuleNotifyFailSync implements DynamicBusinessRuleAction {

    /*******************************************************************************************************
    * @description  create assigned serial for new subscriptions
    * @param trigger.new map
    * @return none, the result should be set to the records itself
    * @example
    */

    List<Messaging.SingleEmailMessage> messagesToSend = new List<Messaging.SingleEmailMessage>();
    public void processRecords(Map<Id,SObject> newRecordMap,  Map<Id,SObject> oldRecordMap,
            List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {

        LogModel log = LogModel.startLog('DynamicBusinessRuleNotifyFailSync', 'processRecords');

        System.debug('DynamicBusinessRuleNotifyFailSync records:' + records);
       // try {

            Set <Id> orderIds = new Set <Id>();
            Set<Id> PAMorderIds = new Set<Id>();
            Map<Id,Integration_Snapshot__c> pamIntegrationSnapshotByOrderId = new Map<Id, Integration_Snapshot__c>();
            Set<Id> BOSorderIds = new Set<Id>();
            Map<Id,Integration_Snapshot__c> bosIntegrationSnapshotByOrderId = new Map<Id, Integration_Snapshot__c>();
            Set<Id> ECHOorderIds = new Set<Id>();
            Map<Id,Integration_Snapshot__c> echoIntegrationSnapshotByOrderId = new Map<Id, Integration_Snapshot__c>();
            Set<Id> NetsuiteorderIds = new Set<Id>();
            Map<Id,Integration_Snapshot__c> netsuiteIntegrationSnapshotByOrderId = new Map<Id, Integration_Snapshot__c>();
            Set<Id> ZABorderIds = new Set<Id>();
            Map<Id,Integration_Snapshot__c> zabIntegrationSnapshotByOrderId = new Map<Id, Integration_Snapshot__c>();
            // JSON string of email (list) as json parameters
            String listOfEmails = (String)JSON.deserialize(jsonParameter, String.class);
            List <String> emails = listOfEmails.split(',');

            for (SObject obj : records) {
                Integration_Snapshot__c s = (Integration_Snapshot__c) obj;
                if (s.Object_Name__c == 'Order' && s.Sync_Status__c != null && s.Sync_Status__c.contains('Fail') ){
                    orderIds.add(s.Record_ID__c);

                    /*if(s.System_Name__c == 'PAM'){
                        PAMorderIds.add(s.Record_ID__c);
                        pamIntegrationSnapshotByOrderId.put(s.Record_ID__c, s);
                    }*/
                    System.debug('System_Name__c...'+s.System_Name__c);
                    switch on s.System_Name__c{
                        when 'PAM'{
                            PAMorderIds.add(s.Record_ID__c);
                            pamIntegrationSnapshotByOrderId.put(s.Record_ID__c, s);
                        }
                        when 'BOS'{
                            BOSorderIds.add(s.Record_ID__c);
                            bosIntegrationSnapshotByOrderId.put(s.Record_ID__c, s);
                        }
                        when 'Netsuite'{
                            NetsuiteorderIds.add(s.Record_ID__c);
                            netsuiteIntegrationSnapshotByOrderId.put(s.Record_ID__c, s);
                        }
                        when 'ZAB'{
                            ZABorderIds.add(s.Record_ID__c);
                            zabIntegrationSnapshotByOrderId.put(s.Record_ID__c, s);
                        }
                        when 'ECHO'{
                            ECHOorderIds.add(s.Record_ID__c);
                            echoIntegrationSnapshotByOrderId.put(s.Record_ID__c, s);
                        }
                    }
                }
            }

            Map <Id, Order> orderMap = new Map<Id, Order> ([select id, order.opportunity.reseller__c, order.opportunity.reseller__r.Name,
                    ordernumber, account.Name, owner.name, owner.email, LastModifiedDate, Status,
                    account.Terr_Theater__c, account.Terr_Region__c, Placed_Date__c , TotalAmount, Portal_Placed_Order__c, SBCF_Order_Type__c, (Select Id, Product2Id, Product2.Name, Product2.ProductCode from OrderItems) from Order  where id in :orderIds]);

            System.debug('#### emails: ' + emails);
            System.debug('#### orderIds: .' + orderIds);
            System.debug('#### orderMap: .' + orderMap);


            for (SObject obj : records) {
                Integration_Snapshot__c s = (Integration_Snapshot__c) obj;
                Order o = orderMap.get(s.Record_ID__c);
                if (o != null){
                        SendOrderEmail(s, o, emails);
                    }              
                }
            if(!messagesToSend.isEmpty()){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messagesToSend);
                if (results[0].success) {
                    System.debug('#### The email was sent successfully.');
                } else {
                    System.debug('#### The email failed to send: ' + results[0].errors[0].message);
                }
            }
            
            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
            Organization org = [select Id, IsSandbox from Organization limit 1];
            if(!PAMorderIds.isEmpty()){
                List<PAM_Order_Notification__mdt> pamNotificationSettings = [Select Id, DeveloperName, Type__c, Value__c from PAM_Order_Notification__mdt];
                Set<String> prodCodesForNotifications = new Set<String>();
                List<String> emailAddressForNotifications = new List<String>();

                for(PAM_Order_Notification__mdt notificationSetting : pamNotificationSettings){
                    if(notificationSetting.Type__c == 'Notification Email'){
                        emailAddressForNotifications.add(notificationSetting.Value__c);
                    }
                    if(notificationSetting.Type__c == 'Product Code'){
                        prodCodesForNotifications.add(notificationSetting.Value__c);
                    }
                }

                
                for(String oId : PAMorderIds){
                    Order pamOrder = orderMap.get(oId);
                    Integration_Snapshot__c iSnapshot = pamIntegrationSnapshotByOrderId.get(oId);
                    if(pamOrder.OrderItems != null && pamOrder.SBCF_Order_Type__c == 'New'){
                        for(OrderItem oItem : pamOrder.OrderItems){
                            if(prodCodesForNotifications.contains(oItem.Product2.ProductCode)){
                                emailMessages.add(createPAMFailureEmailNotification(pamOrder,iSnapshot,emailAddressForNotifications,org));
                                break;
                            }
                        }
                    }
                }     
            }
            List<Failed_Sync_Notification__mdt> failedNotificationSettings = [Select Id, DeveloperName, Email_Address__c from Failed_Sync_Notification__mdt];
            if(!BOSorderIds.isEmpty()){
                Boolean emailExist = true;
                System.debug('BOSorderIds...'+BOSorderIds);
                List<String> emailAddressForNotifications = new List<String>();
                for(Failed_Sync_Notification__mdt notificationSetting : failedNotificationSettings){
                    if(notificationSetting.DeveloperName == 'BOS'){
                        if(notificationSetting.Email_Address__c!=null){
                            System.debug('notificationSetting.Email_Address__c...'+notificationSetting.Email_Address__c);
                            String listOfEmails4 = (String)JSON.deserialize(notificationSetting.Email_Address__c, String.class);
                            List <String> emails4 = listOfEmails4.split(',');
                            emailAddressForNotifications.addAll(emails4);
                        }else{
                            emailExist = false;
                            System.debug('No Email for BOS');
                            log.addSummaryLog('No Email for BOS');
                        }
                        break;
                    }
                }
                if(emailExist){
                    for(String oId : BOSorderIds){
                        Order bosOrder = orderMap.get(oId);
                        Integration_Snapshot__c iSnapshot = bosIntegrationSnapshotByOrderId.get(oId);
                        emailMessages.add(createFailureEmailNotification(bosOrder,iSnapshot,emailAddressForNotifications,org,'BOS'));
                    }
                }
            }

            if(!NetsuiteorderIds.isEmpty()){
                Boolean emailExist = true;
                List<String> emailAddressForNotifications = new List<String>();
                for(Failed_Sync_Notification__mdt notificationSetting : failedNotificationSettings){
                    if(notificationSetting.DeveloperName == 'Netsuite'){
                        if(notificationSetting.Email_Address__c!=null){
                        String listOfEmails1 = (String)JSON.deserialize(notificationSetting.Email_Address__c, String.class);
                        List <String> emails1 = listOfEmails1.split(',');
                        emailAddressForNotifications.addAll(emails1);
                        }else{
                            emailExist = false;
                            System.debug('No Email for BOS');
                            log.addSummaryLog('No Email for BOS');
                        }
                        break;
                    }
                }
				if(emailExist){
                    for(String oId : NetsuiteorderIds){
                        Order netsuiteOrder = orderMap.get(oId);
                        Integration_Snapshot__c iSnapshot = netsuiteIntegrationSnapshotByOrderId.get(oId);
                        emailMessages.add(createFailureEmailNotification(netsuiteOrder,iSnapshot,emailAddressForNotifications,org,'Netsuite'));
                    }
                }
            }

            if(!ZABorderIds.isEmpty()){
                Boolean emailExist = true;
                List<String> emailAddressForNotifications = new List<String>();
                for(Failed_Sync_Notification__mdt notificationSetting : failedNotificationSettings){
                    if(notificationSetting.DeveloperName == 'ZAB'){
                        if(notificationSetting.Email_Address__c!=null){
                            if(notificationSetting.Email_Address__c!=null){
                                String listOfEmails2 = (String)JSON.deserialize(notificationSetting.Email_Address__c, String.class);
                                List <String> emails2 = listOfEmails2.split(',');
                                emailAddressForNotifications.addAll(emails2);
                            }else{
                            emailExist = false;
                            System.debug('No Email for BOS');
                            log.addSummaryLog('No Email for BOS');
                        }
                        break;
                        }
                        else{
                            emailExist = false;
                            System.debug('No Email for BOS');
                            log.addSummaryLog('No Email for BOS');
                        }
                        break;
                    }
                }
				if(emailExist){
                    for(String oId : ZABorderIds){
                        Order zabOrder = orderMap.get(oId);
                        Integration_Snapshot__c iSnapshot = ZABIntegrationSnapshotByOrderId.get(oId);
                        emailMessages.add(createFailureEmailNotification(zabOrder,iSnapshot,emailAddressForNotifications,org,'ZAB'));
                    }
                }
            }

            if(!ECHOorderIds.isEmpty()){
                Boolean emailExist = true;
                List<String> emailAddressForNotifications = new List<String>();
                for(Failed_Sync_Notification__mdt notificationSetting : failedNotificationSettings){
                    if(notificationSetting.DeveloperName == 'ECHO'){
                        String listOfEmails3 = (String)JSON.deserialize(notificationSetting.Email_Address__c, String.class);
                        List <String> emails3 = listOfEmails3.split(',');
                        emailAddressForNotifications.addAll(emails3);
                    }
                }
				if(emailExist){
                    for(String oId : ECHOorderIds){
                        Order ECHOOrder = orderMap.get(oId);
                        Integration_Snapshot__c iSnapshot = ECHOIntegrationSnapshotByOrderId.get(oId);
                        emailMessages.add(createFailureEmailNotification(ECHOOrder,iSnapshot,emailAddressForNotifications,org,'ECHO'));
                    }
                }
            }

            System.debug('emailMessages...'+emailMessages);
            if(!emailMessages.isEmpty()){
                if(!Test.isRunningTest()){
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(emailMessages);
                }
            }
            
       // } Catch (Exception e){
        //    System.debug('#### Exceptions: ' + e.getMessage());
        //    log.addExceptionLog(e);
        //}

    }


    /**
     *

body: Order # _________ has failed. Please review the Integration Status here (hyperlink to the order) and ensure that order is placed successfully.

- the Salesforce team


Report show the following:
integration status that has failed.
theater / region
order ID
link to order
account Name
reseller account
date placement
order amount
     *
     * @param order
     * @param addresses
     */
    @TestVisible
    private void SendOrderEmail(Integration_Snapshot__c s, Order o, List <String> addresses){

        system.debug('###EMAIL ' + addresses);
        Organization org = [select Id, IsSandbox from Organization limit 1];
        List<CommunityOrderSettings__mdt> portalOrderSettings = [Select Id , Community_Order_Integration_Error_Email__c from CommunityOrderSettings__mdt Where Community_Order_Integration_Error_Email__c != null];

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        if (addresses == null) {
            addresses = new List <String>();
        }

        if(o.Portal_Placed_Order__c == false){
            if(o.owner.email != null){
                addresses.add(o.owner.email);
            }
        }else{
            for(CommunityOrderSettings__mdt ordSetg : portalOrderSettings){
                system.debug('#####EMAIL2 : ' + ordSetg.Community_Order_Integration_Error_Email__c);
                if(ordSetg.Community_Order_Integration_Error_Email__c != null){
                    addresses.add(ordSetg.Community_Order_Integration_Error_Email__c);
                }
            }
            
        }

        message.toAddresses = addresses;
        // message.optOutPolicy = 'FILTER';
        message.subject = 'ACTION REQUIRED: Order ' + o.OrderNumber + ' failed to sync with '  + s.System_Name__c ; // + (org.IsSandbox ? ' (Sandbox Env)': '');


        String messageBody = '';
        messageBody += 'Order # ' + o.OrderNumber + ' has failed. Please review the Integration Status here ' + URL.getOrgDomainUrl().toExternalForm() + '/' + o.id + ' and ensure that order is placed successfully. \n\n';


        if (org.IsSandbox){
            messageBody += 'Sandbox: ' + org.Id + '\n';
        }
        messageBody += 'Target System: ' + s.System_Name__c + '\n';
        messageBody += 'Salesforce Order : ' + o.OrderNumber + '\n';
        messageBody += 'Date Placed: ' + o.Placed_Date__c + '\n';
        messageBody += 'Account : ' + o.account.Name + '\n';
        if (String.isNotBlank(o.opportunity.reseller__r.Name)){
            messageBody += 'Reseller : ' + o.opportunity.reseller__r.Name + '\n';
        }
        messageBody += 'Theater: ' + o.account.Terr_Theater__c + '\n';
        messageBody += 'Region: ' + o.account.Terr_Region__c + '\n';
        messageBody += 'Order Amount: ' + o.TotalAmount + '\n';
        messageBody += 'Order Sync Status: ' + s.Sync_Status__c + '\n';
        messageBody += 'Order Onwer: ' + o.owner.name + '\n';
        messageBody += 'Sync Status Detail : \n';
        messageBody +=  s.Message_Payload__c;

        messageBody += '\n\n - the Salesforce team \n';

        message.plainTextBody = messageBody;
        system.debug('###TOADDRESSES : ' +  message.toAddresses);
        messagesToSend.add(message);
        //Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        //Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

       /* if (results[0].success) {
            System.debug('#### The email was sent successfully.');
        } else {
            System.debug('#### The email failed to send: ' + results[0].errors[0].message);
        }*/

    }

    private Messaging.SingleEmailMessage createPAMFailureEmailNotification(Order pamOrder, Integration_Snapshot__c iSnapshot, List<String> emailAddressForNotifications, Organization org){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = emailAddressForNotifications;
        message.subject = 'ACTION REQUIRED: Order ' + pamOrder.OrderNumber + ' failed to sync with PAM';
        String messageBody = '';
        messageBody += 'Order # ' + pamOrder.OrderNumber + ' has failed for PAM. Please review the Integration Status here ' + URL.getOrgDomainUrl().toExternalForm() + '/' + pamOrder.id + ' and ensure that order is placed successfully. \n\n';
        if (org.IsSandbox){
            messageBody += 'Sandbox: ' + org.Id + '\n';
        }
        messageBody += 'Integration Snapshot Name : ' + iSnapshot.Name + '\n';
        messageBody += 'System Name : PAM' + '\n';
        messageBody += 'Integration App : ' + iSnapshot.Integration_App__c + '\n';
        messageBody += 'Status : ' + pamOrder.Status + '\n';
        messageBody += 'Record ID : ' + pamOrder.Id + '\n';
        messageBody += 'LastModifiedDate : ' + pamOrder.LastModifiedDate + '\n';
        messageBody += 'External ID : ' + iSnapshot.External_ID__c + '\n';
        messageBody += 'Integration Snapshot ID :' + iSnapshot.Id + '\n';
        messageBody += 'Message Payload : ' + iSnapshot.Message_Payload__c + '\n';

        messageBody += '\n\n - the Salesforce team \n';

        message.plainTextBody = messageBody;

        return message;
    }

    private Messaging.SingleEmailMessage createFailureEmailNotification(Order failedOrder, Integration_Snapshot__c iSnapshot, List<String> emailAddressForNotifications, Organization org, String systemName){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = emailAddressForNotifications;
        message.subject = 'ACTION REQUIRED: Order ' + failedOrder.OrderNumber + ' failed to sync with '+systemName;
        String messageBody = '';
        messageBody += 'Order # ' + failedOrder.OrderNumber + ' has failed for '+systemName+'. Please review the Integration Status here ' + URL.getOrgDomainUrl().toExternalForm() + '/' + failedOrder.id + ' and ensure that order is placed successfully. \n\n';
        if (org.IsSandbox){
            messageBody += 'Sandbox: ' + org.Id + '\n';
        }
        messageBody += 'Integration Snapshot Name : ' + iSnapshot.Name + '\n';
        messageBody += 'System Name : '+systemName + '\n';
        messageBody += 'Integration App : ' + iSnapshot.Integration_App__c + '\n';
        messageBody += 'Status : ' + failedOrder.Status + '\n';
        messageBody += 'Record ID : ' + failedOrder.Id + '\n';
        messageBody += 'LastModifiedDate : ' + failedOrder.LastModifiedDate + '\n';
        messageBody += 'External ID : ' + iSnapshot.External_ID__c + '\n';
        messageBody += 'Integration Snapshot ID :' + iSnapshot.Id + '\n';
        messageBody += 'Message Payload : ' + iSnapshot.Message_Payload__c + '\n';

        messageBody += '\n\n - the Salesforce team \n';

        message.plainTextBody = messageBody;

        return message;
    }

}