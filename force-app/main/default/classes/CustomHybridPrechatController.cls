/**
* @author Jose V.
* @date 2019
*
* @group Controller
*
* @description controller for CustomHybridPreChatUI lightning component
*       2019-02-12: bug fix https://bugs.cudaops.com/browse/SFDC-3601
*       2019-04-18: change to without sharing since the script is invoked by live Agent Site Guest User
*
* Commented this class since all logic has been moved to processes and flows
*/

public without sharing class CustomHybridPrechatController {

    // static final String WEB_MESSAGE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Message').getRecordTypeId();  // '0123C0000006R7kQAE';
    // static final String WEBCHAT_LEADSOURCE = 'Live Chat';


    // @AuraEnabled
    // public static void createCase(String firstName, String lastName, String email, String message, String existingCase, String serialNumber, String liveChatTranscriptExternalId) {

    //     LogModel log = LogModel.startLog('CustomHybridPrechatController', 'createCase');
    //     try {

    //         Case newCase = new Case();

    //         newCase.Web_First_Name__c = firstName;
    //         newCase.Web_Last_Name__c = lastName;
    //         newCase.SuppliedEmail = email;
    //         newCase.Description = message;
    //         newCase.Subject = message;
    //         newCase.Web_Existing_Case__c = existingCase;
    //         newCase.Web_Serial__c = serialNumber;
    //         //newCase.Web_Language_of_correspondence__c = language;
    //         newCase.RecordTypeId = WEB_MESSAGE_RECORD_TYPE_ID;
    //         newCase.Do_Not_Auto_Assign__c = true;
    //         newCase.Origin = 'Live Chat';
    //         newCase.LiveChatTranscript_External_Id__c = liveChatTranscriptExternalId;

    //         withoutSharingDML.save(newCase);
    //         // insert newCase;

    //     } catch (Exception e) {
    //        log.addExceptionLog(e);
    //    }


    // }
    
    // public static String createLeadWithOwner(String firstName, String lastName, String email, String message, String company, String liveChatTranscriptExternalId, Id ownerId) {

    //     LogModel log = LogModel.startLog('CustomHybridPrechatController', 'createLeadWithOwner');
    //     try {

    //         List<Contact> existingContacts = [SELECT Id, LiveChatTranscript_External_Id__c FROM Contact WHERE Email =: email];
    //         List<Lead> existingLeads = [SELECT Id, LiveChatTranscript_External_Id__c FROM Lead WHERE Email =: email AND Status IN ('Marketing Qualified Lead', 'Sales Accepted Lead')];

    //         System.debug('~~ CreateLead ~~');
    //         System.debug('~~ existing leads: ~~' + existingLeads);
    //         System.debug('~~ existing contacts: ~~' + existingContacts);
    //         // System.debug(existingLeads);


    //         if (existingContacts != null && !existingContacts.isEmpty()) {

    //             List <Task> newTasks = new List <Task>();
    //             for(Contact existingContact:existingContacts) {
    //                 System.debug('~~ Inserting new hotlist activity on contact ~~');
    //                 System.debug('~~ contact id ' + existingContact.Id + ' ~~');
    //                 Task newTask = new Task(
    //                     WhoId=existingContact.Id,
    //                     Subject='Live Chat',
    //                     Hot_List_Source__c='Live Chat',
    //                     TaskSubtype='Task',
    //                     LiveChatTranscript_External_Id__c =   liveChatTranscriptExternalId
    //                 );
    //                 newTasks.add(newTask); // insert newTask;
    //                 existingContact.LiveChatTranscript_External_Id__c = liveChatTranscriptExternalId; // so regardless of new or existing contact, the current live chat session will still be assoicated with the contact
    //                 existingContact.LeadSource = WEBCHAT_LEADSOURCE; // https://bugs.cudaops.com/browse/SFDC-6340
    //             }

    //             if (newTasks.size() > 0 ) {


    //                     withoutSharingDML.save(newTasks);
    //                     withoutSharingDML.save(existingContacts);


    //             }

    //         } else if (existingLeads != null && !existingLeads.isEmpty()) {
    //             List <Task> newTasks = new List <Task>();

    //             for(Lead existingLead:existingLeads) {
    //                 System.debug('~~ Inserting new hot list task on lead ' + existingLead.Id + '~~');
    //                 Task newTask = new Task(
    //                     WhoId=existingLead.Id,
    //                     Subject=message,
    //                     Hot_List_Source__c='Live Chat',
    //                     TaskSubtype='Task',
    //                     LiveChatTranscript_External_Id__c =   liveChatTranscriptExternalId
    //                 );
    //                 newTasks.add(newTask); // insert newTask;
    //                 existingLead.LiveChatTranscript_External_Id__c = liveChatTranscriptExternalId; // so regardless of new or existing contact, the current live chat session will still be assoicated with the lead
    //                 existingLead.LeadSource = WEBCHAT_LEADSOURCE; // https://bugs.cudaops.com/browse/SFDC-6340
    //             }

    //             if (newTasks.size() > 0 ) {
    //                     withoutSharingDML.save(newTasks);
    //                     withoutSharingDML.save(existingLeads); 
    //             }
    //         } else {
    //             System.debug('~~ Creating new lead ~~');
    //             Lead newLead = new Lead();

    //             newLead.FirstName = firstName;
    //             newLead.LastName = firstName;
    //             newLead.Email = email;
    //             newLead.Description = 'Live Chat';
    //             newLead.Company = firstName;
    //             newLead.LeadSource = WEBCHAT_LEADSOURCE; // https://bugs.cudaops.com/browse/SFDC-6340
    //             //newLead.status = 'MQL'; do not set directly here - will use default value
    //             newLead.Business_Group__c = 'Core';
    //             newLead.LiveChatTranscript_External_Id__c = liveChatTranscriptExternalId;
    //             newLead.recordTypeId =  Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByDeveloperName().get('Post_MQL').getRecordTypeId();
    //             if (ownerId != null) {
    //                 newLead.OwnerId = ownerId;
    //             }


    //             Database.DMLOptions dmo = new Database.DMLOptions();
    //             dmo.assignmentRuleHeader.useDefaultRule = true;
    //             newLead.setOptions(dmo);
    //             insert newLead; 
    //             // withoutSharingDML.save(newLead);

    //         }

    //     } catch (Exception e) {
    //         System.debug('~~~~~~ error: ' + e);
    //         String inputString = '';
    //         inputString += 'First Name: ' + firstName + ' \n';
    //         inputString += 'Last Name: ' + lastName + ' \n';
    //         inputString += 'Email: ' + email + ' \n';
    //         inputString += 'Message: ' + message + ' \n';
    //         inputString += 'Company: ' + company + ' \n';
    //         log.addErrorLog(inputString); 
    //         log.addExceptionLog(e);
    //         return e.getMessage();
    //     }

	// 	return 'Success';
    // }
    
    // @AuraEnabled
    // public static String createLead(String firstName, String lastName, String email, String message, String company, String liveChatTranscriptExternalId) {
	// 	return CustomHybridPrechatController.createLeadWithOwner(firstName, lastName, email, message, company, liveChatTranscriptExternalId, null);        
    // }
}