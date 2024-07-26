/**
*  @author Ivan Yeung
*  @date 12/05/2018
*  @group Model
*  @description  model class for case object
* @Modification
* SFDC-13763: Changed code to replace From_Address__c to From_Address_New__c
*/
public without sharing class CaseModel {
    
    public static final String OFFLINE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Offline').getRecordTypeId();  // '0123C000000ErI8QAK';
    public static final String WEB_MESSAGE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Web_Case').getRecordTypeId();  // '0123C0000006R7kQAE';
    public static final String PROFESSIONAL_SERVICES_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Professional_Services').getRecordTypeId();  
    public static final String TECH_SUPPORT_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();
    public static final String DPAAS_RECORD_TYPE_ID = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('DPAAS_Cases').getRecordTypeId();
    public static final String REQUEST_QUOTE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Request_Quote').getRecordTypeId();
    public static final String COMMUNITY_HELP_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Community_Help').getRecordTypeId();  // '0123C0000006R7kQAE';
    public static final String INTERNAL_TICKET_COMMUNITIES_QUEUE_ID = [Select Id, Name, Type from Group where Name = 'Internal Ticket - Communities' and Type = 'Queue'].Id;
    public static Boolean isUpdateCompletedMilestoneStatusInvoked = false;
    public static set<String> internalTicketEntitlementQueuesSet = new Set<String>();
    public static set<String> milestoneCompleteStatusSet = new Set<String>();
    public static Map<Id,Group> GroupMap;
    public static Map<Id,User> UserMap;
    
    static {        
        internalTicketEntitlementQueuesSet.add('Internal Ticket - General Queue (Tier 1)');
        internalTicketEntitlementQueuesSet.add('Internal Ticket - Tier 1');
        internalTicketEntitlementQueuesSet.add('Internal Ticket - Tier 2');
        internalTicketEntitlementQueuesSet.add('Internal Ticket - Customer Services');
        internalTicketEntitlementQueuesSet.add('Internal Ticket - Auto-Renewals');
        internalTicketEntitlementQueuesSet.add('Internal Ticket - HWW Queue');
        internalTicketEntitlementQueuesSet.add('Internal Ticket - RMA');
        internalTicketEntitlementQueuesSet.add('Internal Ticket - Trade Compliance');
        internalTicketEntitlementQueuesSet.add('Internal Ticket - Sales Ops Queue');
        internalTicketEntitlementQueuesSet.add('Internal Ticket – NPI');
        internalTicketEntitlementQueuesSet.add('Internal Ticket - Sales Enhancement Queue');
        milestoneCompleteStatusSet.add('Cancelled');
        milestoneCompleteStatusSet.add('Waiting for Requester Response');
        milestoneCompleteStatusSet.add('Response Received');
        milestoneCompleteStatusSet.add('Jira_Ticket_Opened');
        milestoneCompleteStatusSet.add('Backlog');
        milestoneCompleteStatusSet.add('Closed');
    }    
    /*******************************************************************************************************
* @description set the contact lookup field based upon the web form fields
* @param trigger.new map
* @return none, the result should be set to the records itself
* @example
*/
    public static List <Case>  populateCaseContact( List <SObject> records ){
        
        
        List <Case> modifiedCases = new List <Case>();
        
        Set <String> firstNames = new Set<String>();
        Set <String> lastNames = new Set<String>();
        Set <String> emails = new Set<String>();
        Set <String> caseNumbers = new Set <String>();
        
        for (SObject s: records){
            Case c = (Case)s;
            firstNames.add(c.Web_First_Name__c);
            lastNames.add(c.Web_Last_Name__c);
            if(String.isNotBlank(c.SuppliedEmail) && String.isBlank(c.ContactId)){
                emails.add(c.SuppliedEmail);
            }
            if(String.isNotBlank(c.ContactId)){
                c.Is_Contact_Verified__c = true;
            }
            caseNumbers.add(c.Web_Existing_Case__c);
        }
        
        if(emails.size() > 0){
            List <Contact> lContacts = [select id, FirstName, LastName, email, Contact_Status__c from Contact
                                        where email in : emails];
            
            For (Contact t:lContacts ){
                for (SObject s: records){
                    Case c = (Case)s;
                    if (c.SuppliedEmail == t.email){
                        c.contactId = t.Id;
                        // assume contact verified flag is set now
                        c.Is_Contact_Verified__c = true;
                    }
                }
            }
        }
        
        if(!caseNumbers.isEmpty()){
            List <Case > lCases = [select id, caseNumber from Case where caseNumber in: caseNumbers ];
            for (Case p: lCases){
                for (SObject s: records){
                    Case c =  (Case)s;
                    if (p.CaseNumber == c.Web_Existing_Case__c){
                        c.ParentId = p.Id;
                        modifiedCases.add(c);
                    }
                }
            }
        }
         
        return modifiedCases;
    }
    
    
    
    //  if serial__c is changed (systematically or by user)
    // populate Assigned_Serial__c lookup
    
    // if Assigned_Serial__c is populated but asset__c is not, try to update asset__c
    
    // after asset__c is set, also try to set the entitlemnt (even though there is a seperated rule, since this is run in pre trigger context, the seperated rule won't be triggered
    
    
    /*******************************************************************************************************
* @description populate the serial__c, Asset based upon the web_serial__c
* @param trigger.new map
* @return none, the result should be set to the records itself
* @example
*/
    
    public static  List <Case> populateWebSerial( List <SObject> records ){
        
        
        // if   Web_Serial__c is provided by not Serial__c is not set, tried to lookup serial__c based upon assigned assigned serial
        // if found poulate serial__c
        List <Case> modifiedCases = new List <Case>();
        
        Map <String, Id> serialAccountMap = new Map<String, Id>();
        
        for (SObject s: records){
            Case c = (Case)s;
            if (String.isNotBlank(c.Web_Serial__c)) {
                // String.trim(c.Web_Serial__c);
                serialAccountMap.put(c.Web_Serial__c, c.AccountId);
            }
        }
        
        // in web , the account is not verified yet, so just use serial
        List <Serial__c> serials = [select Id, IsDeleted,  Name, Serial_Number__c, Status__c from Serial__c where  Serial_Number__c in :serialAccountMap.keySet()];
        
        
         for (SObject s: records){
            Case c = (Case)s;
            for (Serial__c se : serials){
                if (String.isNotBlank(c.Web_Serial__c) && c.Web_Serial__c  == se.Serial_Number__c) {
                    c.Serial__c = se.Id;
                    modifiedCases.add(c);
                }
            }
        }
        
        /*
List <Assigned_Serial__c> assignedSerials = [select Asset__c, Asset__r.AccountId, Id,  Name, Serial__c, Serial_Number__c, Status__c, Subscription__c
from Assigned_Serial__c where Asset__r.AccountId in :serialAccountMap.values() and Serial_Number__c in :serialAccountMap.keySet() ];
for (SObject s: records){
Case c = (Case)s;
for (Assigned_Serial__c assignedSerial : assignedSerials){
if (String.isNotBlank(c.Web_Serial__c) && c.Web_Serial__c  == assignedSerial.Serial_Number__c && c.AccountId == assignedSerial.Asset__r.AccountId) {
c.Serial__c = assignedSerial.Serial__c;
c.AssetId = assignedSerial.Asset__c;
modifiedCases.add(c);
}
}
}
*/
        
        // finally update the entitlment as well
        // DynamicBusinessRuleActionRuleEngine.runOneRule('Case_Premium_Support_Entitlement_Asset', modifiedCases);
        
        return modifiedCases;
        
        
    }
    
    
    
    /*******************************************************************************************************
* @description populate the Asset based upon the Serial__c change . assumption: everythig in records have serial__c look up field changed
*     https://bugs.cudaops.com/browse/SFDC-4565 - 3/25 remove restirction of asset and subscription being associated with the same account of the case
* @param trigger.new map
* @return none, the result should be set to the records itself
* @example
*/
    
    public static  List <Case> populateSerialAsset(List <SObject> records ){
        
        
        // if   Web_Serial__c is provided by not Serial__c is not set, tried to lookup serial__c based upon assigned assigned serial
        // if found poulate serial__c
        
        //  if serial__c is changed (systematically or by user)
        // populate Assigned_Serial__c lookup
        
        // if Assigned_Serial__c is populated but asset__c is not, try to update asset__c
        
        // after asset__c is set, also try to set the entitlemnt (even though there is a seperated rule, since this is run in pre trigger context, the seperated rule won't be triggered
        
        List <Case> modifiedCases = new List <Case>();
        List <Case> modifiedCasesWithSub = new List <Case>();
        
        Map <Id, Id> serialAccountMap = new Map<Id, Id>();
        
        for (SObject s: records){
            Case c = (Case)s;
            if (String.isNotBlank(c.Serial__c)) {
                serialAccountMap.put(c.Serial__c, c.AccountId);
            }
        }
        
         
        //SFDC-10513: Modified where clause to get Active Assigned Serial with a Subscription End date not in past
        List <Assigned_Serial__c> assignedSerials = [SELECT Parent_Subscription__c, 
                                                     Parent_Subscription__r.SBQQ__Product__c, 
                                                     Asset__r.Product2Id, 
                                                     Asset__c, 
                                                     Asset__r.AccountId, 
                                                     Id,  
                                                     Name, 
                                                     Serial__c, 
                                                     Serial_Number__c, 
                                                     Status__c, 
                                                     Subscription__c,
                                                     Subscription__r.SBQQ__RootId__c, 
                                                     Subscription__r.SBQQ__EndDate__c, 
                                                     Subscription__r.SBQQ__StartDate__c,  
                                                     Subscription__r.SBQQ__Product__r.Name, 
                                                     Subscription__r.SBQQ__Product__r.ProductCode,
                                                     Subscription__r.SBQQ__Product__r.prod_subtype__c,
                                                     Subscription__r.SBQQ__Product__r.End_of_Life__c
                                                     FROM Assigned_Serial__c 
                                                     WHERE /*Status__c = 'Active' 
AND Subscription__r.SBQQ__EndDate__c >= :Date.today()
AND */Serial__c in :serialAccountMap.keySet() ORDER BY Subscription__r.SBQQ__EndDate__c DESC ];
        // from Assigned_Serial__c where Status__c != 'Inactive' and Asset__r.AccountId in :serialAccountMap.values() and Serial__c in :serialAccountMap.keySet() ];    // SFDC-4565
         
        String subPrefix = '';
        // note: this is temporary solution to address scenario where parent_subscripton__c is not populated by integration yet.
        Set <Id> parentSubIds = new Set<Id>();
        for (Assigned_Serial__c assignedSerial: assignedSerials){
            if (assignedSerial.Subscription__c != null) {
                subPrefix = ((String)assignedSerial.Subscription__c).left(3);  // CPQ sub prefix is different in each env.
                if (assignedSerial.Subscription__r.SBQQ__RootId__c != null && assignedSerial.Subscription__r.SBQQ__RootId__c.StartsWith(subPrefix)) {
                    parentSubIds.add(assignedSerial.Subscription__r.SBQQ__RootId__c);
                }
            }
        }
         Map<ID, SBQQ__Subscription__c> parentSubMap = new Map<ID, SBQQ__Subscription__c>([SELECT Id, 
                                                                                          SBQQ__Product__c 
                                                                                          FROM SBQQ__Subscription__c 
                                                                                          WHERE id in :parentSubIds]);
        
        for (SObject s: records){
            Case c = (Case)s;
            
            // reset these values
            c.Is_Asset_Verified__c = false;
            c.AssetId = null;
            c.Subscription__c = null;
            c.EntitlementId = null;
            c.Is_Premium_Support__c = false;
            
            //SFDC-8994 Reset the Instant Replacement flag
            c.Instant_Replacement__c = false;
            
            String premiumSupport = '';
            String anySupport = '';
            
            for (Assigned_Serial__c assignedSerial : assignedSerials){
                // if (c.Serial__c != null &&  c.Serial__c  == assignedSerial.Serial__c && c.AccountId == assignedSerial.Asset__r.AccountId) { // SFDC-4565
                if (c.Serial__c != null &&  c.Serial__c  == assignedSerial.Serial__c ){
                    modifiedCases.add(c);
                    c.AssetId = assignedSerial.Asset__c;
                    
                    // JIRA - SFDC-16480 - Updated PremSup condition
                    // 2019-01-24: from case perspective only care about subscription asscoiated with support
                    // https://bugs.cudaops.com/browse/SFDC-4639 - give priority to premium support
                    if (assignedSerial.Subscription__r.SBQQ__Product__r.Name != null &&  
                        (assignedSerial.Subscription__r.SBQQ__Product__r.Name.contains('PremSup') &&
                         !assignedSerial.Subscription__r.SBQQ__Product__r.End_of_Life__c == true) && 
                        assignedSerial.Subscription__r.SBQQ__EndDate__c >= System.today() && 
                        premiumSupport == ''){
                            premiumSupport = assignedSerial.Subscription__c;
                        } else if ( assignedSerial.Subscription__r.SBQQ__Product__r.Name != null && assignedSerial.Subscription__r.SBQQ__Product__r.Name.contains('Support')){
                            anySupport = assignedSerial.Subscription__c;
                        }
                    
                    // SFDC-4934
                    if ( assignedSerial.Subscription__r.SBQQ__Product__r.Name != null && assignedSerial.Subscription__r.SBQQ__Product__r.prod_subtype__c == 'IR'){
                        c.Instant_Replacement__c = true;
                    }
                    
                    
                    // 2019-1-24: cannot use c.subscription__r.SBQQ__StartDate__c because it is not in context , use assignedSerial.subscription__r.SBQQ__StartDate__c
                    // will set asset verified , as long as at least one subscription is valid
                    // 2019-09-16 due to legacy data missing start date, ignore the conditon of start date check
                    // if (assignedSerial.Subscription__r.SBQQ__StartDate__c != null && assignedSerial.Subscription__r.SBQQ__StartDate__c <= Date.today() )
                    if ( assignedSerial.Subscription__r.SBQQ__EndDate__c == null || (assignedSerial.Subscription__r.SBQQ__EndDate__c != null &&  assignedSerial.Subscription__r.SBQQ__EndDate__c >= Date.today() )){
                        // assume asset verified condition is met now
                        c.Is_Asset_Verified__c = true;
                    }
                    
                    // https://bugs.cudaops.com/browse/DTIN-861, to set the base product id
                    if (c.productId == null){
                        if (assignedSerial.Asset__r.Product2Id != null){
                            c.productId = assignedSerial.Asset__r.Product2Id;
                        } else if (assignedSerial.Parent_Subscription__r.SBQQ__Product__c != null){
                            c.productId = assignedSerial.Parent_Subscription__r.SBQQ__Product__c;
                        } else if (assignedSerial.Subscription__r.SBQQ__RootId__c != null){
                            if (parentSubMap.get(assignedSerial.Subscription__r.SBQQ__RootId__c) != null){
                                c.productId = parentSubMap.get(assignedSerial.Subscription__r.SBQQ__RootId__c).SBQQ__Product__c;
                            }
                        }
                        
                    }
                }
            }
            
             
            if (String.isNotBlank(premiumSupport)){
                c.Subscription__c = premiumSupport;
                c.Is_Premium_Support__c = true; 
                c.Priority = 'P2'; 
                c.Is_Priority_updated__c = true;
                c.Case_Created__c = true; // Modified Premium Flag True Condition based on SFDC-14299
                modifiedCasesWithSub.add(c);
            } else if (String.isNotBlank(anySupport)){
                c.Subscription__c = anySupport;
                modifiedCasesWithSub.add(c);
            }
            
        }
        
        
        // it might be duplicated. but this section is assuming that asset is set somehow but not subscription is not set
        //        Set<Id> assetIds = new Set <Id>();
        //        for (SObject s: records){
        //            Case c = (Case)s;
        //            assetIds.add(c.AssetId);
        //        }
        
        
        
        /*    //  update the entitlment as well
System.debug('~~ Starting Case_Premium_Support_Entitlement_Subs: ' + modifiedCasesWithSub);
DynamicBusinessRuleActionRuleEngine.runOneRule('Case_Premium_Support_Entitlement_Subs', modifiedCasesWithSub);
System.debug('~~ finished Case_Premium_Support_Entitlement_Subs: ' + modifiedCasesWithSub);
// final check : if premium entitlement has premium support , set the is premium support as well
Set <Id> entitlementIds = new Set<Id>();
for (SObject s: modifiedCasesWithSub){
Case c = (Case)s;
if (c.EntitlementId != null ){
entitlementIds.add(c.EntitlementId);
}
}
// note this is supposed to cover by busiiness rule is Premium support , but in the context of trigger, the old value is being used
// so set the premium support if serial got changed
if (entitlementIds.size() > 0 ) {
Map<ID, Entitlement> m = new Map<ID, Entitlement>([SELECT Id, Name FROM Entitlement where Id in :entitlementIds]);
for (SObject s: modifiedCasesWithSub){
Case c = (Case)s;
if (c.EntitlementId != null ){
Entitlement e = m.get(c.EntitlementId);
if (e != null && e.Name.contains('Premium Support')){
//c.Is_Premium_Support__c = true;
}
}
}
} */
        
        
        
        // NOTE: Case_Asset_Verified rule need to be run before this. otherwise, the old data might retain.
        
       /* System.debug('~~~ : modified Cases with Sub: ' + JSON.serialize(modifiedCasesWithSub));
        System.debug('~~~ : modified Cases: ' + JSON.serialize(modifiedCases));*/
        
        return modifiedCases;
        
        
    }
    
    /*******************************************************************************************************
* @description process offline case type
* @param trigger.new List
* @return
* @example
*/
    
    public static void processLiveChatCases (List <Case> newCases )    {
        
        
        for(Case newCase:newCases) {
            // Offline Record Type
             
            // This should only happen through LiveChat
            if (newCase.RecordTypeId != null && newCase.RecordTypeId.Equals(OFFLINE_RECORD_TYPE_ID)) { // recordTypeId can be null
                String existingCase = newCase.Web_Existing_Case__c;
                String firstName = newCase.Web_First_Name__c;
                String lastName = newCase.Web_Last_Name__c;
                String serialNumber = newCase.Web_Serial__c;
                String chatType = newCase.Offline_Support_Type__c;
                String message = newCase.subject;
                String email = newCase.SuppliedEmail;
                // String language = newCase.Web_Language_of_correspondence__c;
                String language = 'English';
                String company = newCase.Offline_Support_Company__c;
                
                // Disabled Live Chat for Sales - SFDC-14510
                /* if (chatType != null && chatType.equals('Sales')) { 
//TODO: Should we stop the creation of the current Offline Case?
Group americasLdrLeadQueue = [SELECT Id FROM Group WHERE Name = 'Americas LDR Lead Live Chat'];
createLead(firstName, lastName, email, message, company);
//Try to stop the insertion, but this also reverts the createLead
//newCase.RecordTypeId.addError('Invalid ReceordType to Create');
}*/
                if (chatType != null &&  chatType.equals('Support')) {
                    // Update current case
                    Group contactCenterAllGroup = [SELECT Id FROM Group WHERE Name = 'Contact Center: All'];
                    newCase.RecordTypeId = WEB_MESSAGE_RECORD_TYPE_ID;
                    newCase.Origin = 'Live Chat';
                    newCase.OwnerId = contactCenterAllGroup.Id;
                } else {
                    System.debug('~~ ERROR: Unsupported Chat Type (' + chatType + ') ~~ ');
                }
                
                
            }
        }
        
    }      
    
    /*******************************************************************************************************
* @description populate the case milestones
* @param trigger.new map
* @return none, the result should be set to the records itself
* @example
*/
    public static  List<CaseMilestone>  completeMilestone( List <SObject> records, String jsonParameter,   DateTime complDate ){
        
        Set <Id> caseIds = new Set <Id>();
        for (SObject s: records){
            caseIds.add( (Id)s.get('Id'));
        }
        
        Map<String, Object> parameters =
            (Map<String, Object>)
            JSON.deserializeUntyped(jsonParameter);
         // String milestoneName =  (String) parameters.get('milestoneName');
         List <String> milestones = new List <String>();
        for (Object o: parameters.values() ){
            milestones.add((String)o);
        }
        
        List<CaseMilestone> cmsToUpdate = [select Id, completionDate from CaseMilestone cm
                                           where caseId in :caseIds and cm.MilestoneType.Name in :milestones
                                           and completionDate = null ];
        
        if (cmsToUpdate.isEmpty() == false){
            for (CaseMilestone cm : cmsToUpdate){
                cm.completionDate = complDate;
            }
            DML.save( cmsToUpdate);
        }
        
        return cmsToUpdate;
    }
    
    /*******************************************************************************************************
* @description populate the Callback notification field
* @param trigger.new map
* @return none, the result should be set to the records itself                              
* @example
*/
    
    public static void PopulateSendCallbackNotificationOnInsert(List<Case> newCases){        
        Set<Id> caseIdSet = new Set<Id>();
        for(Case caseRecord: newCases){
            if(caseRecord.Callback_Date_Time__c != null && caseRecord.Callback_TimeZone__c != null){
                caseIdSet.add(caseRecord.Id);
            }
        }            
        
        if(!caseIdSet.isEmpty()){
            AsyncCaseUpdate asyncUpdate = new AsyncCaseUpdate();
            asyncUpdate.caseIdSet = caseIdSet;
            System.enqueueJob(asyncUpdate);
        }            
    }    
    
    /*******************************************************************************************************
* @description populate the Callback notification field
* @param trigger.new map
* @return none, the result should be set to the records itself                              
* @example
*/
    
    public static void PopulateSendCallbackNotificationOnUpdate(List<Case> newCases, Map<Id, Case> oldMap){
        List<Case> listOfCase = new List<Case>();         
        for(Case caseRecord: newCases){
            if((caseRecord.Callback_Date__c != null && caseRecord.Callback_Date__c != oldMap.get(caseRecord.Id).Callback_Date__c) ||
               (caseRecord.Callback_Time__c != null && caseRecord.Callback_Time__c != oldMap.get(caseRecord.Id).Callback_Time__c) ||
               (caseRecord.Callback_TimeZone__c != null && caseRecord.Callback_TimeZone__c != oldMap.get(caseRecord.Id).Callback_TimeZone__c)){
                   listOfCase.add(caseRecord);
               }
        }            
        
        if(listOfCase.isEmpty())
            return;
        List<PicklistEntry> entries = Schema.SObjectType.User.fields.TimeZoneSidKey.picklistValues;
         Map<String, String> timeZoneMap = new Map<String, String>();
        for(PicklistEntry pe: entries){
            timeZoneMap.put(pe.getLabel().substring(0,11), pe.getValue());
        } 
        
        for(Case objCase : listOfCase){
            if(objCase.Callback_Date__c != null && objCase.Callback_Time__c != null && objCase.Callback_TimeZone__c != null){
                
                DateTime tempDateTime = DateTime.newInstance(objCase.Callback_Date__c, objCase.Callback_Time__c);
                objCase.Callback_Date_Time__c = tempDateTime;
                DateTime callBackTime = objCase.Callback_Date_Time__c.addMinutes(30);
                DateTime dt = DateTime.newInstanceGMT(callBackTime.year(), callBackTime.month(), callBackTime.day(), callBackTime.hour(), callBackTime.minute(), callBackTime.second());
                
                String timeZoneString = timeZoneMap.get(objCase.Callback_TimeZone__c.substring(0, 11));                                                      
                if(objCase.Callback_TimeZone__c == '(GMT-05:00) Eastern Time (US and Canada)'){
                    timeZoneString = 'America/New_York';
                } else if(objCase.Callback_TimeZone__c == '(GMT-06:00) Central Time (US and Canada'){
                    timeZoneString = 'America/Chicago';
                } else if(objCase.Callback_TimeZone__c == '(GMT-08:00) Pacific Time (US and Canada); Tijuana'){
                    timeZoneString = 'America/Los_Angeles';
                }  
                
                if(!String.isBlank(timeZoneString)){
                Timezone tz = Timezone.getTimeZone(timeZoneString);
                DateTime callBack = DateTime.newInstance(dt.getTime() - tz.getOffset(dt));
                objCase.Send_Email_Alert_Before_30__c = callBack; 
                objCase.Callback_Date__c = objCase.Callback_Date_Time__c.date();
                objCase.Callback_Time__c = objCase.Callback_Date_Time__c.time();
                objCase.Agent_Callback_Date_Time__c = callBack.addMinutes(-30);
                objCase.Callback_Date_Time__c = callBack.addMinutes(-30);
                }
            }
        }
    }
    
    /*******************************************************************************************************
* @description case which need assignment
* @param trigger.new map
* @return none, the result should be set to the records itself
* @example
*/
    @future
    public static void assignCase(List<id> recordIds)
    {
        
         
        if (recordIds != null && recordIds.size() > 0  ){
            
            
            Set <String> queueNames = new Set <String> ();
            Map <String, String > keyQueueMap = new Map <String, String>();
            For (Case_Queue_Assignment__mdt c:[ select Case_Record_Type_Name__c, Active__c, Id, Label, Queue_Name__c, Region__c, Reason__c from Case_Queue_Assignment__mdt where Active__c = true] ){
                queueNames.add(c.Queue_Name__c);
                String key = c.Case_Record_Type_Name__c +  (c.Region__c != null? c.Region__c: '') + (c.Reason__c != null?c.Reason__c:'') ; // can be more in the future ...
                keyQueueMap.put(key, c.Queue_Name__c);
            }
            
             
            Map <String, Id> queueNameIdMap = new Map<String, Id>();
            For (Group g: [select DeveloperName, Email, Id,  Name, OwnerId,  Type from Group where type = 'Queue' and DeveloperName in: queueNames]){
                queueNameIdMap.put(g.DeveloperName, g.Id);
            }
            
             
            // list of factors to be considered
            List<Case> cases = [SELECT casenumber, subject, id, Web_Region__c, Reason__c, recordTypeId, RecordType.Name FROM Case WHERE Id IN :recordIds];
             
            for (Case c: cases){
                String key;
                
                key = c.RecordType.Name +  c.Web_Region__c + c.Reason__c; // can be more in the future ...'
                 if (keyQueueMap.containsKey(key)){
                    String queueName = keyQueueMap.get(key);
                    if ( String.isNotBlank(queueName) &&  queueNameIdMap.containsKey(queueName)){
                        c.OwnerId = queueNameIdMap.get(queueName);
                    }
                    continue;
                }
                
                // try different combination of key
                key = c.RecordType.Name +  c.Web_Region__c; // can be more in the future ...'
                 if (keyQueueMap.containsKey(key)){
                    String queueName = keyQueueMap.get(key);
                    if ( String.isNotBlank(queueName) &&  queueNameIdMap.containsKey(queueName)){
                        c.OwnerId = queueNameIdMap.get(queueName);
                    }
                    continue;
                }
                
                // try different combination of key
                key = c.RecordType.Name +  c.Reason__c; // can be more in the future ...'
                 if (keyQueueMap.containsKey(key)){
                    String queueName = keyQueueMap.get(key);
                    if ( String.isNotBlank(queueName) &&  queueNameIdMap.containsKey(queueName)){
                        c.OwnerId = queueNameIdMap.get(queueName);
                    }
                    continue;
                }
                
            }
            
            DML.save(cases);
            
        }
        
        
        
    }
    
    public static String createLead(String firstName, String lastName, String email, String message, String company) {
        
        LogModel log = LogModel.startLog('CaseModel', 'createLead');
        try {
            
            List<Contact> existingContacts = [SELECT Id, LiveChatTranscript_External_Id__c FROM Contact WHERE Email =: email];
            List<Lead> existingLeads = [SELECT Id, LiveChatTranscript_External_Id__c FROM Lead WHERE Email =: email AND Status IN ('Marketing Qualified Lead', 'Sales Accepted Lead')];
            
            if (existingContacts != null && !existingContacts.isEmpty()) {
                
                List <Task> newTasks = new List <Task>();
                for(Contact existingContact:existingContacts) {
                     
                    Task newTask = new Task(
                        WhoId=existingContact.Id,
                        Subject=String.isNotBlank(message)? message:'Live Chat',
                        Hot_List_Source__c='Live Chat',
                        TaskSubtype='Task'
                    );
                    newTasks.add(newTask); // insert newTask;
                    existingContact.LeadSource = 'Live Chat';
                }
                
                if (newTasks.size() > 0 ) {
                    withoutSharingDML.save(newTasks);
                    withoutSharingDML.save(existingContacts);
                }
                
            } else if (existingLeads != null && !existingLeads.isEmpty()) {
                List <Task> newTasks = new List <Task>();
                
                for(Lead existingLead:existingLeads) {
                     Task newTask = new Task(
                        WhoId=existingLead.Id,
                        Subject=String.isNotBlank(message)? message:'Live Chat',
                        Hot_List_Source__c='Live Chat',
                        TaskSubtype='Task'
                    );
                    newTasks.add(newTask); // insert newTask;
                    existingLead.LeadSource = 'Live Chat';
                }
                
                if (newTasks.size() > 0 ) {
                    withoutSharingDML.save(newTasks);
                    withoutSharingDML.save(existingLeads); 
                }
            } else {
                 Lead newLead = new Lead();
                
                newLead.FirstName = firstName;
                newLead.LastName = String.isNotBlank(lastName)? lastName:'Unknown';
                newLead.Email = email;
                newLead.Description = String.isNotBlank(message)? message:'Live Chat';
                newLead.Company = String.isNotBlank(company)? company:'Unknown';
                newLead.LeadSource = 'Live Chat';
                newLead.Business_Group__c = 'Core';
                newLead.recordTypeId =  Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByDeveloperName().get('Post_MQL').getRecordTypeId();
                
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.assignmentRuleHeader.useDefaultRule = true;
                newLead.setOptions(dmo);
                insert newLead; 
                
            }
            
        } catch (Exception e) {
             String inputString = '';
            inputString += 'First Name: ' + firstName + ' \n';
            inputString += 'Last Name: ' + lastName + ' \n';
            inputString += 'Email: ' + email + ' \n';
            inputString += 'Message: ' + message + ' \n';
            inputString += 'Company: ' + company + ' \n';
            log.addErrorLog(inputString); 
            log.addExceptionLog(e);
            return e.getMessage();
        }
        
        return 'Success';
    }
    
    // SFDC-12495 
    // to update the support region when a new case is getting created
    public static void updateCaseSupportRegion(List<Case> caseList){
        System.debug('##caseList:: ' + JSON.serialize(caseList));
        Id americaQueueId;
        Id indiaQueueId;
        Id emeaQueueId;
        Id chinaQueueId;
        Id japanQueueId;
        Id baraccudaId;
        Id sonianId;
        Id managedWorkplaceId;
        
        List<RecordType> rtList = [Select Id, Name, DeveloperName from RecordType where DeveloperName = 'Web_Case'];
        Map<Id, Group> groupMap = new Map<Id, Group>([Select Id, Name, DeveloperName, Type from Group 
                                                      where Type = 'Queue' and DeveloperName in 
                                                      ('Contact_Center_Americas', 'Contact_Center_EMEA', 
                                                       'Contact_Center_India', 'Barracuda_MSP', 'WM_Sonian', 'WM_Managed_Workplace', 'Contact_Center_China', 'Contact_Center_Japan')]);
        for(Group groupRecord: groupMap.values()){
            if(groupRecord.DeveloperName == 'Contact_Center_Americas'){
                americaQueueId = groupRecord.Id;
            } else if(groupRecord.DeveloperName == 'Contact_Center_EMEA'){
                emeaQueueId = groupRecord.Id;
            } else if(groupRecord.DeveloperName == 'Contact_Center_India'){
                indiaQueueId = groupRecord.Id;
            } else if(groupRecord.DeveloperName == 'Contact_Center_China'){
                chinaQueueId = groupRecord.Id;
            } else if(groupRecord.DeveloperName == 'Contact_Center_Japan'){
                japanQueueId = groupRecord.Id;
            } else if(groupRecord.DeveloperName == 'Barracuda_MSP'){
                baraccudaId = groupRecord.Id;
            } else if(groupRecord.DeveloperName == 'WM_Sonian'){
                sonianId = groupRecord.Id;
            } else if(groupRecord.DeveloperName == 'WM_Managed_Workplace'){
                managedWorkplaceId = groupRecord.Id;
            }                
        }
        
        for(Case caseRecord: caseList){
            if(caseRecord.OwnerId == americaQueueId ||  
               caseRecord.OwnerId == baraccudaId || caseRecord.OwnerId == sonianId ||
               caseRecord.OwnerId == managedWorkplaceId){
                   caseRecord.Web_Region__c = 'Americas';
               } else if(caseRecord.OwnerId == emeaQueueId){
                   caseRecord.Web_Region__c = 'EMEA';
               } else if(caseRecord.OwnerId == indiaQueueId){
                   caseRecord.Web_Region__c = 'APAC';
               } else if(caseRecord.OwnerId == chinaQueueId){
                   caseRecord.Web_Region__c = 'China';
               } else if(caseRecord.OwnerId == japanQueueId){
                   caseRecord.Web_Region__c = 'Japan';
               }                                     
            
            // populate Case First Queue Id
            String ownerIdString = caseRecord.OwnerId;
            if(ownerIdString.substring(0,3) == '00G' && caseRecord.ParentId == null && 
               caseRecord.RecordTypeId == rtList[0].Id && caseRecord.Source__c != 'EmailMessageModel'){
                   caseRecord.First_Queue_Id__c = caseRecord.OwnerId;
               }
            
            // update priority and Alert Exists on insert of case record
            if(caseRecord.Customers_Provided_Business_Impact__c == 'Major Impact/Business Down'){
                caseRecord.Priority = 'P1';
                caseRecord.Alert_Exists__c = true;
            }
        }        
    }
    
    // SFDC-18669
    public static void beforeInsertHelper(List<Case> newList){        
        List<Case> entitlementCaseList = new List<Case>();
        for(Case caseRecord: newList){    
            caseRecord.Record_Type_Id__c = caseRecord.RecordTypeId; //SFDC-20288 
            if((caseRecord.OwnerId == INTERNAL_TICKET_COMMUNITIES_QUEUE_ID || internalTicketEntitlementQueuesSet.contains(caseRecord.Case_Owner_Queue_Name__c)) && String.isBlank(caseRecord.Completed_Milestone_Status__c) && Case.AccountId != null){
                entitlementCaseList.add(caseRecord);
            }                    
            
            if(caseRecord.From_Address_New__c!=null && caseRecord.From_Address_New__c.contains('xdr-support')){ 
                caseRecord.To_Address__c = 'xdr-support';   
            }                                           
        }
        if(!entitlementCaseList.isEmpty()) assignCaseEntitlements(entitlementCaseList);
    }   
    public static void updateComplianceStatus(List<Case> newList){ 
        
        // To run updateComplianceStatus method only once to reduce the no of queries consumed
        // This method with run only once during the 1st run of the Case Trigger
        if(!TriggerContextVariables.IS_1ST_RUN_updateComplianceStatus_COMPLETED){
            TriggerContextVariables.IS_1ST_RUN_updateComplianceStatus_COMPLETED = true;
        } else {
            return;
        }
        
        Set<ID> accountIds = new Set<Id>();
        Set<ID> contactIds = new Set<Id>();
        Set<ID> serialIds = new Set<Id>();
        for(Case caseRecord: newList){    
            if(caseRecord.AccountId != null)
                accountIds.add(caseRecord.AccountId);
            if(caseRecord.ContactId != null)
                contactIds.add(caseRecord.ContactId);  
            if(caseRecord.Serial__c != null)
                serialIds.add(caseRecord.Serial__c);  
                                         
        }
        Map<Id, String> complianceStatusMap = getComplianceStatus(accountIds,  contactIds, serialIds );
        for(Case caseRecord: newList){ 
            if(caseRecord.AccountId != null && complianceStatusMap.containsKey(caseRecord.AccountId) 
               && complianceStatusMap.get(caseRecord.AccountId) == 'Banned')
                caseRecord.Is_Account_Banned__c = True;
            if(caseRecord.ContactId != null && complianceStatusMap.containsKey(caseRecord.ContactId)
              && complianceStatusMap.get(caseRecord.ContactId) == 'Banned')
                caseRecord.Is_Account_Banned__c = True;
            if(caseRecord.Serial__c != null && complianceStatusMap.containsKey(caseRecord.Serial__c)
              && complianceStatusMap.get(caseRecord.Serial__c) == 'Banned')
                caseRecord.Is_Account_Banned__c = True;
        }
    }
  
    public static Map<Id, String> getComplianceStatus(Set<ID> accountIds, Set<ID> contactIds, Set<ID> serialIds ){
		Map<Id, String> complianceStatusMap = new Map<Id, String>();
        for(Account acc: [Select Id, Compliance_Status__c from Account where Id in :accountIds]) {
            if(acc.Compliance_Status__c!=null)
                complianceStatusMap.put(acc.Id, acc.Compliance_Status__c);
        }
		
        for(Contact con: [Select Id,AccountId, Account.Compliance_Status__c from Contact where Id in :contactIds]) {
            if(con.AccountId!=null && con.Account.Compliance_Status__c!=null)
                complianceStatusMap.put(con.Id, con.Account.Compliance_Status__c);
        }
		
		for(Serial__c ser: [Select Id,Account__c, Account__r.Compliance_Status__c from Serial__c where Id in :serialIds]) {
            if(ser.Account__c!=null && ser.Account__r.Compliance_Status__c!=null)
                complianceStatusMap.put(ser.Id, ser.Account__r.Compliance_Status__c);
        }
		return complianceStatusMap;
	 }
    public static void beforeUpdateHelper(List<Case> newList, Map<Id, Case> oldMap){        
        List<Case> entitlementCaseList = new List<Case>();
        List<Case> caseMilestoneCompletionList = new List<Case>();
        for(Case caseRecord: newList){
            caseRecord.Record_Type_Id__c = caseRecord.RecordTypeId; //SFDC-20288
            Case oldCase = oldMap.get(caseRecord.Id);
            
            if(oldCase.Status == 'Resolved' && (caseRecord.Status == 'In Progress'  || caseRecord.Status == 'Waiting for Customer Response'
               || caseRecord.Status == 'Vendor Hold' || caseRecord.Status == 'Pre Planning' || caseRecord.Status == 'Review & Project Planning'
               || caseRecord.Status == 'Planning Completed' || caseRecord.Status == 'Service Execution')) {
                caseRecord.Old_Resolved_Hours__c = oldCase.Hours_to_Resolved__c;
                caseRecord.Resolved_To_InProgress_Time__c = System.now();
                
            }
            // check if the Case status is changed from woc to Closed
            if(caseRecord.Status == 'Closed' && oldCase.Status == 'Waiting for Customer Response'){
                caseRecord.Closed_By__c = UserInfo.getUserId();
            }    
            
            if(oldCase.OwnerId != caseRecord.OwnerId 
               && (caseRecord.OwnerId == INTERNAL_TICKET_COMMUNITIES_QUEUE_ID || internalTicketEntitlementQueuesSet.contains(caseRecord.Case_Owner_Queue_Name__c))){
                entitlementCaseList.add(caseRecord);
            }   
                                    
            if(oldCase.OwnerId != caseRecord.OwnerId 
               && oldCase.OwnerId == INTERNAL_TICKET_COMMUNITIES_QUEUE_ID && String.isBlank(caseRecord.Completed_Milestone_Status__c)){
                   List<CaseMilestone> cmList = [SELECT Id, CaseId, CompletionDate, IsCompleted, IsViolated, 
                                                 MilestoneTypeId, StartDate, TargetDate 
                                                 FROM CaseMilestone where CaseId =: caseRecord.Id and IsCompleted = false];
                   for(CaseMilestone cm: cmList){
                       cm.CompletionDate = System.now();
                   }
                   update cmList;
                   caseRecord.Completed_Milestone_Status__c = 'Compliant';
            }  
            if(oldCase.OwnerId != caseRecord.OwnerId 
               && oldCase.OwnerId == INTERNAL_TICKET_COMMUNITIES_QUEUE_ID && caseRecord.Completed_Milestone_Status__c == 'Violation'){
                   List<CaseMilestone> cmList = [SELECT Id, CaseId, CompletionDate, IsCompleted, IsViolated, 
                                                 MilestoneTypeId, StartDate, TargetDate 
                                                 FROM CaseMilestone where CaseId =: caseRecord.Id and IsCompleted = false];
                   for(CaseMilestone cm: cmList){
                       cm.CompletionDate = System.now();
                   }
                   update cmList;                   
            }           
            
            if(caseRecord.From_Address_New__c!=null && caseRecord.From_Address_New__c.contains('xdr-support')){ 
                caseRecord.To_Address__c = 'xdr-support';   
            }   
                
            if(oldCase.OwnerId != caseRecord.OwnerId && caseRecord.RecordtypeId == TECH_SUPPORT_RECORD_TYPE_ID && caseRecord.Case_Owner_Queue_Name__c == 'XDR Escalations'){    
                caseRecord.Engineering_Escalated_By__c = Userinfo.getUserId();  
                caseRecord.Engineering_Escalation__c = true;    
                caseRecord.Escalated_Date_Time__c = system.now();   
            }
            
            String oldQueueName = oldCase.Case_Owner_Queue_Name__c;
            if(((((oldQueueName == 'Contact Center: Americas' || oldQueueName == 'Contact Center: EMEA' || oldQueueName == 'Contact Center: India') && 
                 oldCase.RecordtypeId == WEB_MESSAGE_RECORD_TYPE_ID && oldCase.Status == 'New')  ||                                       
                (oldQueueName == 'TAC Global Premium Support' && oldCase.RecordtypeId == TECH_SUPPORT_RECORD_TYPE_ID)  || oldCase.OwnerId == INTERNAL_TICKET_COMMUNITIES_QUEUE_ID || 
                 internalTicketEntitlementQueuesSet.contains(oldQueueName)) && 
                 oldCase.OwnerId != caseRecord.OwnerId) || 
                (internalTicketEntitlementQueuesSet.contains(oldQueueName) && (oldCase.Status == 'New' || oldCase.Status == 'In Progress') &&
                 oldCase.Status != caseRecord.Status && milestoneCompleteStatusSet.contains(caseRecord.Status))){
                 caseMilestoneCompletionList.add(caseRecord);                   
            }  
            
            
            if(caseRecord.Case_Owner_Queue_Name__c == 'TAC Global Premium Support' && oldCase.RecordtypeId == TECH_SUPPORT_RECORD_TYPE_ID && 
               caseRecord.Global_Premium_TS_Milestone_Delta_Timer__c != oldCase.Global_Premium_TS_Milestone_Delta_Timer__c && caseRecord.Global_Premium_TS_Milestone_Delta_Timer__c){
                   caseMilestoneCompletionList.add(caseRecord);  
               }
                    
        }
        
        if(!caseMilestoneCompletionList.isEmpty()) completeCaseMilestones(caseMilestoneCompletionList);    
        if(!caseMilestoneCompletionList.isEmpty() && !isUpdateCompletedMilestoneStatusInvoked) updateCompletedMilestoneStatus(caseMilestoneCompletionList);        
        if(!entitlementCaseList.isEmpty()) assignCaseEntitlements(entitlementCaseList);
        
        for(Case caseRecord: newList){
            String oldQueueName = oldMap.get(caseRecord.Id).Case_Owner_Queue_Name__c;
            if(oldQueueName == 'TAC Global Premium Support' && caseRecord.RecordtypeId == TECH_SUPPORT_RECORD_TYPE_ID && oldMap.get(caseRecord.Id).OwnerId != caseRecord.OwnerId){
                caseRecord.Global_Premium_TS_Milestone_Delta_Timer__c = false;
            }
        }
    }
    
    
    public static void assignCaseEntitlements(List<Case> entitlementCaseList){             
        Map<String, Id> entitlementMap = new Map<String, Id>();
        List<Entitlement> entitlementList = [Select Name, AccountId, SlaProcessId from Entitlement 
                                             where Name in ('Community Help Entitlement', 'Internal Ticket Entitlement')];
        for(Entitlement ent: entitlementList){
            If(ent.Name == 'Community Help Entitlement'){
                entitlementMap.put('Community Help Entitlement', ent.Id);
            } else if(ent.Name == 'Internal Ticket Entitlement'){
                entitlementMap.put('Internal Ticket Entitlement', ent.Id);
            }
        }
        
        if(!entitlementList.isEmpty()){
            for(Case caseRecord: entitlementCaseList){
                if(caseRecord.EntitlementId == null){
                    if(caseRecord.OwnerId == INTERNAL_TICKET_COMMUNITIES_QUEUE_ID){
                        caseRecord.EntitlementId = entitlementMap.get('Community Help Entitlement');
                    } else if(internalTicketEntitlementQueuesSet.contains(caseRecord.Case_Owner_Queue_Name__c)){
                        caseRecord.EntitlementId = entitlementMap.get('Internal Ticket Entitlement');
                    }
                }        
            }               
        }                                             
    }    
    
    public static void updateCompletedMilestoneStatus(List<Case> caseList){
        Set<Id> caseIdSet = new Set<Id>();
        for(Case caseRecord: caseList){
            caseIdSet.add(caseRecord.Id);
        }
        CaseFutureClass.updateCompletedMilestoneStatus(JSON.serialize(caseIdSet));
        isUpdateCompletedMilestoneStatusInvoked = true;
    }   
    
    public static void completeCaseMilestones(List<Case> caseList){
        List<CaseMilestone> cmList = [SELECT Id, CaseId, CompletionDate, IsCompleted, IsViolated, 
                                      MilestoneTypeId, StartDate, TargetDate 
                                      FROM CaseMilestone where CaseId =: caseList and IsCompleted = false];
        for(CaseMilestone cm: cmList){
            cm.CompletionDate = System.now();
        }
        update cmList;   
        System.debug('###cmList:: ' + JSON.serialize(cmList));
    }       
    
    // Start SFDC-18898
    public static void feedOwnerChangesTracking(Map<Id,Case> oldMap,Map<Id,case> MapNew){
         
    try{  
        Set<Id> ownerUserIdChangeSet=new Set<Id>();
        Set<Id> ownerGroupIdChangeSet=new Set<Id>();
        
        for(Id key:MapNew.keySet()){
            
            if(MapNew.get(key).ownerId!=oldMap.get(key).ownerId && TECH_SUPPORT_RECORD_TYPE_ID==MapNew.get(key).recordtypeId){
                if(((String)(MapNew.get(key).ownerId)).startsWith('005')){
                  ownerUserIdChangeSet.add(MapNew.get(key).ownerId);    
                }else{
                    ownerGroupIdChangeSet.add(MapNew.get(key).ownerId);    
                }
                if(((String)(oldMap.get(key).ownerId)).startsWith('005')){
                  ownerUserIdChangeSet.add(oldMap.get(key).ownerId);    
                }else{
                    ownerGroupIdChangeSet.add(oldMap.get(key).ownerId);    
                }
                
                
            }
        }
        if(UserMap==null && !ownerUserIdChangeSet.isEmpty()){
          UserMap=new Map<Id,User>([SELECT ID,Name
                                                From User 
                                               WHERE Id IN:ownerUserIdChangeSet]);
            
        }
        if(GroupMap==null && !ownerGroupIdChangeSet.isEmpty()){
         GroupMap=new Map<Id,Group>([SELECT ID,Name
                                                From Group 
                                                WHERE Id IN:ownerGroupIdChangeSet]);
        
        }
        
        if(!ownerUserIdChangeSet.isEmpty() || !ownerGroupIdChangeSet.isEmpty()){
           List<FeedItem> fdlist=new List<FeedItem>();
           for(Id key:MapNew.keySet()){
            if(MapNew.get(key).ownerId!=oldMap.get(key).ownerId && TECH_SUPPORT_RECORD_TYPE_ID==MapNew.get(key).recordtypeId){
               String commentBody='Case Owner Updated ';
                   
                        if(UserMap.size()>0 && UserMap.containsKey(OldMap.get(key).OwnerId)){
                           commentBody=commentBody+UserMap.get(OldMap.get(key).OwnerId).Name;    
                                }else{
                               commentBody=commentBody+(GroupMap.size()>0?GroupMap.get(OldMap.get(key).OwnerId).Name:'');             
                                }
                				commentBody=commentBody+' to ';
                       if(UserMap.size()>0 && UserMap.containsKey(MapNew.get(key).OwnerId)){
                           commentBody=commentBody+UserMap.get(MapNew.get(key).OwnerId).Name;  
                                }else{
                               commentBody=commentBody+(GroupMap.size()>0?GroupMap.get(MapNew.get(key).OwnerId).Name:'');             
                                }
                
                
                feedItem fditm=new feedItem();
                fdItm.Body=commentBody;
                fdItm.Title='Case updated';
                //fdItm.Type='ActivityEvent';
                fdItm.Visibility='InternalUsers';
                fdItm.ParentId=key;
                fdlist.add(fdItm);
            }
        }
        if(!fdlist.isEmpty()){
            insert fdlist;
        }
        }
       
    }catch(Exception ex){
        System.debug('Error Msg:: '+ex.getMessage()+ ' Line No.: '+ex.getLineNumber());
    }
    }
    // End SFDC-18898
 
}