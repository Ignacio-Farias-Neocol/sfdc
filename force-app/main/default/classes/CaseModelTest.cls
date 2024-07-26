/**
* Created by iyeung on 1/22/19.

* @Modification
* SFDC-13763: Changed code to replace From_Address__c to From_Address_New__c
*/

@isTest public class CaseModelTest
{
    @testSetup
    public static void setRecord(){
        
        Profile prfile = [select Id,name from Profile where  name='System Administrator' limit 1];
        
        User newUser1 = new User(
            profileId = prfile.id,
            username = 'newUsertestt@yahoo.com' + System.currentTimeMillis(),
            email = 'pb@f.com',
            emailencodingkey = 'UTF-8',
            localesidkey = 'en_US',
            languagelocalekey = 'en_US',
            timezonesidkey = 'America/Los_Angeles',
            alias='nuser',
            lastname='lastname'
        );
        insert newUser1; 
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Create_Edit_State_Country_Territory_Data'];
        insert new PermissionSetAssignment(AssigneeId = newUser1.id, PermissionSetId = ps.Id);
        
    }
    
    @isTest
    static void test_populateCaseContact(){
        
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            // by pass business action ,
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
            TriggerContextVariables.RUN_CASE_TRIGGER = false;
            List <Case> l = TestDataFactory.webCases;
            TriggerHandler.clearAllBypasses();
            
            CaseModel.populateCaseContact(l);
        }
        
    }
    
    
    @isTest
    static void test_populateWebSerial(){
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            
            // by pass business action ,
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
            TriggerContextVariables.RUN_CASE_TRIGGER = false;
            List <Case> l = TestDataFactory.webCases;
            TriggerHandler.clearAllBypasses();
            
            // to do: set up assigned serial test data
            Test.startTest();
            
            DynamicBusinessRuleCaseWeb dw = new DynamicBusinessRuleCaseWeb();
            dw.processRecords(null, null, l, '', '', ''); // CaseModel.populateWebSerial(l);
            
            DynamicBusinessRuleCaseAsset d = new DynamicBusinessRuleCaseAsset();
            d.processRecords(null, null, l, '', '', '');   // CaseModel.populateSerialAsset(l);
            
            DynamicBusinessRuleCaseAssignment dg = new DynamicBusinessRuleCaseAssignment();
            dg.processRecords(null, null, l, '', '', '');   // CaseModel.assignCase(ids);
            Test.stopTest();
        }
        
    }
    
    
    @isTest
    static void test_processLiveChatSalesCases(){
        
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            // by pass business action ,
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
            List <Case> l = TestDataFactory.offlineCases;
            TriggerHandler.clearAllBypasses();
            
            CaseModel.processLiveChatCases(l);
        }
        
    }
    
    @isTest
    static void test_processLiveChatSupportCases(){
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            // by pass business action
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
            List <Case> l = TestDataFactory.offlineCases;
            l[0].Offline_Support_Type__c = 'Support';
            TriggerHandler.clearAllBypasses();
            
            CaseModel.processLiveChatCases(l);
        }
    }
    
    @isTest
    static void test_completeMilestone(){
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            // by pass business action ,
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
            List <Case> l = TestDataFactory.offlineCases;
            TriggerHandler.clearAllBypasses();
            
            String jsonParameter = '{"milestoneName1" :"Premium Cases - P1", "milestoneName2" :"Premium Cases - P2", "milestoneName3" :"Premium Cases - P3", "milestoneName4" :"Premium Cases - P4" }';
            
            Test.startTest();
            DynamicBusinessRuleCaseMilestone d = new DynamicBusinessRuleCaseMilestone();
            d.processRecords(null, null, l, jsonParameter, '', '');   CaseModel.completeMilestone(l, jsonParameter, Date.today());
            Test.stopTest();
        }
    }
    
    @isTest
    static void test_populateSerialAssetReplacement(){
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            try {
                // by pass business action
                TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active  
                List<Account> lAccounts = TestDataFactory.customers;
                
                Product2 prod = new Product2();
                prod.Name = 'PremSup Instant Replacement Support Product';
                prod.ProductCode = '1234';
                prod.is_pst_enterprise__c = true;
                insert prod;
                
                Serial__c serial = new Serial__c();
                serial.Activation_Date__c = Date.today();
                serial.Serial_Number__c = String.valueOf(Math.random() * 10000000).left(6);
                serial.Status__c = 'Active';
                insert serial;
                
                SBQQ__Subscription__c subs = new SBQQ__Subscription__c();
                subs.SBQQ__RootId__c = String.valueOf(serial.Id);
                subs.SBQQ__Account__c = lAccounts[0].Id;
                subs.SBQQ__SubscriptionStartDate__c = Date.Today().addDays(-7); 
                subs.SBQQ__SubscriptionEndDate__c = Date.Today().addDays(7);
                subs.SBQQ__Quantity__c = 8;
                subs.SBQQ__Product__c = prod.Id; 
                insert subs;
                
                Asset asset = new Asset();
                asset.Name = 'test_Instant Replacement_Support_Product';
                asset.AccountId = lAccounts[0].Id;
                asset.Product2Id = prod.Id;
                asset.SerialNumber = serial.Serial_Number__c;
                asset.BNCPQ_Serial__c = serial.Id;
                insert asset;
                
                Assigned_Serial__c assignedSerial = new Assigned_Serial__c();
                //assignedSerial.Asset__c = asset.id;
                assignedSerial.Serial__c = serial.Id;
                assignedSerial.Status__c = 'Active';
                insert assignedSerial;
                
                Contact con = new Contact();
                con.LastName = 'Doe' + ' ' + '1234';
                con.FirstName = 'John';
                con.Email = 'John.Doe@test.com';
                con.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
                con.AccountId = lAccounts[0].Id;
                con.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
                con.LeadSource = 'Renewal';
                insert con;
                
                Case cse = new Case();
                cse.Description = 'Web Case 1234';
                cse.Status = 'New';
                cse.Web_First_Name__c = con.FirstName;
                cse.Web_Last_Name__c = con.LastName;
                cse.SuppliedEmail = con.Email;
                cse.Subject = 'Unit Test 1234';
                cse.Origin = 'Web';
                cse.Web_Language_of_correspondence__c = 'English';
                cse.Web_Region__c = 'Americas';
                cse.Offline_Support_Type__c = 'Sales'; 
                cse.New_Case_Notification_Sent__c = false; 
                cse.Web_Serial__c = serial.Serial_Number__c;
                cse.Callback_Date_Time__c = system.now();
                cse.Serial__c = serial.Id;
                cse.recordTypeId =   Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Offline').getRecordTypeId();
                insert cse;
                
                List<Case> lCases = new List<Case>();
                lCases.add(cse);
                TriggerHandler.clearAllBypasses();
                
                CaseModel.populateSerialAsset(lCases);
            }catch(Exception err) {
                System.debug('@@Error at populateSerialAsset: '+err.getMessage());
            }  }  
        
    }
    
    @isTest
    static void test_assignCase(){
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            // by pass business action ,
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active 
            List<Case> lCases = TestDataFactory.offlineCases;
            TriggerHandler.clearAllBypasses();
            List<Id> lIds = new List<Id>();
            for(Case c:lCases) {
                lIds.add(c.Id);
            }
            
            CaseModel.assignCase(lIds);
        }
    }
    
    @isTest
    static void test_createLead1(){
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            // by pass business action ,
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active 
            List<Case> lCases = TestDataFactory.offlineCases;
            TriggerHandler.clearAllBypasses();      
            
            CaseModel.createLead('Test_CaseModelFName','Test_CaseModelLName','Test_CaseModel@test.com','','');
        }
    }
    
    @isTest
    static void test_createLead2(){
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            // by pass business action ,
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active 
            List<Lead> lLeads = TestDataFactory.postMQLLeads;
            TriggerHandler.clearAllBypasses();      
            
            CaseModel.createLead(lLeads[0].FirstName,lLeads[0].LastName,lLeads[0].Email,'','');
        }
    }
    
    @isTest
    static void test_createLeadError(){
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            // by pass business action ,
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active 
            List<Lead> lLeads = TestDataFactory.postMQLLeads;
            TriggerHandler.clearAllBypasses();      
            
            CaseModel.createLead('Test_CaseModelFName','Test_CaseModelLName','Test_CaseModel','','');
        }
    }
    
    @isTest
    static void test_PopulateSendCallbackNotificationOnUpdate(){
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            List<Case> caseList = TestDataFactory.supportCases;
            for(Case caseRecord: caseList){
                // case callbackfunctionality
                caseRecord.Callback_Date_Time__c = System.now().addDays(2);
                caseRecord.Callback_TimeZone__c = '(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi';            
            }
            upsert caseList;
        }
    }
    
    @isTest
    static void test_PopulateSendCallbackNotificationOnInsert(){
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            List<Case> caseList = TestDataFactory.supportCases;
            List<Case> newCaseList = new List<Case>();
            for(Case caseRecord: caseList){
                Case newCaseRecord = new Case();
                newCaseRecord = caseRecord.clone(false, true, false, false);
                
                // case callbackfunctionality
                newCaseRecord.Callback_Date_Time__c = System.now().addDays(2);
                newCaseRecord.Callback_TimeZone__c = '(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi'; 
                newCaseRecord.Product_Family_List__c='Backup Server/Service';
                newCaseRecord.Missing_Serial_Number__c = 'abc';
                newCaseList.add(newCaseRecord);
            }
            
            Test.startTest();
            insert newCaseList;
            Test.stopTest();
        }
    }  
    
    
    @isTest
    static void beforeInsertHelper_test(){
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            String INTERNAL_TICKET_COMMUNITIES_QUEUE_ID = [Select Id, Name, Type from Group where Name = 'Internal Ticket - Communities' and Type = 'Queue'].Id;
            Case cse = new Case();
            cse.Description = 'Web Case 1234';
            cse.Status = 'New';
            cse.Subject = 'Unit Test 1234';
            cse.Origin = 'Web';
            cse.Web_Language_of_correspondence__c = 'English';
            cse.Web_Region__c = 'Americas';
            cse.Offline_Support_Type__c = 'Sales'; 
            cse.New_Case_Notification_Sent__c = false; 
            cse.OwnerId = INTERNAL_TICKET_COMMUNITIES_QUEUE_ID;
            
            Test.startTest();
            insert cse;
            
            cse.OwnerId = UserInfo.getUserId();
            cse.Completed_Milestone_Status__c = null;
            cse.Status = 'Resolved';
            update cse; 
             cse.Status = 'In Progress';
             update cse; 
            Test.stopTest();
        }
    }  
    
    /*
@isTest
static void beforeInsertHelper_test2(){
String INTERNAL_TICKET_COMMUNITIES_QUEUE_ID = [Select Id, Name, Type from Group where Name = 'Internal Ticket - Communities' and Type = 'Queue'].Id;
Case cse = new Case();
cse.Description = 'Web Case 1234';
cse.Status = 'New';
cse.Subject = 'Unit Test 1234';
cse.Origin = 'Web';
cse.Web_Language_of_correspondence__c = 'English';
cse.Web_Region__c = 'Americas';
cse.Offline_Support_Type__c = 'Sales'; 
cse.New_Case_Notification_Sent__c = false; 
insert cse;

Test.startTest();        
cse.OwnerId = UserInfo.getUserId();
cse.Completed_Milestone_Status__c = null;
update cse;    
Test.stopTest();
}  */
    
    
    @isTest
    static void beforeInsertHelper_test3(){
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            String INTERNAL_TICKET_COMMUNITIES_QUEUE_ID = [Select Id, Name, Type from Group where Name = 'Internal Ticket - Communities' and Type = 'Queue'].Id;
            Case cse = new Case();
            cse.Description = 'Web Case 1234';
            cse.Status = 'New';
            cse.Subject = 'Unit Test 1234';
            cse.Origin = 'Web';
            cse.Web_Language_of_correspondence__c = 'English';
            cse.Web_Region__c = 'Americas';
            cse.Offline_Support_Type__c = 'Sales'; 
            cse.New_Case_Notification_Sent__c = false; 
            cse.OwnerId = INTERNAL_TICKET_COMMUNITIES_QUEUE_ID;
            insert cse;
            
            Test.startTest();        
            cse.OwnerId = UserInfo.getUserId();
            cse.Completed_Milestone_Status__c = 'Violation';
            update cse;    
            Test.stopTest();
        }
    }   
    
     @isTest
    static void beforeInsertHelper_test03(){
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            try {
                // by pass business action
                TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active  
                List<Account> lAccounts = TestDataFactory.customers;
               lAccounts[0].Compliance_Status__c = 'Banned';
                update lAccounts[0];
                
                Serial__c serial = new Serial__c();
                serial.Activation_Date__c = Date.today();
                serial.Serial_Number__c = String.valueOf(Math.random() * 10000000).left(6);
                serial.Status__c = 'Active';
                serial.Account__c=lAccounts[0].Id;
                insert serial;
                

 
                
                Contact con = new Contact();
                con.LastName = 'Doe' + ' ' + '1234';
                con.FirstName = 'John';
                con.Email = 'John.Doe@test.com';
                con.Contact_Status__c = 'Active';  // Note: DPL check will change this status to 'Pending'
                con.AccountId = lAccounts[0].Id;
                con.recordTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
                con.LeadSource = 'Renewal';
                insert con;
                
                Case cse = new Case();
 				cse.AccountId = lAccounts[0].Id;
                cse.ContactId = con.Id;
                cse.Description = 'Web Case 1234';
                cse.Status = 'New';
                cse.Web_First_Name__c = con.FirstName;
                cse.Web_Last_Name__c = con.LastName;
                cse.SuppliedEmail = con.Email;
                cse.Subject = 'Unit Test 1234';
                cse.Origin = 'Web';
                cse.Web_Language_of_correspondence__c = 'English';
                cse.Web_Region__c = 'Americas';
                cse.Offline_Support_Type__c = 'Sales'; 
                cse.New_Case_Notification_Sent__c = false; 
                cse.Web_Serial__c = serial.Serial_Number__c;
                cse.Callback_Date_Time__c = system.now();
                cse.Serial__c = serial.Id;
                cse.recordTypeId =   Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Offline').getRecordTypeId();
                insert cse;
                
                List<Case> lCases = new List<Case>();
                lCases.add(cse);
                TriggerHandler.clearAllBypasses();
                
                CaseModel.populateSerialAsset(lCases);
            }catch(Exception err) {
                System.debug('@@Error at populateSerialAsset: '+err.getMessage());
            }  }  
        
    }
    
    /*
@isTest
static void test_checkIfPremiumSupportCaseForAmericas(){

//initial setup
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

// by pass business action ,
TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
List <Case> l = TestDataFactory.webCases;
TriggerHandler.clearAllBypasses();

// assign from address
for(Case caseRecord: l){
//  caseRecord.From_Address__c = 'premiumsupport_team_qa@barracuda.com'; //SFDC-13763
caseRecord.From_Address_New__c= 'premiumsupport_team_qa@barracuda.com';
caseRecord.OwnerId = americaQueueId;
}

Case newCaseRecord = l[0].clone(false, true, false, false);

// to do: set up assigned serial test data
Test.startTest();
CaseModel.checkIfPremiumSupportCase(l);
insert newCaseRecord;
Test.stopTest();
}    

@isTest
static void test_checkIfPremiumSupportCaseForEMEA(){

//initial setup
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

// by pass business action ,
TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
List <Case> l = TestDataFactory.webCases;
TriggerHandler.clearAllBypasses();

// assign from address
for(Case caseRecord: l){
// caseRecord.From_Address__c = ' emeapremiumsupport_team_qa@barracuda.com'; //SFDC-13763
caseRecord.From_Address_New__c= ' emeapremiumsupport_team_qa@barracuda.com';
caseRecord.OwnerId = emeaQueueId;
}

Case newCaseRecord = l[0].clone(false, true, false, false);

// to do: set up assigned serial test data
Test.startTest();
CaseModel.checkIfPremiumSupportCase(l);
insert newCaseRecord;
Test.stopTest();
}    

@isTest
static void test_checkIfPremiumSupportCaseForIndia(){

//initial setup
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

// by pass business action ,
TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); // among other things, keep the contact status as active
List <Case> l = TestDataFactory.webCases;
TriggerHandler.clearAllBypasses();

// assign from address
for(Case caseRecord: l){
// caseRecord.From_Address__c = 'wafpremiumsupport_team_qa@barracuda.com'; SFDC-13763
caseRecord.From_Address_New__c= 'wafpremiumsupport_team_qa@barracuda.com';
caseRecord.OwnerId = indiaQueueId;
}

Case newCaseRecord = l[0].clone(false, true, false, false);

// to do: set up assigned serial test data
Test.startTest();
CaseModel.checkIfPremiumSupportCase(l);
insert newCaseRecord;
Test.stopTest();
}  
*/
    
    @isTest
    static void testMethod01(){
        User usr=[Select id From User where userName like 'newUsertestt@yahoo.com%' limit 1];
        System.runAs(usr){
            try {           
                Id americaQueueId;
                Id mwQueueId;
                Id mspQueueId;
                Id sonianQueueId;
                Id indiaQueueId;
                Id emeaQueueId;   
                Id chinaQueueId;
                Id japanQueueId;
                
                List<String> strList = new List<String>();
                
                Map<Id, Group> groupMap = new Map<Id, Group>([Select Id, Name, DeveloperName, Type from Group 
                                                              where Type = 'Queue' and DeveloperName in 
                                                              ('Contact_Center_Americas', 'Barracuda_MSP', 'WM_Sonian', 'WM_Managed_Workplace', 'Contact_Center_EMEA', 
                                                               'Contact_Center_India', 'Contact_Center_China', 'Support_Japan')]);
                for(Group groupRecord: groupMap.values()){
                    if(groupRecord.DeveloperName == 'Contact_Center_Americas'){
                        americaQueueId = groupRecord.Id;
                    } else if(groupRecord.DeveloperName == 'Barracuda_MSP'){
                        mspQueueId = groupRecord.Id;
                    } else if(groupRecord.DeveloperName == 'WM_Sonian'){
                        sonianQueueId = groupRecord.Id;
                    } else if(groupRecord.DeveloperName == 'WM_Managed_Workplace'){
                        mwQueueId = groupRecord.Id;
                    } else if(groupRecord.DeveloperName == 'Contact_Center_EMEA'){
                        emeaQueueId = groupRecord.Id;
                    } else if(groupRecord.DeveloperName == 'Contact_Center_India'){
                        indiaQueueId = groupRecord.Id;
                    } else if(groupRecord.DeveloperName == 'Contact_Center_China'){
                        chinaQueueId = groupRecord.Id;
                    } else if(groupRecord.DeveloperName == 'Support_Japan'){
                        japanQueueId = groupRecord.Id;
                    }
                }            
                TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
                List<Case> lCase = TestDataFactory.webCases;
                TriggerHandler.clearAllBypasses();
                
                for(Case caseRecord: lCase){
                    caseRecord.From_Address_New__c = 'professionalservice@barracuda.com';
                    caseRecord.OwnerId = americaQueueId;
                }       
                CaseModel.updateCaseSupportRegion(lCase);      
                
                for(Case caseRecord: lCase){
                    //caseRecord.From_Address_New__c = 'professionalservice@barracuda.com';
                    caseRecord.OwnerId = indiaQueueId;
                }       
                CaseModel.updateCaseSupportRegion(lCase); 
                
                for(Case caseRecord: lCase){
                    //caseRecord.From_Address_New__c = 'professionalservice@barracuda.com';
                    caseRecord.OwnerId = emeaQueueId;
                }       
                CaseModel.updateCaseSupportRegion(lCase); 
                
                for(Case caseRecord: lCase){
                    //caseRecord.From_Address_New__c = 'professionalservice@barracuda.com';
                    caseRecord.OwnerId = chinaQueueId;
                }       
                CaseModel.updateCaseSupportRegion(lCase);             
                
            }catch(Exception err) {
                system.debug('@@Error:'+err.getMessage());
            }           
        }  
    }
    
}