@isTest
public class FlowActionCallableHandlerTest {
    
    @isTest
    static void testCalculateAccumulatedAge() {
      case cs=  createCase();
        Map<String,Object>payload=new Map<String,object>();
        payload.put('record',cs);
        Map<Id,Case> csMap=new Map<Id,Case>();
        csMap.put(cs.Id,cs);
        payload.put('inputMap',csMap);
        FlowActionCallableHandler fac=new FlowActionCallableHandler();
        fac.call('calcualteAccumatedAge',payload);
      
    }
    
    @isTest
    static void testUpdateCaseOnEmailMessageResponse() {
        case cs=  createCase();
          EmailMessage emailMessage = new EmailMessage();
        emailMessage.Subject = 'Test Email';
        emailMessage.TextBody = 'This is a test email.';
        emailMessage.FromAddress = 'emeasupport_coz@barracuda.com';
        emailMessage.Incoming = true;
        emailMessage.parentId=cs.Id;
        // Insert the EmailMessage record
        insert emailMessage;
        
        Map<String,Object>payload=new Map<String,object>();
        FlowActionCallableHandler fac=new FlowActionCallableHandler();
        List<sObject> records=new List<sObject>{emailMessage};
        payload.put('updateCaseOnEmailMessageResponse',records);
        payload.put('updateFromAddress',records);
        payload.put('updateCaseEmail',records);
        payload.put('emailMessageUpdateCaseFromAddress',records);
        payload.put('emailUpdateCaseOwner',records);
        payload.put('handleEmailClosedCase',records);
        payload.put('emailMessageUpdates',records);
        payload.put('updatePSInternalEmail',records);
        Map<string,object> callerPayload=new Map<String,Object>();
            callerPayload.put('record',payload);
        Map<String,sObject> inputMap=new Map<String,sObject>();
        inputMap.put(cs.Id,Cs);
            callerPayload.put('inputMap', inputMap);
        
        fac.callAsync(callerPayload);
       
    }
    
    @isTest
    static void testCaseCustomerReply() {
       case cs=  createCase();
         EmailMessage emailMessage = new EmailMessage();
        emailMessage.Subject = 'Test Email';
        emailMessage.TextBody = 'This is a test email.';
        emailMessage.FromAddress = 'emeasupport_coz@barracuda.com';
        emailMessage.Incoming = true;
        emailMessage.parentId=cs.Id;
        // Insert the EmailMessage record
        insert emailMessage;
        Map<String,Object>payload=new Map<String,object>();
        FlowActionCallableHandler fac=new FlowActionCallableHandler();
        List<sObject> records=new List<sObject>{emailMessage};
        payload.put('caseCustomerReply',records);
        payload.put('updateFromAddress',records);
        payload.put('updateCaseEmail',records);
        payload.put('emailMessageUpdateCaseFromAddress',records);
        payload.put('emailUpdateCaseOwner',records);
        payload.put('handleEmailClosedCase',records);
        payload.put('emailMessageUpdates',records);
        payload.put('updatePSInternalEmail',records);
        
        Map<String,sObject> inputMap=new Map<String,sObject>();
        inputMap.put(cs.Id,Cs);
        Map<string,object> callerPayload=new Map<String,Object>();
            callerPayload.put('record',payload);
            callerPayload.put('inputMap', inputMap);
        fac.callAsync(callerPayload);

        
    }
    
    @isTest
    static void testHandleEmailClosedCase() {
        case cs=  createCase();
        // Create a new EmailMessage record
        EmailMessage emailMessage = new EmailMessage();
        
        // Set the properties
        emailMessage.Subject = 'Test Email';
        emailMessage.TextBody = 'This is a test email.';
        emailMessage.FromAddress = 'test@example.com';
        emailMessage.ToAddress = 'emeasupport_coz@barracuda.com';
        emailMessage.Incoming = true;
        emailMessage.Status='2';
        emailMessage.parentId=cs.Id;
        // Insert the EmailMessage record
        insert emailMessage;

        Map<String,Object>payload=new Map<String,object>();
        FlowActionCallableHandler fac=new FlowActionCallableHandler();
        List<sObject> records=new List<sObject>{emailMessage};
        payload.put('updateFromAddress',records);
        payload.put('updateCaseEmail',records);
        payload.put('emailMessageUpdateCaseFromAddress',records);
        payload.put('emailUpdateCaseOwner',records);
        payload.put('handleEmailClosedCase',records);
        payload.put('emailMessageUpdates',records);
        payload.put('updatePSInternalEmail',records);
        
        
        
            
        Map<String,sObject> inputMap=new Map<String,sObject>();
        inputMap.put(cs.Id,Cs);
        Map<string,object> callerPayload=new Map<String,Object>();
            callerPayload.put('record',payload);
            callerPayload.put('inputMap',inputMap);
        fac.callAsync(callerPayload);
         
    }
    
