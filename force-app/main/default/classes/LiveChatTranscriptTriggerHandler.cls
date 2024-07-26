/**
* Trigger handler for LiveChatTranscript Object
*
* @Author Jose
* @Date 2018/12/01
* @group Trigger
* @description  even though the trigger method is empty, the fact that this class extend the trigger handler means that additional logic e.g. busienssAction can be executed off this object
*     2019-01-12 : IY bug fix
*/
public with sharing class LiveChatTranscriptTriggerHandler extends TriggerHandler {

//     public override void beforeInsert() {


//         LogModel log = LogModel.startLog('LiveChatTranscriptTriggerHandler', 'beforeInsert');
//         try {

//             System.debug('~~ LinkToCaseOrLead beforeInsert~~');

//             String WEB_MESSAGE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Web_Case').getRecordTypeId();


//             list<LiveChatTranscript> liveChatTranscripts = Trigger.New;

//             for (LiveChatTranscript liveChatTranscript : liveChatTranscripts) {
//                 String externalId = liveChatTranscript.External_Id__c;
//                 // Id contactId = liveChatTranscript.ContactId; // assume not set
//                 // Id liveChatTranscriptId = liveChatTranscript.Id;  // not available before insret

//                 if (externalId != null && externalId != '') {

//                     // live chat deployment try to match contact with first name, last name and email
//                     /*
//                     embedded_svc.settings.extraPrechatInfo = [{
//                             "entityFieldMaps" : [{
//                             "doCreate" : false,
//                             "fieldName" : "LastName",
//                             "isExactMatch" : true,
//                             "label" : "Last Name"
//                             }, {
//                             "doCreate" : false,
//                             "doFind" : true,
//                             "fieldName" : "First Name",
//                             "isExactMatch" : true,
//                             "label": "First Name"
//                             }, {
//                             "doCreate" : false,
//                             "doFind" : true,
//                             "isExactMatch" : true,
//                             "fieldName" : "Email",
//                             "label": "Email"
//                             }],
//                     "entityName" : "Contact"
//                      }];

//                      */
//                     // but if for whatever reason, it does not have contact, has a fall back to set the contact as well.
//                     if (liveChatTranscript.ContactId == null) {
//                         List<Contact> existingContacts = [SELECT Id FROM Contact WHERE LiveChatTranscript_External_Id__c = :externalId order by createdDate limit 1];
//                         if (existingContacts != null) {
//                             System.debug(existingContacts);
//                             for (Contact existingCase : existingContacts) {
//                                     liveChatTranscript.contactId = existingCase.Id;
//                             }
//                         }
//                     }

//                     List<Case> existingCases = [SELECT Id FROM Case WHERE LiveChatTranscript_External_Id__c = :externalId and recordTypeId = :WEB_MESSAGE_RECORD_TYPE_ID LIMIT 1];
//                     if (existingCases != null) {
//                         System.debug(existingCases);
//                         for (Case existingCase : existingCases) {
//                             liveChatTranscript.CaseId = existingCase.Id;
//                         }
//                     }

//                     List<Lead> existingLeads = [SELECT Id FROM Lead WHERE LiveChatTranscript_External_Id__c = :externalId LIMIT 1];
//                     if (existingLeads != null) {
//                         System.debug(existingLeads);
//                         for (Lead existingLead : existingLeads) {
//                             liveChatTranscript.LeadId = existingLead.Id;

//                             // Ties the LiveChatTranscript to the Task/Activity created by this interaction
//                             // 2019-02-12: there can be multiple tasks associated with the same lead. so not reliable. In addition, it is the hot list htat need to be associated with live chat

// //                            Id taskWhoId = contactId != null ? contactId : existingLead.Id;
// //                            List<Task> latestExistingTasks = [SELECT Id, Live_Chat_Transcript__c FROM Task WHERE Hot_List_Type__c='Inbound LiveChat' and WhoId =: taskWhoId ORDER BY CreatedDate DESC LIMIT 1];
// //                            if (latestExistingTasks != null && !latestExistingTasks.isEmpty()) {
// //                                for (Task latestExistingTask:latestExistingTasks) {
// //                                    latestExistingTask.Live_Chat_Transcript__c = liveChatTranscriptId;
// //                                    update latestExistingTask;
// //                                }
// //                            }


//                         }
//                     }

//                     List<Hot_list__c> existingHotLists = [SELECT Id FROM Hot_list__c WHERE LiveChatTranscript_External_Id__c = :externalId LIMIT 1];
//                     if (existingHotLists != null) {
//                         System.debug(existingCases);
//                         for (Hot_List__c existingHotList : existingHotLists) {
//                             liveChatTranscript.Hot_List__c = existingHotList.Id;
//                         }
//                     }


//                 }
//             }
//         } catch (Exception e) {
//             log.addExceptionLog(e);
//         }


//     }

    /**
     *  linkCaseOrLead
     *
     * @param dayToKeep
     */
    /*
    @Future   @TestVisible
    private static void  linkCaseOrLead(LIst <Id> ids) {

        // 2019-04-11 - move to future to improve performance of livechattranscript creation ?? 

        System.debug('~~ LinkToCaseOrLead ~~');
        LogModel log = LogModel.startLog('LiveChatTranscriptTriggerHandler', 'beforeInsert');
        try {

            list<LiveChatTranscript> liveChatTranscripts =
            [select id, External_Id__c, ContactId, CaseId, LeadId, Hot_List__c  from LiveChatTranscript where id in :ids ];
            System.debug('~~ LinkToCaseOrLead ~~' + liveChatTranscripts);
            String WEB_MESSAGE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Web_Case').getRecordTypeId();


            List<Task> modifiedTasks = new List <Task>();

            for (LiveChatTranscript liveChatTranscript : liveChatTranscripts) {
                String externalId = liveChatTranscript.External_Id__c;
                Id contactId = liveChatTranscript.ContactId;
                Id liveChatTranscriptId = liveChatTranscript.Id;  // not available before insret

                if (externalId != null && externalId != '') {

                    List<Case> existingCases = [SELECT Id FROM Case WHERE LiveChatTranscript_External_Id__c = :externalId and recordTypeId = :WEB_MESSAGE_RECORD_TYPE_ID LIMIT 1];
                    if (existingCases != null) {
                        System.debug(existingCases);
                        for (Case existingCase : existingCases) {
                            liveChatTranscript.CaseId = existingCase.Id;
                        }
                    }

                    List<Lead> existingLeads = [SELECT Id FROM Lead WHERE LiveChatTranscript_External_Id__c = :externalId LIMIT 1];
                    if (existingLeads != null) {
                        System.debug(existingLeads);
                        for (Lead existingLead : existingLeads) {
                            liveChatTranscript.LeadId = existingLead.Id;
                        }
                    }

                    List<Hot_list__c> existingHotLists = [SELECT Id FROM Hot_list__c WHERE LiveChatTranscript_External_Id__c = :externalId LIMIT 1];
                    if (existingHotLists != null) {
                        System.debug(existingCases);
                        for (Hot_List__c existingHotList : existingHotLists) {
                            liveChatTranscript.Hot_List__c = existingHotList.Id;
                        }
                    }


                    List<Task> latestExistingTasks = [SELECT Id, Live_Chat_Transcript__c FROM Task WHERE Hot_List_Type__c = 'Inbound LiveChat' and LiveChatTranscript_External_Id__c = :externalId];
                    if (latestExistingTasks != null && !latestExistingTasks.isEmpty()) {
                        for (Task latestExistingTask : latestExistingTasks) {
                            latestExistingTask.Live_Chat_Transcript__c = liveChatTranscriptId;
                            modifiedTasks.add(latestExistingTask);
                        }
                    }


                }
            }
            System.debug('~~ LinkToCaseOrLead ~~ modified livechat' + liveChatTranscripts);
            withoutSharingDML.save(liveChatTranscripts);
            if (modifiedTasks.size() > 0 ){
                System.debug('~~ LinkToCaseOrLead ~~ modified task' + liveChatTranscripts);
                withoutSharingDML.save(modifiedTasks);  // update latestExistingTask;
            }

        } catch (Exception e) {
            log.addExceptionLog(e);
        }

    }
    */

    // public override void afterInsert() {

    //     /*
    //     System.debug('~~ LiveChatTranscript : After Insert  ~~');
    //     List <Id > transcriptIds = new List <Id>();
    //     for (LiveChatTranscript l:   (List <LiveChatTranscript> ) Trigger.New){
    //         transcriptIds.add(l.Id);
    //     }
    //     System.debug('~~ LiveChatTranscript : After Insert  ~~' +transcriptIds );
    //     linkCaseOrLead(transcriptIds);
    //     */


    //     LogModel log = LogModel.startLog('LiveChatTranscriptTriggerHandler', 'afterInsert');
    //     try {

    //         System.debug('~~ LinkToCaseOrLead afterInsert ~~');
    //         list<LiveChatTranscript> liveChatTranscripts = Trigger.New;

    //         for (LiveChatTranscript liveChatTranscript : liveChatTranscripts) {
    //             String externalId = liveChatTranscript.External_Id__c;
    //             // Id contactId = liveChatTranscript.ContactId;
    //             Id liveChatTranscriptId = liveChatTranscript.Id;  // available only after insert

    //             if (externalId != null && externalId != '') {

    //                 List<Task> latestExistingTasks = [SELECT Id, Live_Chat_Transcript__c FROM Task WHERE Hot_List_Source__c = 'Live Chat' and LiveChatTranscript_External_Id__c = :externalId];
    //                 if (latestExistingTasks != null && !latestExistingTasks.isEmpty()) {
    //                     for (Task latestExistingTask : latestExistingTasks) {
    //                         latestExistingTask.Live_Chat_Transcript__c = liveChatTranscriptId;
    //                     }
    //                     withoutSharingDML.save(latestExistingTasks);  // update latestExistingTask;
    //                 }


    //             }
    //         }
    //     }   catch (Exception e) {
    //         log.addExceptionLog(e);
    //     }

    // }
    
    // public override void afterUpdate() {
    public override void beforeUpdate() {

        LogModel log = LogModel.startLog('LiveChatTranscriptTriggerHandler', 'afterupdate');
        try {



            list<LiveChatTranscript> liveChatTranscripts = Trigger.New;
            System.debug('~~ LiveChatTranscriptTriggerHandler Update ~~' + liveChatTranscripts );
            Set <Id> caseIds = new Set<Id>();
            Set <Id> leadIds = new Set<Id>();
            Set <Id> hotListIds = new Set<Id>();
            Map<Id, Id> chatOwnerMap = new Map<Id, Id>();

            for (LiveChatTranscript liveChatTranscript : liveChatTranscripts) {

                // 2019-04-11 only update lead when the transcript is completed
                // Note: when a chat end, the status remains as in progress, it is up to the user to change the dispostion
                if (liveChatTranscript.status == 'Completed'){
                    String leadId = liveChatTranscript.LeadId;
                    if (leadId != null) {
                        leadIds.add(leadId);
                    }
                }

                String newOwnerId = liveChatTranscript.OwnerId;
                String oldOwnerId = (String) Trigger.oldMap.get(liveChatTranscript.Id).get('OwnerId');

                System.debug('~~ LiveChatTranscriptTriggerHandler old owner:  ~~' + oldOwnerId );
                System.debug('~~ LiveChatTranscriptTriggerHandler old transcript :  ~~' + (liveChatTranscript) Trigger.oldMap.get(liveChatTranscript.Id) );

                // if the transcript owner is changed (e.g. via omni channel) to a single user, change the owner of related records case, lead as well
                // if (newOwnerId !=  oldOwnerId && newOwnerId.startsWith('005') ) {  // 2019-04-15 from queue to single user does not trigger for some reason
                if (liveChatTranscript.Is_Child_Owner_Updated__c == false ){
                    chatOwnerMap.put(liveChatTranscript.Id, newOwnerId);
                    if (liveChatTranscript.caseId != null) {
                        caseIds.add(liveChatTranscript.caseId );
                    }
                    if (liveChatTranscript.leadId != null) {
                        leadIds.add(liveChatTranscript.leadId );
                    }
                    if (liveChatTranscript.Hot_List__c != null) {
                        hotListIds.add(liveChatTranscript.Hot_List__c );
                    }

                    liveChatTranscript.Is_Child_Owner_Updated__c = true; // before trigger. no DML required

                }

            }

            System.debug('~~ LiveChatTranscriptTriggerHandler caseIds ~~' + caseIds);
            System.debug('~~ LiveChatTranscriptTriggerHandler leadIds ~~' + leadIds);
            System.debug('~~ LiveChatTranscriptTriggerHandler hotListIds ~~' + hotListIds);

            if (leadIds.size() > 0 || Test.isRunningTest() ){
                List<Lead> modifiedLeads = [SELECT Live_Chat_Transcript__c,Id, OwnerId FROM Lead WHERE Id in :leadIds];
                for (Lead lead : modifiedLeads ){
                    for (LiveChatTranscript liveChatTranscript : liveChatTranscripts) {

                        // Note: when a chat end, the status remains as in progress, it is up to the user to change the dispostion

                        if (liveChatTranscript.status == 'Completed' && liveChatTranscript.leadId != null){
                            lead.Live_Chat_Transcript__c = liveChatTranscript.Body;
                        }

                        if (chatOwnerMap.containsKey(liveChatTranscript.Id)){
                            lead.OwnerId = chatOwnerMap.get(liveChatTranscript.Id);
                        }

                    }
                }
                withoutSharingDML.save( modifiedLeads);
            }


            if (caseIds.size() > 0 || Test.isRunningTest()){
                List<Case> modifiedCases = [SELECT LiveChatTranscript_External_Id__c,Id, OwnerId FROM Case WHERE Id in :caseIds];
                for (Case c : modifiedCases ){
                    for (LiveChatTranscript liveChatTranscript : liveChatTranscripts) {
                        if (liveChatTranscript.caseId != null) {
                            c.OwnerId = chatOwnerMap.get(liveChatTranscript.Id);
                        }
                    }
                }
                withoutSharingDML.save( modifiedCases);
            }


            if (hotListIds.size() > 0 || Test.isRunningTest() ){
                List<Hot_List__c> modHotLists = [SELECT LiveChatTranscript_External_Id__c,Id, OwnerId FROM Hot_List__c WHERE Id in :hotListIds];
                for (Hot_List__c c : modHotLists ){
                    for (LiveChatTranscript liveChatTranscript : liveChatTranscripts) {
                        if (liveChatTranscript.Hot_List__c != null) {
                            c.OwnerId = chatOwnerMap.get(liveChatTranscript.Id);
                        }
                    }
                }
                withoutSharingDML.save( modHotLists);
            }


        } catch (Exception e) {
            log.addExceptionLog(e);
        }

    }


}