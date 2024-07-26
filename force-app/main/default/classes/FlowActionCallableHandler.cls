public class FlowActionCallableHandler implements Callable {
    public static final String WEB_MESSAGE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Web_Case').getRecordTypeId(); // '0123C0000006R7kQAE';
    public static final String INTERNAL_COMMUNITY_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Community_Help').getRecordTypeId();
    public static final String TECHNICAL_SUPPORT_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();
    public static final String PARTNER_SUCCESS_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Partner_Success').getRecordTypeId();
    public static final String PROFESSIONAL_SERVICE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Professional_Services').getRecordTypeId();
    
    
    // Dispatch actual methods
    public Object call(String action, Map<String, Object> args) {
        system.debug('call method is invoked');
        switch on action {
            when 'calcualteAccumatedAge' { 
                return this.calcualteAccumatedAge(args.get('record'));
            }                        
            when else {
                throw new ExtensionMalformedCallException('Method not implemented');
            }
        }
    }
    public Object callAsync(Map<String, Object> args) {
        
        Map<String,sObject> payloadMap=(Map<string,sObject>)args.get('inputMap');
        Map<String,object> recordMap=(Map<String,object>)args.get('record');
        system.debug('call Async method is invoked');
        System.debug('###args::: ' + JSON.serialize(args));
        System.debug('###recordMap::: ' + JSON.serialize(recordMap));
        for(String method :recordMap.keySet()){
            System.debug('####method::: ' + method);
            switch on method {
                
                when 'updateCaseOnEmailMessageResponse'{
                    this.updateCaseOnEmailMessageResponse((List<sObject>)recordMap.get(method),(Map<string,sObject>)args.get('inputMap'));
                }
                when 'caseCustomerReply' {
                    this.caseCustomerReply((List<sObject>)recordMap.get(method),(Map<string,sObject>)args.get('inputMap'));
                }
                when 'handleEmailClosedCase' {
                    this.handleEmailClosedCase((List<sObject>)recordMap.get(method),(Map<string,sObject>)args.get('inputMap'));
                }
                when 'emailMessageUpdateCaseFromAddress' {
                    this.emailMessageUpdateCaseFromAddress((List<sObject>)recordMap.get(method),(Map<string,sObject>)args.get('inputMap'));
                }
                when 'emailUpdateCaseOwner' {
                    this.emailUpdateCaseOwner((List<sObject>)recordMap.get(method),(Map<string,sObject>)args.get('inputMap'));
                }
                when 'updateFromAddress' {
                    this.updateFromAddress((List<sObject>)recordMap.get(method),(Map<string,sObject>)args.get('inputMap'));
                }
                when 'updateCaseEmail' {
                    this.updateCaseEmail((List<sObject>)recordMap.get(method),(Map<string,sObject>)args.get('inputMap'));
                }   				               
                when 'updatePSInternalEmail' {
                    this.updatePSInternalEmail((List<sObject>)recordMap.get(method),(Map<string,sObject>)args.get('inputMap'));
                }   
                when 'emailMessageUpdates' {
                    this.emailMessageUpdates((List<sObject>)recordMap.get(method),(Map<string,sObject>)args.get('inputMap'));
                }   
                when 'assignEntitlementForPremiumCase' {
                    this.assignEntitlementForPremiumCase((List<sObject>)recordMap.get(method),(Map<string,sObject>)args.get('inputMap'));
                } 
                when 'sendPremiumSupportNotifications' {
                    this.sendPremiumSupportNotifications((List<sObject>)recordMap.get(method),(Map<string,sObject>)args.get('inputMap'));
                }                   
                when else {
                    throw new ExtensionMalformedCallException('Method not implemented');
                }
            }
        }
        return payloadMap;
    }
    
    
    // Actual method
    String calcualteAccumatedAge(Object record) {
        try{
            Map<String,object> recordMap=(Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(record));
            Case records=(case)JSON.deserialize (JSON.serialize(recordMap),case.class);
            //System.assertEquals(records.Escalated_Date_Time__c,Datetime.Now());
            if(records.Escalated_Date_Time__c!=null){
                if(records.Accumulated_age_in_sec__c!=null){
                    return String.valueOf(Integer.valueOf(recordMap.get('Accumulated_Age_in_Sec__c'))+(Integer.valueOf(Datetime.Now().getTime() - records.Escalated_Date_Time__c.getTime())/1000));
                }else{
                    return String.valueOf(Integer.ValueOf(Datetime.Now().getTime() - records.Escalated_Date_Time__c.getTime())/1000);
                    
                }
                
            }
        }catch(Exception ex){
            System.debug('Error: '+ex.getMessage ()+' Line No: '+ex.getLineNumber());
        }
        return '0';
        
    }
    public Map<String,sObject> updateCaseOnEmailMessageResponse(List<sObject> record,Map<String,sObject> payloadMap){
        //Node: MSP - When Partner replies
        try{
            for(EmailMessage em:(List<EmailMessage>)record){
                String csId=(String)em.get('ParentId');
                if(payloadMap.containsKey(csId)){
                    if((boolean)em.get('Incoming')==true){
                        payloadMap.get(csId).put('Status','In Progress');
                    }else{
                        payloadMap.get(csId).put('Status','Waiting for Requester Response');
                    }
                    
                }else if(csId.startswith('500')) {
                    if((boolean)em.get('Incoming')==true){ 
                        payloadMap.put(csId,new Case (Id=csId,Status='In Progress'));
                    }else{
                        payloadMap.put(csId,new Case (Id=csId,Status='Waiting for Requester Response'));
                    }
                }
            }
            return payloadMap;  
        }catch(Exception ex){
            System.debug('Error: '+ex.getMessage ()+' Line No: '+ex.getLineNumber());
        }
        return payloadMap; 
    }
    
    public Map<String,sObject> caseCustomerReply(List<sObject> record,Map<String,sObject> payloadMap){
        //Node: 1.Internal Ticket Record Type - When Customer replies back
        //		2.Community Help- When Customer replies back
        try{
            for(EmailMessage em:(List<emailMessage>)record){
                String csId=(String)em.get('ParentId');
                if(payloadMap.containsKey(csId)){
                    payloadMap.get(csId).put('Status','Response Received');
                    
                }else if(csId.startswith('500')) {
                    payloadMap.put(csId,new Case (Id=csId,Status='Response Received'));
                }
                
            } 
            return payloadMap;
        }catch(Exception ex){
            System.debug('Error: '+ex.getMessage ()+' Line No: '+ex.getLineNumber());
        }
        return payloadMap;
    }
    public Map<String,sObject> handleEmailClosedCase(List<sObject> record,Map<String,sObject> payloadMap){
        
        Case cs=new Case();
        Set<Id> csIdSet=new Set<Id>();
        List<EmailMessage> messageLs=new List<EmailMessage>();
        List<EmailMessage> emList=(List<EmailMessage>)record;
        for(EmailMessage em:emList){
            csIdSet.add(em.ParentId);
        }
        Map<id,Case>caMap=new Map<Id,Case>([select Id,ClosedDate,recordtypeId,Status From Case Where Id IN:csIdSet]);
        for(EmailMessage em:emList){
            String csId=(String)em.get('ParentId');
            if(payloadMap.containsKey(csId)){
                cs=(Case)payloadMap.get(csId);
            }
            else{
                cs=caMap.get(csId);
            }
            
            Double closedTime=0;
            
            if((cs != null && caMap.get(cs.Id).ClosedDate != null)){
                closedTime= Math.floor((System.now().getTime() - caMap.get(cs.Id).ClosedDate.getTime())/(1000*60*60)); 
            }
            
            if(closedTime<73 && caMap.get(cs.Id).Status == 'Closed' && (caMap.get(cs.Id).RecordTypeId == INTERNAL_COMMUNITY_RECORD_TYPE_ID || caMap.get(cs.Id).RecordTypeId == PARTNER_SUCCESS_RECORD_TYPE_ID)){
                //Re-open the case
                cs.Status = 'In Progress'; 
                cs.Case_Re_Opened__c = true;
                payloadMap.put(cs.Id,cs);
            }
            else if((caMap.get(cs.Id).Status != 'Closed' && caMap.get(cs.Id).RecordTypeId == PROFESSIONAL_SERVICE_RECORD_TYPE_ID )|| caMap.get(cs.Id).Status == 'Closed'){
                // messageLs.add(em);
                EmailMessageModel obj=new EmailMessageModel(em);
                System.enqueueJob(obj);
            }
        }
        return payloadMap;
    }
    
    // method to send Premium Support Notifications for AMERICAS, EMEA & APAC
    public Map<String,sObject> sendPremiumSupportNotifications(List<sObject> records, Map<String,sObject> payloadMap){
        LogModel log = LogModel.startLog('FlowActionCallableHandler', 'sendPremiumSupportNotifications');
        System.debug('####sendPremiumSupportNotifications');
        try {
            EmailMessage emRecord; 
            for(sObject sObj: records){
                emRecord = (EmailMessage) sObj;
            }  
            System.debug('####payloadMap1sendPremiumSupportNotificationss:emRecord:: ' + JSON.serialize(payloadMap));
            System.debug('####payloadMap1sendPremiumSupportNotifications::: ' + JSON.serialize(payloadMap));
            Case c  = (Case) payloadMap.get(emRecord.ParentId);
  
            if(((String.isNotBlank(c.From_Address_New__c) && (c.From_Address_New__c.contains('wafpremium') || 
                                                              c.From_Address_New__c.contains('emeapremium_team') || 
                                                              c.From_Address_New__c.contains('emeapremiumsupport_team'))) || 
                (emRecord.Case_Owner_Name__c == 'Contact Center: India' || 
                 emRecord.Case_Owner_Name__c == 'Contact Center: EMEA')) 
               && c.Premium_Emails__c)
            	PremiumSupportNotification.sendEmail(emRecord, c.From_Address_New__c); 
            else if(((String.isNotBlank(c.From_Address_New__c) && c.From_Address_New__c.contains('premiumsupport_team')) || emRecord.Case_Owner_Name__c == 'Contact Center: Americas') && c.Premium_Emails__c)
            	PremiumSupportNotification.sendEmail(emRecord, c.From_Address_New__c); 
        } catch (Exception e) {
            log.addExceptionLog(e);
        }                           
        return payloadMap;
    }    
    
    // method to assign Premium Entitlement to Case
    public Map<String,sObject> assignEntitlementForPremiumCase(List<sObject> records, Map<String,sObject> payloadMap){
        LogModel log = LogModel.startLog('FlowActionCallableHandler', 'assignEntitlementForPremiumCase');
        System.debug('####assignEntitlementForPremiumCase');
        try {
            Set<Id> csIdSet=new Set<Id>();
            for(sObject sObj: records){
                Id recordId = (Id) sObj.get('Id');
                if(String.valueOf(recordId).startsWith('500')){
                    csIdSet.add(recordId);
                } else {
                    EmailMessage em = (EmailMessage) sObj;
                    csIdSet.add(em.ParentId);                                        
                }
            }
            
           
            List<Case> caseList = [Select Id, EntitlementId, AccountId, ContactId, Priority, RecordTypeId, 
                                   Status, Is_Premium_Support__c, Premium_Emails__c, Case_Owner_Queue_Name__c,
                                   RecordType.Name from Case where Id =: csIdSet];  
            System.debug('####payloadMap1::: ' + JSON.serialize(payloadMap));
            if(!caseList.isEmpty()){
                Boolean isPriorityP2 = false;
                case caseRecord = caseList[0];
                if(payloadMap.containsKey(caseRecord.Id)){                    
                    Case c  = (Case) payloadMap.get(caseRecord.Id);
                    if(c.Priority == 'P2') isPriorityP2 = true;
                    System.debug('###c:: ' + JSON.serialize(c));
                }
                System.debug('###caseRecord::: ' + JSON.serialize(caseRecord));
                if((caseRecord.RecordType.Name == 'Web Message' && (isPriorityP2 || caseRecord.Priority == 'P2') && caseRecord.Status == 'New') ||
                   (caseRecord.RecordType.Name == 'Technical Support' && !String.isBlank(caseRecord.Case_Owner_Queue_Name__c) && 
                    caseRecord.Case_Owner_Queue_Name__c == 'TAC Global Premium Support') || Test.IsRunningTest()){                    
                        Entitlement en = [Select Id, Name from Entitlement where 
                                          Name = 'Premium Cases Assign Entitlement' and
                                          Status = 'Active' and 
                                          StartDate = 2020-06-10 and
                                          EndDate = 2049-12-31 limit 1];                        
                        if(payloadMap.containsKey(caseRecord.Id)){
                            payloadMap.get(caseRecord.Id).put('EntitlementId', en.Id);                        
                        }else {
                            payloadMap.put(caseRecord.Id, new Case (Id=caseRecord.Id, EntitlementId=en.Id));
                        }   					
                    }
                System.debug('####payloadMap2::: ' + JSON.serialize(payloadMap));
            }
        } catch (Exception e) {
            log.addExceptionLog(e);
        }                           
        return payloadMap;        
    } 
    
    // method to update Case From Address
    public Map<String,sObject> emailMessageUpdateCaseFromAddress(List<sObject> record, Map<String,sObject> payloadMap){
        System.debug('####emailMessageUpdateCaseFromAddress');
        LogModel log = LogModel.startLog('FlowActionCallableHandler', 'emailMessageUpdateCaseFromAddress');
        try {
            List<EmailMessage> emRecord = (List<EmailMessage>) record;
            Set<Id> csIdSet=new Set<Id>();
            for(EmailMessage em:emRecord){
                csIdSet.add(em.ParentId);
            }
            
            List<Case> caseList = [Select Id, Priority, Premium_Emails__c, Is_Priority_updated__c, OwnerId, From_Address_New__c, 
                                   Contact_Center_Workaround__c, IsProfessionalService__c, Web_Region__c
                                   from Case where Id IN: csIdSet];  
            for(Case caseRecord: caseList){
                if(payloadMap.containsKey(caseRecord.Id)){
                    Case c  = (Case) payloadMap.get(caseRecord.Id);
                    caseRecord.From_Address_New__c = c.From_Address_New__c;
                }                    
            }
            if(!caseList.isEmpty()){  
                for(case cs:caseList){  
                    case caseRecord = CaseModelFlowHelper.setContactCenter(new List<case>{cs})[0];
                    System.debug('###caseRecord:: ' + JSON.serialize(caseRecord));
                    if(payloadMap.containsKey(caseRecord.Id)){ 
                        System.debug('###inside if block');                        
                        Case existingCaseRecord = (Case) payloadMap.get(caseRecord.Id);
                        existingCaseRecord.Premium_Emails__c = caseRecord.Premium_Emails__c;
                        existingCaseRecord.Is_Priority_updated__c = caseRecord.Is_Priority_updated__c;
                        existingCaseRecord.Web_Region__c = caseRecord.Web_Region__c;
                        existingCaseRecord.Contact_Center_Workaround__c = caseRecord.Contact_Center_Workaround__c;
                        existingCaseRecord.Priority = caseRecord.Priority;
                        existingCaseRecord.IsProfessionalService__c = caseRecord.IsProfessionalService__c;
                        payloadMap.put(caseRecord.Id, existingCaseRecord); 
                    } else {
                        System.debug('###inside else block');
                       payloadMap.put(caseRecord.Id, caseRecord);
                    }                    
                }
            }
            System.debug('###payloadMap:: ' + JSON.serialize(payloadMap));
        } catch (Exception e) {
            log.addExceptionLog(e);
        }                           
        return payloadMap;        
    }
    
    
    public Map<String,sObject> emailUpdateCaseOwner(List<sObject> record,Map<String,sObject> payloadMap){
        LogModel log = LogModel.startLog('EmailMessageTriggerHelper', 'updateCaseOwner');
        try {        
            List<EmailMessage> emLs = (List<EmailMessage>)record;
            emLs = [Select ParentId, Parent.Status, Parent.RecordType.DeveloperName, ToAddress from EmailMessage where Id =: emLs];
            
            Map<String, String> emailToQueueMap = new Map<String, String>();
            Map<String, Id> QueueToIdMap = new Map<String, Id>();
            
            for(EmailToCaseOwnerMapping__mdt mdt: [Select Email__c, Case_Owner__c from EmailToCaseOwnerMapping__mdt]){
                for(String emailString: new Set<String>(mdt.Email__c.split(','))){
                    emailToQueueMap.put(emailString.trim(), mdt.Case_Owner__c);
                }                        	
            }        
            for(Group grp: [Select DeveloperName, Id from Group where Type = 'Queue' and DeveloperName =: emailToQueueMap.values()]){
                QueueToIdMap.put(grp.DeveloperName, grp.Id);
            }
            
            
            for(EmailMessage em:emLs){
                if((em.Parent.Status == 'Waiting for Customer Response' && em.Parent.RecordType.DeveloperName == 'Web_Case') || Test.isRunningTest()){
                    
                    Set<String> fromEmails = new Set<String>(em.ToAddress.split(';'));                   
                    for(String emailStr: fromEmails){
                        emailStr = emailStr.trim();
                        if(emailToQueueMap.containsKey(emailStr)){
                            Case c = new Case();
                            if(payloadMap.containsKey(em.ParentId)){
                                c =(Case)payloadMap.get(em.ParentId);
                            }
                            c.Id = em.ParentId;                             
                            c.OwnerId = QueueToIdMap.get(emailToQueueMap.get(emailStr)); 
                            
                            payloadMap.put(c.Id,c);
                            break;
                        }
                    }
                    
                    if(payloadMap.containsKey(em.ParentId)){
                        Case c = (Case) payloadMap.get(em.ParentId);
                        c.Status = 'New';
                        c.Web_Message_Attempt_1__c = false;
                        payloadMap.put(c.Id, c);                                                 
                    } else {
                        Case c = new Case();
                        c.Id = em.ParentId;
                        c.Status = 'New';
                        c.Web_Message_Attempt_1__c = false;
                        payloadMap.put(c.Id, c);                         
                    }
                    
                }
            }
        } catch (Exception e) {
            log.addExceptionLog(e);
        } 
        return payloadMap;
        
    }
    
    public Map<String,sObject> updateFromAddress(List<sObject> record, Map<String,sObject> payloadMap){
        System.debug('#####updateFromAddress');
        LogModel log = LogModel.startLog('EmailMessageTriggerHelper', 'updateCaseFromAddress');
        try{ 	
            List<EmailMessage> emLs=(List<EmailMessage>) record;
            Set<Id> caseIdSet = new Set<Id>();
            for(EmailMessage em: emLs){
                caseIdSet.add(em.ParentId);
            }
            Map<Id, Case> caseMap = new Map<Id, Case>([Select Id, Status, Internal_PS_Email__c, CreatedDate, Web_Region__c from Case where Id =: caseIdSet]);
            List<String> toAndCCAddressList=new List<String>();
            
            for(CaseToAdresss__mdt toAddress:[SELECT Id,EmailAddress__c FROM CaseToAdresss__mdt]){
                if(toAddress.EmailAddress__c!=null){
                    toAndCCAddressList.add(toAddress.EmailAddress__c);
                }
            }
            for(EmailMessage em:EmLs){                                  
                for(String address:toAndCCAddressList){
                    if((em.ToAddress!=null && em.ToAddress.ContainsIgnoreCase(address)) || (em.CcAddress!=null && em.CcAddress.ContainsIgnoreCase(address))){ 
                        String toAddress= em.CcAddress==null?em.ToAddress:(em.ToAddress+';'+ em.CcAddress);
                            
                            Case c=new Case();
                        if(payloadMap.containsKey(em.ParentId)){
                            c =(Case)payloadMap.get(em.ParentId);
                        }
                        c.Id=em.ParentId;
                        c.From_Address_New__c=toAddress;
                        payloadMap.put(em.ParentId,c);
                        break;
                    }  
                }
            }
            
        } catch (Exception e) {
            log.addExceptionLog(e);
        } 
        return payloadMap;
        
    }
    public Map<String,sObject> updateCaseEmail(List<sObject> record,Map<String,sObject> payloadMap){
        
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
            List<EmailMessage> emLs=(List<EmailMessage>)record;
            Set<Id> csIdSet=new Set<Id>();
            for(EmailMessage em:emLs)
            {
                csIdSet.add(em.ParentId);
            }
            caseMap = new Map<Id, Case>([Select Id, Additional_Recipient_Email__c from Case where Id IN: csIdSet]);
            for(EmailMessage em:emLs){
                if( em.Status != '5' && !em.Incoming && em.ParentId != null && String.valueOf(em.ParentId).startsWith('500')){
                    
                    Set<String> uniqueEmailSet = new Set<String>();
                    String additionalRecipientEmail;
                    Case c = new Case();
                    if(payloadMap.containsKey(em.ParentId)){
                        c =(Case)payloadMap.get(em.ParentId);
                    }
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
                    
                    if(String.isNotBlank(additionalRecipientEmail)){
                        c.Additional_Recipient_Email__c = additionalRecipientEmail;    
                        payloadMap.put(c.Id,c);
                    }
                    
                } 
                else if((em.Status != '1' && em.Status != '5' && em.Status != null) && em.Incoming && em.ParentId != null && String.valueOf(em.ParentId).startsWith('500')){
                    Set<String> uniqueEmailSet = new Set<String>();
                    String additionalRecipientEmail;                
                    Case c = new Case(); 
                    if(payloadMap.containsKey(em.ParentId)){
                        c =(Case)payloadMap.get(em.ParentId);
                    }
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
                    if(String.isNotBlank(additionalRecipientEmail)){
                        c.Additional_Recipient_Email__c = additionalRecipientEmail;                 
                        payloadMap.put(c.Id,c);
                    }
                    
                }
            }
            
        } catch (Exception e) {
            system.debug('Exception error**');
            log.addExceptionLog(e);
        }
        return payloadMap;
        
    } 
    
    public Map<String, sObject> updatePSInternalEmail(List<sObject> record,Map<String,sObject> payloadMap){
        LogModel log = LogModel.startLog('FlowActionCallableHandler', 'updatePSInternalEmail');
        try {        
            List<EmailMessage> emLs = (List<EmailMessage>) record;
            emLs = [Select ParentId, Parent.Web_Region__c, Parent.Subject, Parent.CaseNumber, Parent.SuppliedEmail from EmailMessage where Id =: emLs];                        
            
            for(EmailMessage em:emLs){
                String psEmail;
                if(em.Parent.Web_Region__c == 'EMEA'){
                    psEmail = System.Label.EMEA_PS_Email;
                } else if(em.Parent.Web_Region__c == 'Americas'){
                    psEmail = System.Label.Americas_PS_EMail;
                } else if(em.Parent.Web_Region__c == 'APAC'){
                    psEmail = System.Label.APAC_PS_Email;
                }
                Case c = new Case();
                if(payloadMap.containsKey(em.ParentId)){
                    c = (Case) payloadMap.get(em.ParentId);
                }
                c.Id = em.ParentId;
                c.Internal_PS_Email__c = psEmail;
                c.IsProfessionalService__c = true;
                payloadMap.put(c.Id, c);  
                
                // send email to internal ps email
                List<Messaging.SingleEmailMessage> lEmails = new List<Messaging.SingleEmailMessage>();
                OrgWideEmailAddress fromAddr = [select Id,DisplayName,Address from OrgWideEmailAddress where Address = 'donotreply@barracuda.com' LIMIT 1];
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> sendingTo = new List<String>{psEmail};
                email.setOrgWideEmailAddressId(fromAddr.Id);
                email.setToAddresses(sendingTo);
                email.setBccSender(false);
                String emailSubject = 'NEW Professional Service Web Message - Case #' + em.Parent.CaseNumber + ' ' + em.Parent.Web_Region__c;
                email.setSubject(emailSubject);
                String emailBody = '<ul>'+
                    '<li> Email Subject: ' + em.Parent.Subject + '</li>'+
                    '<li> Case Number: ' + em.Parent.CaseNumber + '</li>'+
                    '<li> From Address: ' + em.Parent.SuppliedEmail + '</li>'+
                    '</ul>';
                email.setHtmlBody(emailBody);
                lEmails.add(email);
                system.debug('Print lEmails:'+lEmails.size());                
                Messaging.sendEmail(lEmails);                
            }
        } catch (Exception e) {
            log.addExceptionLog(e);
        } 
        return payloadMap;        
    }  
    
    public Map<String,sObject> emailMessageUpdates(List<sObject> record, Map<String,sObject> payloadMap){
        System.debug('#####tsEmailMessageUpdates');
        LogModel log = LogModel.startLog('EmailMessageTriggerHelper', 'tsEmailMessageUpdates');
        try{ 	
            List<EmailMessage> emLs=(List<EmailMessage>) record;
            Set<Id> caseIdSet = new Set<Id>();
            for(EmailMessage em: emLs){
                caseIdSet.add(em.ParentId);
            }
            Map<Id, Case> caseMap = new Map<Id, Case>([Select Id, Status, RecordType.Name, Agent_First_Communication__c, CaseNumber
                                                       from Case where Id =: caseIdSet]);
            for(EmailMessage em:EmLs){ 
                Case caseRecord = caseMap.get(em.ParentId);
                System.debug('###caseRecord::: ' + JSON.serialize(caseRecord));
                System.debug('####em::: ' + JSON.serialize(em));
                Boolean EmailMessageSubjectComparison = false;
                String subjComp = 'Your Case ' + caseRecord.CaseNumber + ' has been received';
                if(em.Subject.startsWithIgnoreCase(subjComp)){
                    EmailMessageSubjectComparison = true;
                }
                System.debug('###EmailMessageSubjectComparison::: ' + EmailMessageSubjectComparison);
                Case c = new Case();
                if(payloadMap.containsKey(em.ParentId)) 
                    c = (Case) payloadMap.get(em.ParentId);
                else 
                    c.Id = em.ParentId;   
                if((caseRecord.Status == 'Waiting for Customer Response' || caseRecord.Status == 'Vendor Hold' || caseRecord.Status == 'Resolved')
                   && em.Incoming && !em.Subject.contains('Automatic Reply') && em.Status == '0'){
                       System.debug('inside if block 1');
                    c.Status = 'In Progress';
                    payloadMap.put(c.Id, c);                     
                   } else if(caseRecord.Agent_First_Communication__c == null && em.Status == '3' && EmailMessageSubjectComparison == false &&
                    !em.Incoming){
                       c.Agent_First_Communication_Method__c = 'Email';
                       c.Agent_First_Communication__c = System.now();
                       c.Last_Email_Sent__c = System.now();
                       payloadMap.put(c.Id, c);
                   } else if(!em.Incoming && EmailMessageSubjectComparison == false && em.Status == '3'){
                       c.Last_Email_Sent__c = System.now();
                       payloadMap.put(c.Id, c);                          
                   }				
            }
            
        } catch (Exception e) {
            log.addExceptionLog(e);
        } 
        return payloadMap;
        
    }
    
    
    public class ExtensionMalformedCallException extends Exception {}
}