    @isTest
    static void testSendPremiumSupportNotification() {
        Map<String, Object> args = new Map<String, Object>();
        Map<String, object> recordMap = new Map<String, Object>();
        Map<String, sObject> payloadMap = new Map<String, sObject>();
        
        TriggerContextVariables.RUN_CASE_TRIGGER = false;
        case cs = createCase();  
        cs.From_Address_New__c = 'emeapremiumsupport_team@barracuda.com';
        cs.Premium_Emails__c = true;
        update cs;
        
        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Subject = 'Test Email';
        emailMessage.TextBody = 'This is a test email.';
        emailMessage.FromAddress = 'test@example.com';
        emailMessage.Incoming = false;
        emailMessage.Status='2';
        emailMessage.parentId=cs.Id;
        emailMessage.ToAddress = 'emeapremiumsupport_team@barracuda.com';
        insert emailMessage;      
        
        recordMap.put('sendPremiumSupportNotifications',new List<sObject>{emailMessage});
        payloadMap.put(cs.Id, cs);
        args.put('record', recordMap);
        args.put('inputMap', payloadMap);
        FlowActionCallableHandler fac=new FlowActionCallableHandler();
        fac.callAsync(args);        
    }
    
    @isTest
    static void testSendNotificationForAmericas() {        
        Map<String, Object> args = new Map<String, Object>();
        Map<String, object> recordMap = new Map<String, Object>();
        Map<String, sObject> payloadMap = new Map<String, sObject>();
        
        TriggerContextVariables.RUN_CASE_TRIGGER = false;
        case cs = createCase();  
        cs.From_Address_New__c = 'premiumsupport_team@barracuda.com';
        cs.Premium_Emails__c = true;
        update cs;
        
        EmailMessage emailMessage = new EmailMessage();
        emailMessage.Subject = 'Test Email';
        emailMessage.TextBody = 'This is a test email.';
        emailMessage.FromAddress = 'test@example.com';
        emailMessage.Incoming = false;
        emailMessage.Status='2';
        emailMessage.parentId=cs.Id;
        emailMessage.ToAddress = 'premiumsupport_team@barracuda.com';
        insert emailMessage;     
        
        recordMap.put('sendPremiumSupportNotifications',new List<sObject>{emailMessage});
        payloadMap.put(cs.Id, cs);
        args.put('record', recordMap);
        args.put('inputMap', payloadMap);
        FlowActionCallableHandler fac=new FlowActionCallableHandler();
        fac.callAsync(args);                
    }
    
    /*
    @isTest
    static void testAssignEntitlementForPremiumCase() {
         case cs=  createCase();
        Map<String,Object>payload=new Map<String,object>();
        payload.put('record',new EmailMessage(ParentId=cs.Id));
        Map<String,Case> csMap=new Map<String,Case>();
        csMap.put(cs.Id,cs);
        payload.put('inputMap',csMap);
        FlowActionCallableHandler fac=new FlowActionCallableHandler();
        fac.callAsync('assignEntitlementForPremiumCase',payload);
       
    }*/
    
    @isTest
    public static void emailUpdateCaseOwner(){
         case cs=  createCase();
        // Create a new EmailMessage record
        EmailMessage emailMessage = new EmailMessage();
        
        // Set the properties
        emailMessage.Subject = 'Test Email';
        emailMessage.TextBody = 'This is a test email.';
        emailMessage.FromAddress = 'test@example.com';
        emailMessage.Incoming = false;
        emailMessage.Status='2';
        emailMessage.parentId=cs.Id;
        // Insert the EmailMessage record
        insert emailMessage;

        Map<String,Object>payload=new Map<String,object>();
        FlowActionCallableHandler fac=new FlowActionCallableHandler();
        List<sObject> records=new List<sObject>{emailMessage};
        payload.put('updateFromAddress',records);
        payload.put('updateCaseEmail',records);
        payload.put('emailMessageUpdateCaseFromAddress',records);
        payload.put('emailUpdateCaseOwner',records);
        payload.put('handleEmailClosedCase',records);
        payload.put('emailMessageUpdates',records);
        payload.put('updatePSInternalEmail',records);
        payload.put('assignEntitlementForPremiumCase',records);
        
        
        
            
        Map<String,sObject> inputMap=new Map<String,sObject>();
        inputMap.put(cs.Id,Cs);
        Map<string,object> callerPayload=new Map<String,Object>();
            callerPayload.put('record',payload);
            callerPayload.put('inputMap',inputMap);
        fac.callAsync(callerPayload);
        
    }
    public static case createCase(){
       
        
        // Simulate a Trigger.new context with the relevant records
        List<sObject> testRecords = new List<sObject>();
        String webRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();
        String techRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
                Case csp=new Case(web_region__c='Americas',status='New',Priority='P2',Is_Premium_Support__c=true,recordtypeid=webRecordTypeID,Escalated_Date_Time__c=DateTime.now());

        insert csp;
        Case cs=new Case(web_region__c='Americas',ParentId=csp.Id,status='New',recordtypeid=webRecordTypeID,Escalated_Date_Time__c=DateTime.now());
        insert cs;
        return cs;
        
        
    }
     public static case webCreateCase(){
       
        
        // Simulate a Trigger.new context with the relevant records
        List<sObject> testRecords = new List<sObject>();
        String webRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();
        String techRecordTypeID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
                Case csp=new Case(web_region__c='Americas',status='New',Priority='P2',Is_Premium_Support__c=true,recordtypeid=webRecordTypeID,Escalated_Date_Time__c=DateTime.now());

        insert csp;
        Case cs=new Case(web_region__c='Americas',ParentId=csp.Id,status='New',recordtypeid=webRecordTypeID,Escalated_Date_Time__c=DateTime.now());
        
         insert cs;
         cs.Status='Waiting for Customer Response';
         update cs;
        return cs;
        
        
    }
}