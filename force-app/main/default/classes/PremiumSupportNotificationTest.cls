@isTest
public class PremiumSupportNotificationTest
{
    @testSetup 
    static void createRecs() {
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');		
        List <Group> lGroup = new List <Group>();
        Group gAmericas = new Group(Name='Americas_Premium',Type='Regular');
        Group gEmea = new Group(Name='EMEA_Premium',Type='Regular');
        Group gIndia = new Group(Name='India_Premium',Type='Regular');
        lGroup.add(gAmericas);
        lGroup.add(gEmea);
        lGroup.add(gIndia);
        insert lGroup;                  
        
        List <GroupMember> lGm = new List <GroupMember>();
        GroupMember gmAmericas = new GroupMember(GroupId=lGroup[0].Id,UserOrGroupId=UserInfo.getUserId());
        GroupMember gmEmea = new GroupMember(GroupId=lGroup[1].Id,UserOrGroupId=UserInfo.getUserId());
        GroupMember gmIndia = new GroupMember(GroupId=lGroup[2].Id,UserOrGroupId=UserInfo.getUserId());
        lGm.add(gmAmericas);
        lGm.add(gmEmea);
        lGm.add(gmIndia);
        insert lGm;
        TriggerHandler.clearAllBypasses();
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
    
    @isTest static void testPremiumNotif() {
        try {            
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
            List <Case> lCase = TestDataFactory.webCases;
            TriggerHandler.clearAllBypasses();
            
            Id americaQueueId;
            Id indiaQueueId;
            Id emeaQueueId;        
            
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
            
            TriggerContextVariables.RUN_CASE_TRIGGER = false;
            case cs = createCase();  
            cs.From_Address_New__c = 'premiumsupport_team@barracuda.com';
            cs.Premium_Emails__c = true;
            cs.OwnerId = americaQueueId;
            update cs;
            
            EmailMessage emailMessage = new EmailMessage();
            emailMessage.Subject = 'Test Email';
            emailMessage.TextBody = 'This is a test email.';
            emailMessage.FromAddress = 'premiumsupport_team@barracuda.com';
            emailMessage.Incoming = false;
            emailMessage.Status='2';
            emailMessage.parentId=cs.Id;
            emailMessage.ToAddress = 'premiumsupport_team@barracuda.com';
            insert emailMessage;             
            
            Test.startTest();			
            PremiumSupportNotification.sendEmail(emailMessage, 'premiumsupport_team@barracuda.com');
            Test.stopTest();
        }catch(Exception err) {
            system.debug('@@Error:'+err.getMessage());
        }
    }
    
    @isTest static void testPremiumNotif02() {
        try {            
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
            List <Case> lCase = TestDataFactory.webCases;
            TriggerHandler.clearAllBypasses();
            
            Id americaQueueId;
            Id indiaQueueId;
            Id emeaQueueId;        
            
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
            
            TriggerContextVariables.RUN_CASE_TRIGGER = false;
            case cs = createCase();  
            cs.From_Address_New__c = 'emeapremiumsupport_team@barracuda.com';
            cs.Premium_Emails__c = true;
            cs.OwnerId = emeaQueueId;
            update cs;
            
            EmailMessage emailMessage = new EmailMessage();
            emailMessage.Subject = 'Test Email';
            emailMessage.TextBody = 'This is a test email.';
            emailMessage.FromAddress = 'premiumsupport_team@barracuda.com';
            emailMessage.Incoming = false;
            emailMessage.Status='2';
            emailMessage.parentId=cs.Id;
            emailMessage.ToAddress = 'emeapremiumsupport_team@barracuda.com';
            insert emailMessage;             
            
            Test.startTest();			
            PremiumSupportNotification.sendEmail(emailMessage, 'emeapremiumsupport_team@barracuda.com');
            Test.stopTest();
        }catch(Exception err) {
            system.debug('@@Error:'+err.getMessage());
        }
    }
    
    
    @isTest static void testPremiumNotif03() {
        try {            
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
            List <Case> lCase = TestDataFactory.webCases;
            TriggerHandler.clearAllBypasses();
            
            Id americaQueueId;
            Id indiaQueueId;
            Id emeaQueueId;        
            
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
            
            TriggerContextVariables.RUN_CASE_TRIGGER = false;
            case cs = createCase();  
            cs.From_Address_New__c = 'wafpremium_team@barracuda.com';
            cs.Premium_Emails__c = true;
            cs.OwnerId = indiaQueueId;
            update cs;
            
            EmailMessage emailMessage = new EmailMessage();
            emailMessage.Subject = 'Test Email';
            emailMessage.TextBody = 'This is a test email.';
            emailMessage.FromAddress = 'wafpremium_team@barracuda.com';
            emailMessage.Incoming = false;
            emailMessage.Status='2';
            emailMessage.parentId=cs.Id;
            emailMessage.ToAddress = 'emeapremiumsupport_team@barracuda.com';
            insert emailMessage;             
            
            Test.startTest();			
            PremiumSupportNotification.sendEmail(emailMessage, 'wafpremium_team@barracuda.com');
            Test.stopTest();
        }catch(Exception err) {
            system.debug('@@Error:'+err.getMessage());
        }
    }
        
    
    
    /*
    @isTest static void testPremiumNotif02() {
        try {            
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
            List <Case> lCase = TestDataFactory.webCases;
            lCase[0].From_Address_New__c = 'premiumsupport_team@barracuda.com;emeapremiumsupport_team@barracuda.com;wafpremiumsupport_team@barracuda.com';
            lCase[0].OwnerId = [Select Id from Group where Name = 'Contact Center: Americas'].Id;
            update lCase;
            System.debug('##lCase:: ' + JSON.serialize(lCase));
            TriggerHandler.clearAllBypasses();
            //Case cs = [SELECT Id,CaseNumber FROM Case WHERE Subject LIKE 'Unit Test%' LIMIT 1];
            List <PremiumSupportNotification.NotificationInputs> lInps = new List <PremiumSupportNotification.NotificationInputs>();
            PremiumSupportNotification.NotificationInputs inp = new PremiumSupportNotification.NotificationInputs();
            inp.FromAddress = 'test@gmail.com';
            inp.caseNum = lCase[0].CaseNumber;
            inp.subject = 'Test_PremiumSupportNotification_CaseSubject';
            inp.emailId = 'premiumsupport_team@barracuda.com;emeapremiumsupport_team@barracuda.com;wafpremiumsupport_team@barracuda.com';
            lInps.add(inp);
            
            Test.startTest();			
            PremiumSupportNotification.sendEmail(lInps);
            //PremiumSupportNotification.updateCase(String.valueOf(lCase[0].Id));
            Test.stopTest();
        }catch(Exception err) {
            system.debug('@@Error:'+err.getMessage());
        }
    }
    
    @isTest static void testPremiumNotif03() {
        try {            
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
            List <Case> lCase = TestDataFactory.webCases;
            lCase[0].From_Address_New__c = 'premiumsupport_team@barracuda.com;emeapremiumsupport_team@barracuda.com;wafpremiumsupport_team@barracuda.com';
            lCase[0].OwnerId = [Select Id from Group where Name = 'Contact Center: EMEA'].Id;
            update lCase;
            System.debug('##lCase:: ' + JSON.serialize(lCase));
            TriggerHandler.clearAllBypasses();
            //Case cs = [SELECT Id,CaseNumber FROM Case WHERE Subject LIKE 'Unit Test%' LIMIT 1];
            List <PremiumSupportNotification.NotificationInputs> lInps = new List <PremiumSupportNotification.NotificationInputs>();
            PremiumSupportNotification.NotificationInputs inp = new PremiumSupportNotification.NotificationInputs();
            inp.FromAddress = 'test@gmail.com';
            inp.caseNum = lCase[0].CaseNumber;
            inp.subject = 'Test_PremiumSupportNotification_CaseSubject';
            inp.emailId = 'premiumsupport_team@barracuda.com;emeapremiumsupport_team@barracuda.com;wafpremiumsupport_team@barracuda.com';
            lInps.add(inp);
            
            Test.startTest();			
            PremiumSupportNotification.sendEmail(lInps);
            //PremiumSupportNotification.updateCase(String.valueOf(lCase[0].Id));
            Test.stopTest();
        }catch(Exception err) {
            system.debug('@@Error:'+err.getMessage());
        }
    }  
    
    @isTest static void testPremiumNotif04() {
        try {            
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
            List <Case> lCase = TestDataFactory.webCases;
            //lCase[0].From_Address_New__c = 'premiumsupport_team@barracuda.com;emeapremiumsupport_team@barracuda.com;wafpremiumsupport_team@barracuda.com';
            lCase[0].OwnerId = [Select Id from Group where Name = 'Contact Center: India'].Id;
            update lCase;
            System.debug('##lCase:: ' + JSON.serialize(lCase));
            TriggerHandler.clearAllBypasses();
            //Case cs = [SELECT Id,CaseNumber FROM Case WHERE Subject LIKE 'Unit Test%' LIMIT 1];
            List <PremiumSupportNotification.NotificationInputs> lInps = new List <PremiumSupportNotification.NotificationInputs>();
            PremiumSupportNotification.NotificationInputs inp = new PremiumSupportNotification.NotificationInputs();
            inp.FromAddress = 'test@gmail.com';
            inp.caseNum = lCase[0].CaseNumber;
            inp.subject = 'Test_PremiumSupportNotification_CaseSubject';
            inp.emailId = 'premiumsupport_team@barracuda.com;emeapremiumsupport_team@barracuda.com;wafpremiumsupport_team@barracuda.com';
            lInps.add(inp);
            
            Test.startTest();			
            PremiumSupportNotification.sendEmail(lInps);
            //PremiumSupportNotification.updateCase(String.valueOf(lCase[0].Id));
            Test.stopTest();
        }catch(Exception err) {
            system.debug('@@Error:'+err.getMessage());
        }
    }   
    
    @isTest static void testPremiumNotif05() {
        try {            
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
            List <Case> lCase = TestDataFactory.webCases;
            TriggerHandler.clearAllBypasses();
            //Case cs = [SELECT Id,CaseNumber FROM Case WHERE Subject LIKE 'Unit Test%' LIMIT 1];
            List <PremiumSupportNotification.NotificationInputs> lInps = new List <PremiumSupportNotification.NotificationInputs>();
            PremiumSupportNotification.NotificationInputs inp = new PremiumSupportNotification.NotificationInputs();
            inp.FromAddress = 'test@gmail.com';
            inp.caseNum = '01234';
            inp.subject = 'Test_PremiumSupportNotification_CaseSubject';
            inp.emailId = 'emeapremiumsupport_team@barracuda.com';
            lInps.add(inp);
            
            Test.startTest();			
            PremiumSupportNotification.sendEmail(lInps);
            //PremiumSupportNotification.updateCase(String.valueOf(lCase[0].Id));
            Test.stopTest();
        }catch(Exception err) {
            system.debug('@@Error:'+err.getMessage());
        }
    }
    
    @isTest static void testPremiumNotif06() {
        try {            
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
            List <Case> lCase = TestDataFactory.webCases;
            TriggerHandler.clearAllBypasses();
            //Case cs = [SELECT Id,CaseNumber FROM Case WHERE Subject LIKE 'Unit Test%' LIMIT 1];
            List <PremiumSupportNotification.NotificationInputs> lInps = new List <PremiumSupportNotification.NotificationInputs>();
            PremiumSupportNotification.NotificationInputs inp = new PremiumSupportNotification.NotificationInputs();
            inp.FromAddress = 'test@gmail.com';
            inp.caseNum = '01234';
            inp.subject = 'Test_PremiumSupportNotification_CaseSubject';
            inp.emailId = 'premiumsupport_team@barracuda.com';
            lInps.add(inp);
            
            Test.startTest();			
            PremiumSupportNotification.sendEmail(lInps);
            //PremiumSupportNotification.updateCase(String.valueOf(lCase[0].Id));
            Test.stopTest();
        }catch(Exception err) {
            system.debug('@@Error:'+err.getMessage());
        }
    }  
    
    @isTest static void testPremiumNotif07() {
        try {            
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
            List <Case> lCase = TestDataFactory.webCases;
            lCase[0].From_Address_New__c = 'premiumsupport_team@barracuda.com;emeapremiumsupport_team@barracuda.com;wafpremiumsupport_team@barracuda.com';
            lCase[0].OwnerId = [Select Id from Group where Name = 'Contact Center: India'].Id;
            update lCase;
            System.debug('##lCase:: ' + JSON.serialize(lCase));
            TriggerHandler.clearAllBypasses();
            //Case cs = [SELECT Id,CaseNumber FROM Case WHERE Subject LIKE 'Unit Test%' LIMIT 1];
            List <PremiumSupportNotification.NotificationInputs> lInps = new List <PremiumSupportNotification.NotificationInputs>();
            PremiumSupportNotification.NotificationInputs inp = new PremiumSupportNotification.NotificationInputs();
            inp.FromAddress = 'test@gmail.com';
            inp.caseNum = lCase[0].CaseNumber;
            inp.subject = 'Test_PremiumSupportNotification_CaseSubject';
            inp.emailId = 'premiumsupport_team@barracuda.com;emeapremiumsupport_team@barracuda.com;wafpremiumsupport_team@barracuda.com';
            lInps.add(inp);
            
            Test.startTest();			
            PremiumSupportNotification.sendEmail(lInps);
            //PremiumSupportNotification.updateCase(String.valueOf(lCase[0].Id));
            Test.stopTest();
        }catch(Exception err) {
            system.debug('@@Error:'+err.getMessage());
        }
    }     
	*/
}