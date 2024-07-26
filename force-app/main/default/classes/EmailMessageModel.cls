/**
* Created by iyeung on 1/11/19.

* @Modification
* SFDC-13763: Changed code to replace From_Address__c to From_Address_New__c
*/

global with sharing class EmailMessageModel implements Queueable {
    public sObject record;
    public static final String WEB_MESSAGE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Web_Case').getRecordTypeId(); // '0123C0000006R7kQAE';
    public static final String INTERNAL_COMMUNITY_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Community_Help').getRecordTypeId();
    public static final String TECHNICAL_SUPPORT_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();
    public static final String PARTNER_SUCCESS_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Partner_Success').getRecordTypeId();
    public static final String PROFESSIONAL_SERVICE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Professional_Services').getRecordTypeId();
    public static final Id INTERNAL_TICKET_QUEUE_ID  = [SELECT DeveloperName,Id,Name,Type FROM Group where DeveloperName='Internal_Ticket_Communities' AND Type='Queue' LIMIT 1].Id;    
    public static final Id PARTNER_SUCCESS_MSP_QUEUE_ID  = [SELECT DeveloperName,Id,Name,Type FROM Group where DeveloperName='Partner_Success_MSP_Queue' AND Type='Queue' LIMIT 1].Id;  
    public static final Id CONTACT_CENTER_EMEA_QUEUE_ID = [SELECT DeveloperName,Id,Name,Type FROM Group where DeveloperName='Contact_Center_EMEA' AND Type='Queue' LIMIT 1].Id; 
    public static final Id CONTACT_CENTER_INDIA_QUEUE_ID = [SELECT DeveloperName,Id,Name,Type FROM Group where DeveloperName='Contact_Center_India' AND Type='Queue' LIMIT 1].Id;
    public static final Id CONTACT_CENTER_AMERICAS_QUEUE_ID = [SELECT DeveloperName,Id,Name,Type FROM Group where DeveloperName='Contact_Center_Americas' AND Type='Queue' LIMIT 1].Id;
    
    public EmailMessageModel(sObject record){
        this.record=record;
    }
    public void execute(QueueableContext context) {
        try{ 
            EmailMessageModel.ProcessEmailRequest obj=new EmailMessageModel.ProcessEmailRequest();
            obj.emailMessage=(EmailMessage)record;
            EmailMessageModel.handleEmailClosedCase(new List<EmailMessageModel.ProcessEmailRequest> {obj});
        }catch(Exception ex){
            System.debug('Error: '+ex.getMessage ()+' Line No: '+ex.getLineNumber());
        }
        
    }
    
    global class ProcessEmailRequest {
        @InvocableVariable(
            label = 'Email Message'
            description = 'The Email Message that is being processed'
            required = true
        ) public EmailMessage emailMessage;
    }
    
    global class ProcessEmailReply {
        @InvocableVariable public Id existingCaseId;
        @InvocableVariable public Id newCaseId;
    }
    
    // 2019-07-20: add additional fields for web case
    /*  private static List <String> CLONE_CASE_FIELDS = new List <String>
{   'Origin', 'Priority', 'Web_Region__c', 'Web_Language_of_correspondence__c','RecordTypeId',
'Alert__c', 'Reason__c', 'preferred_Contact_Method__c', 'Serial__c', 'Client__c',
'Computer_ID__c', 'Computer_Name__c', 'Username__c', 'Is_Asset_Verified__c', 'Is_Premium_Support__c', 'From_Address__c', 'First_Queue_Id__c',
'Is_Enterprise_Account__c', 'Pick_Product_only_if_Essentials__c', 'ClosedDate', 'Case_Re_Opened__c',
'Product_Family_List__c', 'AccountId', 'ContactId', 'Is_Contact_Verified__c', 'Alternate_Email__c', 'Web_Serial__c',
'Related_Contact__c', 'URL__c', 'Web_Last_Name__c', 'Web_First_Name__c', 'SuppliedPhone', 'SuppliedEmail', 'SuppliedName',
'Related_Account__c', 'Subject', 'Description', 'Fix_Version__c', 'AssetId', 'EntitlementId', 'BusinesGroup__c', 'Source__c', 'OwnerId', 'owner.email',
'contact.Name', 'caseNumber', 'Account.Name'
}; */  //SFDC-13763
    
    private static List <String> CLONE_CASE_FIELDS = new List <String>
    {   'Origin', 'Priority', 'Web_Region__c', 'Web_Language_of_correspondence__c','RecordTypeId',
        'Alert__c', 'Reason__c', 'preferred_Contact_Method__c', 'Serial__c', 'Client__c',
        'Computer_ID__c', 'Computer_Name__c', 'Username__c', 'Is_Asset_Verified__c', 'Is_Premium_Support__c', 'From_Address_New__c', 'First_Queue_Id__c',
        'Is_Enterprise_Account__c', 'Pick_Product_only_if_Essentials__c', 'ClosedDate', 'Case_Re_Opened__c', 'Closed_By_Process__c',
        'Product_Family_List__c', 'AccountId', 'ContactId', 'Is_Contact_Verified__c', 'Alternate_Email__c', 'Web_Serial__c',
        'Related_Contact__c', 'URL__c', 'Web_Last_Name__c', 'Web_First_Name__c', 'SuppliedPhone', 'SuppliedEmail', 'SuppliedName',
        'Related_Account__c', 'Subject', 'Description', 'Fix_Version__c', 'AssetId', 'EntitlementId', 'BusinesGroup__c', 'Source__c', 'OwnerId', 'owner.email',
        'contact.Name', 'caseNumber', 'Account.Name'
        };
            
            /**
*
*
* @param requests
* @description https://bugs.cudaops.com/browse/SFDC-2590
*
* @return
*/
            @InvocableMethod(
                label = 'Handle Email for Closed Case'
                description = 'Handle Email for Closed Case'
            )
            global static List<ProcessEmailReply> handleEmailClosedCase(List<ProcessEmailRequest> requests) {
                system.debug('~~handlemailclosedcase');
                
                List<ProcessEmailReply> results = new List<ProcessEmailReply>();
                
                // since this is the handler for email. if it fails, emailMessage will fail to create. So it is important to have proper exception handling
                
                LogModel log = LogModel.startLog('EmailMessageModel', 'handleEmailClosedCase');
                try {
                    
                    
                    // you query the email ID and get email.parent = caseid , and check case status = closed. if closed then clone the case.  else ignore.  PB ends
                    
                    Set <Id> caseIds = new Set<Id>();
                    Map <Id, EmailMessage> msgMap = new  Map<Id, EmailMessage>();
                    List<EmailMessage> updateEmailToChildCase = new List<EmailMessage>();
                    
                    for (ProcessEmailRequest r : requests) {
                        if (r.emailMessage != null && r.emailMessage.ParentId != null) {
                            caseIds.add(r.emailMessage.ParentId);
                            msgMap.put(r.emailMessage.ParentId, r.emailMessage);
                        }
                    }
                    
                    String soql = 'select Id, ParentId, Status ';
                    for (String s : CLONE_CASE_FIELDS) {
                        soql += ', ' + s ;
                    }
                    soql += ' from Case where Id in :caseIds';
                    System.debug('~~ soql: ' + soql);
                    List <Case> newCases = new List <Case>();
                    
                    Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
                    List<task> caseTasksToCreate = new List<task>();
                    for (Case c : Database.query(soql)) {
                        System.debug('~~ status:'+c.Status);
                        if (c.Status == 'Closed') {
                            if(c.RecordTypeId == INTERNAL_COMMUNITY_RECORD_TYPE_ID || c.RecordTypeId == PARTNER_SUCCESS_RECORD_TYPE_ID) {
                                System.debug('~~ Community Help case');
                                Double closedTime = Math.floor((System.now().getTime() - c.closeddate.getTime())/(1000*60*60)); 
                                system.debug('~~ closedTime:'+closedTime);
                                if(closedTime>73) {                            
                                    //Invoke submethod for Professional Service, Community_Help & Partner Success Cases
                                    if(c.RecordTypeId == INTERNAL_COMMUNITY_RECORD_TYPE_ID){
                                        newCases.addAll(createCase(CLONE_CASE_FIELDS, c, msgMap, INTERNAL_COMMUNITY_RECORD_TYPE_ID, INTERNAL_TICKET_QUEUE_ID, true, c.Origin));
                                    }
                                    else{
                                        newCases.addAll(createCase(CLONE_CASE_FIELDS, c, msgMap, PARTNER_SUCCESS_RECORD_TYPE_ID, PARTNER_SUCCESS_MSP_QUEUE_ID, false, c.Origin));
                                    }
                                }
                            }
                            else if(c.RecordTypeId == TECHNICAL_SUPPORT_RECORD_TYPE_ID) {
                                system.debug('cases of TECHNICAL_SUPPORT_RECORD_TYPE_ID');
                                newCases.addAll(createCaseForTS(CLONE_CASE_FIELDS, c, msgMap, WEB_MESSAGE_RECORD_TYPE_ID));
                            }
                            else {
                                System.debug('~~ inside other cases');
                                //Invoke submethod for all other Cases
                                newCases.addAll(createCase(CLONE_CASE_FIELDS, c, msgMap, WEB_MESSAGE_RECORD_TYPE_ID, null, false, c.Origin));
                            }
                        }else{
                            if(c.RecordTypeId == PROFESSIONAL_SERVICE_RECORD_TYPE_ID || Test.isRunningTest()){
                                
                                task tsk = new task();
                                tsk.subject = 'Email received from customer';
                                tsk.type = 'Email';
                                tsk.whatId = c.Id;
                                tsk.ownerId = c.ownerId;
                                tsk.status= 'Not Started';
                                tsk.ActivityDate = system.today();
                                caseTasksToCreate.add(tsk);
                                
                                string emailBody = c.contact.Name + ' has responded via email to case number ' + c.caseNumber + '\n' + 'Account Name: ' + c.Account.Name;
                                emailBody = emailBody + '\n' + 'Due Date: ' + system.today();
                                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                                message.toAddresses = new String[] { c.owner.email };
                                    message.subject = 'Task created for " email received by customer"';
                                message.plainTextBody = emailBody;
                                messages.add(message);
                                
                            }
                        }  
                    }
                    if(!caseTasksToCreate.isEmpty()){
                        insert caseTasksToCreate;  
                    } 
                    if(!messages.isEmpty()){
                        Messaging.sendEmail(messages);
                    }
                    
                    
                    List<String> emailMessageIds = new List<String>();
                    if(!newCases.isEmpty()) {
                        DML.save(newCases);
                        
                        for (Case c: newCases){
                            // system.debug('c-->' + c.From_Address__c); //SFDC-13763
                            system.debug('c-->' + c.From_Address_New__c);
                            if(msgMap.containsKey(c.ParentId)){
                                EmailMessage actualEmail = msgMap.get(c.ParentId);
                                EmailMessage clonedEmail  = actualEmail.clone(false, true, true, true);
                                clonedEmail.ValidatedFromAddress = null;
                                clonedEmail.parentId = c.Id;
                                clonedEmail.relatedtoid = c.Id;
                                clonedEmail.Source__c = 'EmailMessageModel';                        
                                updateEmailToChildCase.add(clonedEmail);
                                emailMessageIds.add(actualEmail.Id);
                            }
                            
                            ProcessEmailReply reply = new ProcessEmailReply();
                            reply.existingCaseId = c.ParentId;
                            reply.newCaseId = c.Id;
                            results.add(reply);
                        }
                    }
                    
                    if(!updateEmailToChildCase.isEmpty()){
                        System.debug('~~ updateEmailToChildCase:'+updateEmailToChildCase.size());
                        // DML.save(updateEmailToChildCase);
                        try {
                            upsert updateEmailToChildCase;
                        } catch (Exception e) {
                            System.debug(':::errorMessage::: ' + e.getMessage());
                        }
                        
                        Map<String,Object> caseData = new Map<String,Object>();
                        List<String> newEmailMessageIds = new List<String>();
                        for(EmailMessage updateEmailToChildCaseobj:updateEmailToChildCase){
                            newEmailMessageIds.add(updateEmailToChildCaseobj.Id);
                        }
                        caseData.put('EmailMessageIds',emailMessageIds);
                        caseData.put('newEmailMessageIds',newEmailMessageIds);
                        createAttachmentForChildCase(new List<String>{json.serializePretty(caseData)});
                        
                        
                    }
                    
                } Catch (exception e){
                    System.debug('----- handleEmailClosedCase: ' + e);
                    log.addExceptionLog(e);
                }
                return results;
            }
    
    @testVisible private static List<Case> createCaseForTS(List<String> CLONE_CASE_FIELDS, Case c, Map<Id, EmailMessage> msgMap, String RECORD_TYPE_ID) {
        system.debug('createCaseForTS Method Fired.!!');
        // create new Case
        List <Case> returnCases = new List <Case>();
        Case s = new Case();
        
        for (String f : CLONE_CASE_FIELDS) {
            switch on (f) {
                when 'Subject' {
                    s.put(f, msgMap.get(c.id).Subject);
                } 
                when 'Description' {
                    s.put(f, msgMap.get(c.id).TextBody.abbreviate(31990));
                }
                when else {
                    if(f != 'OwnerId' && f != 'owner.email' && f != 'contact.Name' && f != 'Account.Name' && f != 'caseNumber'){
                        s.put(f, c.get(f));
                    }
                }
            }
        }
        Map<String, Id> queusWithId = new Map<String, Id>();
        for(group g: [SELECT id, Name FROM group WHERE type='queue' AND name in('Contact Center: EMEA','Contact Center: China','Contact Center: India','Contact Center: Americas','Contact Center: Japan')]){
            if(g.name=='Contact Center: EMEA'){queusWithId.put('EMEA',g.Id);}
            if(g.name=='Contact Center: China'){queusWithId.put('China',g.Id);}
            if(g.name=='Contact Center: Japan'){queusWithId.put('Japan',g.Id);}
            if(g.name=='Contact Center: Americas'){queusWithId.put('Americas',g.Id);}
            if(g.name=='Contact Center: India'){queusWithId.put('APAC',g.Id);}
        }
        
        s.RecordTypeID = RECORD_TYPE_ID;
        s.OwnerId = (c.First_Queue_Id__c==null?(queusWithId.get(c.web_region__c)):c.First_Queue_Id__c);
        s.Status = 'New';
        s.origin = 'Email';
        s.ParentId = c.Id;
        s.Source__c = 'EmailMessageModel';
        if(c.Closed_By_Process__c == 'Batch Class'){
            s.Subject = c.Subject;
        }
        returnCases.add(s);
        
        return returnCases;
    }
    
    @testVisible private static List<Case> createCase(List<String> CLONE_CASE_FIELDS, Case c, Map<Id, EmailMessage> msgMap, String RECORD_TYPE_ID, Id Owner, Boolean CommunityCase, String Case_Origin) {
        // create new Case
        List <Case> returnCases = new List <Case>();
        Case s = new Case();
        
        for (String f : CLONE_CASE_FIELDS) {
            switch on (f) {
                when 'Subject' {
                    s.put(f, msgMap.get(c.id).Subject);
                }
                when 'Description' {
                    s.put(f, msgMap.get(c.id).TextBody.abbreviate(31990));
                }
                when else {
                    if(f != 'OwnerId' && f != 'owner.email' && f != 'contact.Name' && f != 'Account.Name' && f != 'caseNumber'){
                        s.put(f, c.get(f));
                    }
                }
            }
        }
        
        s.RecordTypeID = RECORD_TYPE_ID;
        if(RECORD_TYPE_ID == PARTNER_SUCCESS_RECORD_TYPE_ID){
            s.OwnerId = PARTNER_SUCCESS_MSP_QUEUE_ID;
        }
        if(c.RecordTypeID == PROFESSIONAL_SERVICE_RECORD_TYPE_ID && c.Web_Region__c == 'EMEA'){
            s.OwnerId = CONTACT_CENTER_EMEA_QUEUE_ID;
            s.IsProfessionalService__c = true;
        } else if(c.RecordTypeID == PROFESSIONAL_SERVICE_RECORD_TYPE_ID && c.Web_Region__c == 'APAC'){
            s.OwnerId = CONTACT_CENTER_INDIA_QUEUE_ID;
            s.IsProfessionalService__c = true;
        } else if(c.RecordTypeID == PROFESSIONAL_SERVICE_RECORD_TYPE_ID && c.Web_Region__c == 'AMERICAS'){
            s.OwnerId = CONTACT_CENTER_AMERICAS_QUEUE_ID;
            s.IsProfessionalService__c = true;
        }  
        
        Map<String, Id> queusWithId = new Map<String, Id>();
        for(group g: [SELECT id, Name FROM group WHERE type='queue' AND name in('Contact Center: EMEA','Contact Center: China','Contact Center: India','Contact Center: Americas','Contact Center: Japan')]){
            if(g.name=='Contact Center: EMEA'){queusWithId.put('EMEA',g.Id);}
            if(g.name=='Contact Center: China'){queusWithId.put('China',g.Id);}
            if(g.name=='Contact Center: Japan'){queusWithId.put('Japan',g.Id);}
            if(g.name=='Contact Center: Americas'){queusWithId.put('Americas',g.Id);}
            if(g.name=='Contact Center: India'){queusWithId.put('APAC',g.Id);}
        }
        
        s.Status = 'New';
        if(c.First_Queue_Id__c==null && queusWithId.get(c.web_region__c)!=null)
            s.OwnerId = queusWithId.get(c.web_region__c);
        s.origin = 'Email'; //Updating Child Case origin to Email
        s.ParentId = c.Id;
        s.Source__c = 'EmailMessageModel'; 
        
        if(CommunityCase) {
            s.OwnerId = INTERNAL_TICKET_QUEUE_ID;
        }        
        returnCases.add(s);
        
        return returnCases;
    }
    
    public static void updateCaseEmail(List<EmailMessage> emList){
        Boolean caseFlowBefore =FlowActionTriggerHandler.isExecutedBeforeUpdate;
        Boolean caseFlowAfter = FlowActionTriggerHandler.isExecutedAfterUpdate;
        FlowActionTriggerHandler.isExecutedBeforeUpdate = true;
        FlowActionTriggerHandler.isExecutedAfterUpdate = true;        
        LogModel log = LogModel.startLog('EmailMessageModel', 'updateCaseEmail');
        try {
            List<Case> caseList = new List<Case>();
            Set<String> emailSet = new Set<String>();
            Set<Id> caseIdSet = new Set<Id>();
            Map<Id, Case> caseMap = new Map<Id, Case>();
            List<Key_Value_Data__mdt> keyValueList = [Select DeveloperName, Value_Long__c 
                                                      from Key_Value_Data__mdt 
                                                      where DeveloperName = 'Case_Support_Emails'];  
            if(!keyValueList.isEmpty() && String.isNotBlank(keyValueList[0].Value_Long__c)){
                List<String> emialIdList = keyValueList[0].Value_Long__c.split(',');
                for(String emailId: emialIdList){
                    emailSet.add(emailId.trim());
                }
            }

            
            for(EmailMessage em: emList){
                //SFDC-19815
                if(em.Status != '5')
                    caseIdSet.add(em.ParentId);
            }     
            
            caseMap = new Map<Id, Case>([Select Id, Additional_Recipient_Email__c from Case where Id =: caseIdSet]);
            
            for(EmailMessage em: emList){
                //SFDC-19815
                if( em.Status != '5' && !em.Incoming && em.ParentId != null && String.valueOf(em.ParentId).startsWith('500')){
                    Set<String> uniqueEmailSet = new Set<String>();
                    String additionalRecipientEmail;
                    Case c = new Case();
                    c.Id = em.ParentId;
                    if(String.isNotBlank(caseMap.get(c.Id).Additional_Recipient_Email__c)){
                        for(String emailAddr: caseMap.get(c.Id).Additional_Recipient_Email__c.split(';')){
                            emailAddr = emailAddr.trim(); 
                            uniqueEmailSet.add(emailAddr);
                        }                    
                    }
                    if(String.isNotBlank(em.CcAddress)){
                        for(String emailAddr: em.CcAddress.split(';')){
                            emailAddr = emailAddr.trim(); 
                            uniqueEmailSet.add(emailAddr);
                        }                    
                    }      
                    for(String emailAddr: uniqueEmailSet){
                        if(String.isNotBlank(additionalRecipientEmail)){
                            additionalRecipientEmail = additionalRecipientEmail + '; ' + emailAddr;
                        } else {
                            additionalRecipientEmail = emailAddr;
                        }                    
                    }
                    c.Additional_Recipient_Email__c = additionalRecipientEmail;                
                    caseList.add(c);
                } 
                //SFDC-19815
                else if((em.Status != '1' && em.Status != '5' && em.Status != null) && em.Incoming && em.ParentId != null && String.valueOf(em.ParentId).startsWith('500')){
                    Set<String> uniqueEmailSet = new Set<String>();
                    String additionalRecipientEmail;                
                    Case c = new Case();                                                                                                                                                                                                                       
                    c.Id = em.ParentId;
                    if(String.isNotBlank(caseMap.get(c.Id).Additional_Recipient_Email__c)){
                        for(String emailAddr: caseMap.get(c.Id).Additional_Recipient_Email__c.split(';')){
                            emailAddr = emailAddr.trim(); 
                            uniqueEmailSet.add(emailAddr);
                        }                    
                    }
                    if(String.isNotBlank(em.CcAddress)){
                        for(String emailAddr: em.CcAddress.split(';')){
                            emailAddr = emailAddr.trim(); 
                            uniqueEmailSet.add(emailAddr);
                        }                    
                    }      
                    for(String emailAddr: em.ToAddress.split(';')){
                        emailAddr = emailAddr.trim();
                        if(!emailSet.contains(emailAddr) && !uniqueEmailSet.contains(emailAddr)){
                            uniqueEmailSet.add(emailAddr);
                        }
                    }
                    for(String emailAddr: uniqueEmailSet){
                        if(String.isNotBlank(additionalRecipientEmail)){
                            additionalRecipientEmail = additionalRecipientEmail + '; ' + emailAddr;
                        } else {
                            additionalRecipientEmail = emailAddr;
                        }                    
                    }
                    c.Additional_Recipient_Email__c = additionalRecipientEmail;                 
                    caseList.add(c);              }
            }
            
            if(!caseList.isEmpty()){
                Database.SaveResult[] srList = Database.update(caseList, false); 
                
                Integer index = 0;
                
                // Iterate through each returned result
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess() || Test.isRunningTest()) {
                        LogModel log1 = LogModel.startLog('EmailMessageModel', 'execute');
                        String errorStr = 'Record Id: ' + caseList[index].Id;
                        
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {                        
                            errorStr = errorStr + ' ' + err.getStatusCode() + ' ' + err.getMessage() + ' ' + err.getFields();                        
                        }
                        if(errorStr.length() > 32767){
                            errorStr = errorStr.substring(0, 32767);
                        }                    
                        log1.endLog(errorStr);
                    }
                    
                    index++;
                }                
            }
            
        } catch (Exception e) {
            log.addExceptionLog(e);
        }
        FlowActionTriggerHandler.isExecutedBeforeUpdate = caseFlowBefore;
        FlowActionTriggerHandler.isExecutedAfterUpdate = caseFlowAfter;
    }
    
    @future
    public static void createAttachmentForChildCase(List<String> caseData) {
        Map<String,object> caseDataMap = (Map<String,object>) JSON.deserializeUntyped(caseData[0]);
        List<Object> EmailMessageIdstemp = (List<Object>) caseDataMap.get('EmailMessageIds');
        List<Object> newEmailMessageIdstemp = (List<Object>) caseDataMap.get('newEmailMessageIds');
        List<String> EmailMessageIds = new List<String>();
        List<String> newEmailMessageIds = new List<String>();
        for(Object EmailMessageIdstempobj:EmailMessageIdstemp){
            EmailMessageIds.add((String) EmailMessageIdstempobj);
            
        }
        for(Object newEmailMessageIdstempobj:newEmailMessageIdstemp){
            newEmailMessageIds.add((String) newEmailMessageIdstempobj);
            
        }
        List<ContentDocumentLink> cdL=new List<ContentDocumentLink>([select contentDocumentId,contentDocument.Title,contentDocument.Description from ContentDocumentLink where LinkedEntityId IN:EmailMessageIds]);
        List<Id> cndIdset=new List<Id>();
        for(ContentDocumentLink cd:cdl){
            cndIdset.add(cd.contentDocumentId);
        }
        
        List<ContentVersion> originalContentVersions = [SELECT Id, Title, VersionData, PathOnClient, Description FROM ContentVersion WHERE ContentDocumentId IN:cndIdset];
        List<ContentVersion> clonedContentVersions = new List<ContentVersion>();
        
        for(String newEmailMessageId : newEmailMessageIds){
            
            for(ContentVersion originalContentVersion : originalContentVersions) {
                ContentVersion clonedContentVersion = new ContentVersion();
                clonedContentVersion.Title = originalContentVersion.Title;
                clonedContentVersion.VersionData = originalContentVersion.VersionData;
                clonedContentVersion.PathOnClient = originalContentVersion.PathOnClient;
                clonedContentVersion.Description = originalContentVersion.Description;
                clonedContentVersions.add(clonedContentVersion);
            }
        }
        if(!clonedContentVersions.isEmpty()){
            insert clonedContentVersions;
        }
        
        List<ContentDocumentLink> cdLTobeInsert=new List<ContentDocumentLink>();
        clonedContentVersions = [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :clonedContentVersions];
        
        
        for(String newEmailMessageId : newEmailMessageIds){
            for(ContentVersion originalContentV : clonedContentVersions) {
                ContentDocumentLink cDocLink = new ContentDocumentLink();
                cDocLink.ContentDocumentId = originalContentV.ContentDocumentId;
                cDocLink.LinkedEntityId =newEmailMessageId;
                cDocLink.ShareType = 'V';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                cDocLink.Visibility = 'AllUsers';//AllUsers, InternalUsers, SharedUsers
                cdLTobeInsert.add(cDocLink);
            }
        }
        if(!cdLTobeInsert.isEmpty()){
            DML.save(cdLTobeInsert);
        }
        
    }
}