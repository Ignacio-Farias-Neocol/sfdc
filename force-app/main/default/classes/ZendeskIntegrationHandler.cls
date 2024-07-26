/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-27-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ZendeskIntegrationHandler {
    public static Id xDR_Escalations_QueueId;
    Public static List<case> newCaseList;

     //Start SFDC-19300
   public static void createTicketInZendesk(Map<Id,Case> oldMap,Map<Id,Case> newMap){
       Set<Id> newCaseKeySet= new set<Id>();
       Id technicalRecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
       
       for(id csId: newMap.Keyset() ){
            if(oldMap.get(csId).ownerId != newMap.get(csId).ownerId && technicalRecordTypeId==newMap.get(csId).recordtypeId && newMap.get(csId).XDR_Ticket_Number__c==null){
                newCaseKeySet.add(csId);
            }
       }

       if(!newCaseKeySet.isEmpty()){
           List<String> payLoadFields=new List<String>{
            'Account_s_Name__c',
            'Contact.Name',
            'Contact.Email',
            'Subject',
            'Escalation_Reason__c',
            'CaseNumber',
            'Id',
            'Escalation_Description__c',
            'XDR_Escalation_Team__c',
            'Engineering_Escalated_By__r.Name'};  
                if(xDR_Escalations_QueueId==null){
                    xDR_Escalations_QueueId=[SELECT id From group where type='Queue' AND DeveloperName='XDR_Escalations' Limit 1].Id;
                  }
           String query='SELECT '+String.join(payLoadFields, ',')+ ' From Case Where Id IN:newCaseKeySet';
           if(newCaseList == null){
                 newCaseList=Database.query(query);
           }
               if(newCaseList !=null && newCaseList.size()>0){
                   List<Integration_Event__e> evetpayloadList=new List<Integration_Event__e>();
                   for(Case cs:newCaseList){
                       if(oldMap.get(cs.Id).ownerId!=xDR_Escalations_QueueId && newMap.get(cs.Id).ownerId==xDR_Escalations_QueueId && newMap.get(cs.Id).XDR_Ticket_Number__c==null){
                           
                           Map<String,String> payloadMap=new Map<string,String>();
                           for(String field:payLoadFields){
                               if(field != 'XDR_Escalation_Team__c')
                               		payloadMap.put(field.replace('.','_'),String.valueOf(getField(cs,field)));
                           }
                           if(cs.XDR_Escalation_Team__c == 'SOC') {
                                payloadMap.put('description','Escalated to XDR Team SOC');
								payloadMap.put('Comments','Escalated to XDR Team SOC. Escalation Description : '+ cs.Escalation_Description__c);                               
                           }
                              
                           if(cs.XDR_Escalation_Team__c == 'Enablement') {
                               payloadMap.put('description','Escalated to XDR Team Enablement');
                                payloadMap.put('Comments','Escalated to XDR Team Enablement. Escalation Description : '+ cs.Escalation_Description__c);
                           }
                           if(cs.XDR_Escalation_Team__c == 'Devops') {
                               payloadMap.put('description','Escalated to XDR Team DevOps'); 
                                payloadMap.put('Comments','Escalated to XDR Team DevOps. Escalation Description : '+ cs.Escalation_Description__c);
                           }
                           if(cs.XDR_Escalation_Team__c == 'Dev') {
                               payloadMap.put('description','Escalated to XDR Team Software Engineering');  
                               payloadMap.put('Comments','Escalated to XDR Team Software Engineering. Escalation Description : '+ cs.Escalation_Description__c);
                           }
   						  
                           Integration_Event__e IntgEvt = new Integration_Event__e();
                           IntgEvt.Object_Name__c='Case';
                           IntgEvt.UUID__c = PlatformEventHelper.GUIDGenerator();
                           IntgEvt.Record_ID__c=cs.Id;
                           IntgEvt.Event_Type__c = 'CaseZenDeskCreate ';
                           IntgEvt.Object_Payload__c=JSON.serialize(payloadMap);
                           System.debug('Payload::: '+JSON.serialize(payloadMap));
                           evetpayloadList.add(IntgEvt);
                       }
                   }
               
               if(!evetpayloadList.isEmpty()){
                   publishObject('CaseZenDeskCreate', evetpayloadList);
               } 
           }
           
       }
        
   }
    
   public static void updateTicketInZendesk(Map<Id,Case> oldMap,Map<Id,Case> newMap){
		
        User integrationMulesoftUser;
        List<User> mulesoftUsers = TriggerContextVariables.getMulesoftUsers();
        
        if (!mulesoftUsers.isEmpty()) {
            integrationMulesoftUser = mulesoftUsers[0];
            // Handle the user found scenario
        } 
       if (integrationMulesoftUser!=null && UserInfo.getUserId() != integrationMulesoftUser.Id) {
           Set<Id> newCaseKeySet= new set<Id>();
           Id technicalRecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
           
           for(id csId: newMap.Keyset() ){
                if(oldMap.get(csId).ownerId != newMap.get(csId).ownerId && technicalRecordTypeId==newMap.get(csId).recordtypeId 
                   && newMap.get(csId).XDR_Ticket_Number__c!=null && oldMap.get(csId).XDR_Ticket_Number__c != newMap.get(csId).XDR_Ticket_Number__c){
                    newCaseKeySet.add(csId);
                }
           }
    
           if(!newCaseKeySet.isEmpty()){
               List<String> payLoadFields=new List<String>{
                'Account_s_Name__c',
                'XDR_Ticket_Number__c',
                'XDR_Escalation_Team__c',
                'Escalation_Description__c',
                'Contact.Name',
                'Contact.Email',
                'Subject',
                'Escalation_Reason__c',
                'CaseNumber',
                'Id',
                'Engineering_Escalated_By__r.Name'};  
                    if(xDR_Escalations_QueueId==null){
                        xDR_Escalations_QueueId=[SELECT id From group where type='Queue' AND DeveloperName='XDR_Escalations' Limit 1].Id;
                      }
               String query='SELECT '+String.join(payLoadFields, ',')+ ' From Case Where Id IN:newCaseKeySet';
               if(newCaseList == null){
                     newCaseList=Database.query(query);
               }
                   if(newCaseList !=null && newCaseList.size()>0){
                       List<Integration_Event__e> evetpayloadList=new List<Integration_Event__e>();
                       for(Case cs:newCaseList){
                           if(oldMap.get(cs.Id).ownerId!=xDR_Escalations_QueueId && newMap.get(cs.Id).ownerId==xDR_Escalations_QueueId && newMap.get(cs.Id).XDR_Ticket_Number__c!=null){
                               
                               Map<String,String> payloadMap=new Map<string,String>();
                               for(String field:payLoadFields){
                                   if(field == 'XDR_Ticket_Number__c') {
                                       payloadMap.put('XDR_Ticket_Number', cs.XDR_Ticket_Number__c);
                                   } else {
                                       payloadMap.put(field.replace('.','_'),String.valueOf(getField(cs,field)));
                              		 }
                               }
                               
                               // SFDC-20466: Adding Escalation comments to the event
                               if(oldMap.get(cs.Id).XDR_Ticket_Number__c != newMap.get(cs.Id).XDR_Ticket_Number__c){
                                   payloadMap.put('Comments','Escalated to XDR Team '+ cs.XDR_Escalation_Team__c + '. ' + 'Escalation Description : '+ cs.Escalation_Description__c);
                               }
                               payloadMap.put('Filter','UpdateZendeskTicket');
                              
                               Integration_Event__e IntgEvt = new Integration_Event__e();
                               IntgEvt.Object_Name__c='Case';
                               IntgEvt.UUID__c = PlatformEventHelper.GUIDGenerator();
                               IntgEvt.Record_ID__c=cs.Id;
                               IntgEvt.Event_Type__c = 'CaseZenDeskUpdate';
                               IntgEvt.Object_Payload__c=JSON.serialize(payloadMap);
                               System.debug('Payload::: '+JSON.serialize(payloadMap));
                               evetpayloadList.add(IntgEvt);
                           }
                       }
                   
                   if(!evetpayloadList.isEmpty()){
                       publishObject('CaseZenDeskUpdate', evetpayloadList);
                   } 
               }
               
           }
       }
        
   }
   
    public static Object getField(SObject record, String field)
   {
       if (record == null) return null;
       if (!field.contains('.')) return record.get(field);
       return getField(
           record.getSObject(field.substringBefore('.')),
           field.substringAfter('.')
       );
   }
   //End SFDC-19300 
   
   //Start SFDC-19350
   public static void addCommentInZendesk(Map<Id,SObject> csIdtofeedIdMap){
       
       List<String> payLoadFields=new List<String>{
            'CaseNumber',
            'Id',
            'XDR_Ticket_Number__c'}; 
       Set<Id> newCaseKeySet=csIdtofeedIdMap.keyset();
       Map<Id,case> newCaseMap;
       String query='SELECT '+String.join(payLoadFields, ',')+ ' From Case Where Id IN:newCaseKeySet';
       newCaseMap=new Map<Id,Case>((List<case>)Database.query(query));
       
       List<Integration_Event__e> evetpayloadList=new List<Integration_Event__e>();
           for(Id key:csIdtofeedIdMap.keySet()){
                    Id recId=String.valueOf((String)csIdtofeedIdMap.get(key).Id);
                    String sObjName = recId.getSObjectType().getDescribe().getName();
                   Map<String,String> payloadMap=new Map<string,String>();
                    String body=(sObjName=='FeedItem')?String.valueOf(csIdtofeedIdMap.get(key).get('body')):String.valueOf(csIdtofeedIdMap.get(key).get('Commentbody'));
                    payloadMap.put('Comments',body);
                    payloadMap.put('XDR_Ticket_Number',newCaseMap.get(key).XDR_Ticket_Number__c);
                    payloadMap.put('CaseNumber',newCaseMap.get(key).CaseNumber);
                    payloadMap.put('Id',key);
               
                   Integration_Event__e IntgEvt = new Integration_Event__e();
                   IntgEvt.Object_Name__c='Case';
                   IntgEvt.UUID__c = PlatformEventHelper.GUIDGenerator();
                   IntgEvt.Record_ID__c=key;
                   IntgEvt.Event_Type__c = 'SFCommentZendesk';
                   IntgEvt.Object_Payload__c=JSON.serialize(payloadMap);
                   System.debug('Payload::: '+JSON.serialize(payloadMap));
                   evetpayloadList.add(IntgEvt);
                   
               }
       if(!evetpayloadList.isEmpty()){
           publishObject('SFCommentZendesk', evetpayloadList);  
       } 
   }
   //End SFDC-19350
   
   //Start SFDC-19319 & 19320
   public static void xdrCasePendingAssignment(List<case> csList,Map<Id,Case> oldMap){
       
       Set<Id> newCaseKeySet= new set<Id>();
       Id technicalRecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();

       for(case cs: csList){
            if(technicalRecordTypeId==cs.recordtypeId && cs.XDR_Ticket_Status__c!=null && cs.XDR_Ticket_Status__c != oldMap.get(cs.Id).XDR_Ticket_Status__c ){
                newCaseKeySet.add(cs.Id);
            }
       }
       
       if(!newCaseKeySet.isEmpty()){
           if(xDR_Escalations_QueueId==null){
                    xDR_Escalations_QueueId=[SELECT id From group where type='Queue' AND DeveloperName='XDR_Escalations' Limit 1].Id;
                  }
           for(case cs:csList){
               if(cs.OwnerId==xDR_Escalations_QueueId && cs.XDR_Ticket_Status__c != oldMap.get(cs.Id).XDR_Ticket_Status__c &&(cs.XDR_Ticket_Status__c=='Awaiting XDR Support' || cs.XDR_Ticket_Status__c=='Solved') && cs.Engineering_Escalated_By__c!=null){
                   cs.OwnerId=cs.Engineering_Escalated_By__c;
               }
           }
       }
               
   }
   //End SFDC-19319 & 19320
   
public static List<Database.SaveResult>  publishObject( String operationType, List <sObject> listObject){
         
       List<Database.SaveResult> results = new List<Database.SaveResult>();
           try {


           if (listObject != null && listObject.size() > 0) {
               List<Integration_Event__e> intEvents = new List<Integration_Event__e>();
               List <Integration_Snapshot__c> snapshots = new List <Integration_Snapshot__c>();

               String objName;
               String objLabel;
               objLabel = ((id) ((listObject[0].get('Record_ID__c')))).getSObjectType().getDescribe().getlabel();
               objName = ((id) ((listObject[0].get('Record_ID__c')))).getSObjectType().getDescribe().getName();
               
               for (sObject obj : listObject) {
                   Integration_Event__e iEvent = new Integration_Event__e();
                   iEvent.UUID__c = PlatformEventHelper.GUIDGenerator();
                   iEvent.Object_Name__c = objName;
                   iEvent.Record_ID__c = (String) obj.get('Record_ID__c');
                   iEvent.Object_Payload__c = String.valueOf(obj.get('Object_Payload__c'));
                   iEvent.Event_Type__c = operationType;
                   intEvents.add(iEvent);
                   
                   Integration_Snapshot__c snapshot = new Integration_Snapshot__c();
                   // so the external id should have the format of concatenation of object type , system name, transaction type and record id field
                   snapshot.External_ID__c = objName + '_' + 'SF' + '_' + 'Platform' + '_' + (String) obj.get('Record_ID__c')+'_'+Datetime.now();
                   snapshot.Integration_App__c = 'Platform Event Trigger';

                   snapshot.System_Name__c = 'Salesforce';
                   snapshot.Sync_Status__c = 'Success';
                   snapshot.Record_ID__c = (String) obj.get('Record_ID__c');
                   snapshot.System_Record_ID__c = (String) obj.get('Record_ID__c');
                   snapshot.Object_Name__c = objName;
                   snapshot.Message_Payload__c = String.valueOf(obj.get('Object_Payload__c'));
                   snapshots.add(snapshot);
               }

              
               EventBus.publish(intEvents);
               Database.upsert(snapshots,false); 
               
               System.debug('snapshots :::iD:: '+snapshots[0].Id);  
           }
           
       }
       catch(DmlException de){
           
       } 
       catch (Exception e) {
           
       }
       return results;

   }   
   
}