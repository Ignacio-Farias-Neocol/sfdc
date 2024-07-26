global class PremiumSupportNotification 
{
    global static void sendEmail(EmailMessage em, String fromAddressNew) {	
        System.debug('###PremiumSupportEmailAlert:::');
        LogModel log = LogModel.startLog('PremiumSupportNotification', 'sendEmail');
        try {
            String toAddr = '';
            String groupDevName = '';
            List<Messaging.SingleEmailMessage> lEmails = new List<Messaging.SingleEmailMessage>();
            OrgWideEmailAddress fromAddr = [select Id,DisplayName,Address from OrgWideEmailAddress where Address = 'donotreply@barracuda.com' LIMIT 1];
            List<Case> caseList = [Select Id, OwnerId, CaseNumber, Subject from Case where Id =: em.ParentId];  
            
            Id americaQueueId;
            Id indiaQueueId;
            Id emeaQueueId;        
            
            List<Boolean> boolList = new List<Boolean>();
            Map<Id, Group> groupMap = new Map<Id, Group>([Select Id, Name, DeveloperName, Type from Group 
                                                          where Type = 'Queue' and DeveloperName in 
                                                          ('Contact_Center_Americas', 'Contact_Center_EMEA', 
                                                           'Contact_Center_India')]);
            for(Group groupRecord: groupMap.values()){
                if(groupRecord.DeveloperName == 'Contact_Center_Americas'){
                    americaQueueId = groupRecord.Id;
                } else if(groupRecord.DeveloperName == 'Contact_Center_EMEA'){
                    emeaQueueId = groupRecord.Id;
                } else if(groupRecord.DeveloperName == 'Contact_Center_India'){
                    indiaQueueId = groupRecord.Id;
                } 
            }
            
            Map<String, Set<String>> fromAddressMap = new Map<String, Set<String>>();
            for(Case_From_Address_New__mdt cfa: [Select DeveloperName, Email_Address__c from Case_From_Address_New__mdt]){
                if(String.isBlank(cfa.Email_Address__c)) continue;
                List<String> emailAddressList = cfa.Email_Address__c.split(';');                       
                fromAddressMap.put(cfa.DeveloperName, new Set<String>(emailAddressList));
            }            
            
            for(Case caseRecord :caseList){
                //Case caseRecord = caseList[0];
                Boolean returnBoolean = false;
                System.debug('##caseRecord:: ' + JSON.serialize(caseRecord));
                List<String> fromAddressList=new List<String>();
                // String fromAddress = caseRecord.From_Address__c; SFDC-13763
                // String fromAddress = caseRecord.From_Address_New__c;
                if(String.isNotEmpty(fromAddressNew) && String.isNotBlank(fromAddressNew))
                {
                    fromAddressList = fromAddressNew.split(';');
                    
                    Set<String> fromAddressSet = new Set<String>();
                    for(String addressStr: fromAddressList){
                        addressStr = addressStr.toLowerCase();
                        fromAddressSet.add(addressStr.trim());
                    }                                        
                    
                    System.debug('##fromAddressSet:: ' + fromAddressSet);                                                         
                    if(caseRecord.OwnerId == americaQueueId){
                        for(String incomingEmailAddress: fromAddressSet){
                            if(fromAddressMap.get('premiumsupport_team_barracuda_com').contains(incomingEmailAddress)){
                                groupDevName = 'Americas_Premium';
                            }                             
                        }
                    } else if(caseRecord.OwnerId == emeaQueueId){
                        for(String incomingEmailAddress: fromAddressSet){
                            if(fromAddressMap.get('emeapremiumsupport_team_barracuda_com').contains(incomingEmailAddress)){
                                groupDevName = 'EMEA_Premium';
                            }                             
                        }           
                    } else if(caseRecord.OwnerId == indiaQueueId){
                        for(String incomingEmailAddress: fromAddressSet){
                            if(fromAddressMap.get('wafpremium_team_barracuda_com').contains(incomingEmailAddress)){
                                groupDevName = 'India_Premium';
                            }                             
                        }            
                    }
                }  
            }
            
            system.debug('####em:::' + JSON.serialize(em));
            System.debug('##groupDevName:: ' + groupDevName);                    
            
            if(String.isBlank(groupDevName)){
                String incomingEmailIds = em.FromAddress;
                if(incomingEmailIds.contains(';') && incomingEmailIds.contains('premiumsupport_team')){                            
                    if(caseList.size() > 0){
                        String ownerIdString = caseList[0].OwnerId;
                        if(ownerIdString.startsWith('00G')){
                            groupDevName = [Select Id, DeveloperName from Group where Id =: caseList[0].OwnerId].DeveloperName;
                            if(groupDevName == 'Contact_Center_Americas'){
                                groupDevName = 'Americas_Premium';
                            } else if(groupDevName == 'Contact_Center_EMEA'){
                                groupDevName = 'EMEA_Premium';
                            } else if(groupDevName == 'Contact_Center_India'){
                                groupDevName = 'India_Premium';
                            }
                        }
                    }
                }
            }					
            
            System.debug('##groupDevName:: ' + groupDevName);
            
            
            String groupMemQry = 'SELECT GroupId,Id,UserOrGroupId FROM GroupMember where Group.DeveloperName =:groupDevName';
            Group groupRecord = [Select Id from Group where DeveloperName =: groupDevName];
            
            // Send bell notification
            Messaging.CustomNotification obj = new Messaging.CustomNotification();
            List<CustomNotificationType> notificationTypeList = [SELECT Id, CustomNotifTypeName, DeveloperName from CustomNotificationType where CustomNotifTypeName = 'Chatter Post'];
            obj.setNotificationTypeId(notificationTypeList[0].Id);
            obj.setTargetId(em.Id);
            obj.setTitle('New Premium Support Web Message – Case ' + em.CaseNumber__c);
            String strBody = 'From Address : ' + em.FromAddress + '\n' + 'Case Number : ' + em.CaseNumber__c + '\n' + 'Subject : ' + em.Subject;
            obj.setBody(strBody);                    
            Set<String> groupIdSet = new Set<String>{groupRecord.Id};
                obj.send(groupIdSet);             
            
            
            Set<Id> sToAddrUsers = new Set<Id>();
            for(GroupMember gm:Database.query(groupMemQry)) {
                if(String.valueof(gm.UserOrGroupId).startsWith('005')) {
                    sToAddrUsers.add(gm.UserOrGroupId);
                }
            }
            
            system.debug('To Address:'+sToAddrUsers.size());
            List<String> sToAddr = new list<String>();
            for(User u:[SELECT Id,Name,Email FROM User WHERE Id IN:sToAddrUsers]) {
                if(String.isNotBlank(u.Email)) {
                    sToAddr.add(u.Email);
                }    
            }
            
            system.debug('To Address Emails:'+sToAddr.size());
            System.debug('##toAddresses:: ' + JSON.serialize(sToAddr));
            
            //EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where Name = 'Premium Notifications for Web Messages' LIMIT 1];		
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String[] sendingTo = sToAddr;
            email.setOrgWideEmailAddressId(fromAddr.Id);
            email.setToAddresses(sendingTo);
            email.setBccSender(false);
            //email.setTargetObjectId(UserInfo.getUserId());
            //email.setTemplateID(emailTemplate.Id);  //Template will not work as the WHAT_ID isn't supports EmailMessage
            String emailSubject = 'New Premium Support Web Message – Case #' +em.CaseNumber__c;
            email.setSubject(emailSubject);
            String emailBody = '<ul>'+
                '<li> Email Subject: ' +em.subject+'</li>'+
                '<li> Case Number: ' +em.CaseNumber__c+'</li>'+
                '<li> From Address: ' +em.FromAddress+'</li>'+
                '</ul>';
            email.setHtmlBody(emailBody);
            //email.setWhatId(inp[0].CaseId);	
            lEmails.add(email);
            system.debug('Print lEmails:'+lEmails.size());
            
            Messaging.sendEmail(lEmails);
            
            //updateCase(inp[0].CaseId);
            
        }catch(Exception e) {
            system.debug('@@Error sending notif: '+e.getMessage());
            System.debug('**Error Message: ' + e.getMessage() + '\n LineNumber: ' + e.getLineNumber() + '\n Exception Type: ' + e.getTypeName() + '\n Cause: ' + e.getCause() + '\nStack Trace ' + e.getStackTraceString());
            log.addExceptionLog(e);
        }
    }
}