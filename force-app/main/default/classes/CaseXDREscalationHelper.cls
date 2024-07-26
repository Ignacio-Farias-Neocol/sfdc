/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-07-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
// Test class for this class - CaseModelAfterUpdateHelperTest
public class CaseXDREscalationHelper {
    public static boolean isExecuted=false;
    public static void createPlatformEvent(List<Case> caseList){
        List<Integration_Event__e> evetpayloadList = new List<Integration_Event__e>();
        List<Integration_Event__e> evetpayloadList2 = new List<Integration_Event__e>();
        for(Case cs: caseList){                        
            Integration_Event__e IntgEvt = new Integration_Event__e();
            IntgEvt.Object_Name__c = 'Case';
            IntgEvt.UUID__c = PlatformEventHelper.GUIDGenerator();
            IntgEvt.Record_ID__c = cs.Id;
            
            Map<String, String> payloadMap = new Map<string, String>();
            if(cs.Status == 'Resolved' || cs.Status == 'Closed'){
                payloadMap.put('Id', cs.Id);
                payloadMap.put('XDR_Ticket_Number', cs.XDR_Ticket_Number__c);
                payloadMap.put('Closure_Code', 'Request Implemented');
                payloadMap.put('Request_Type', 'Engineering Request');
                payloadMap.put('Comments', 'User ' + UserInfo.getName() + ' has moved SFDC Case ' + cs.CaseNumber + ' to resolved');
                payloadMap.put('Payload_Type', 'XDRCaseSolved');
                payloadMap.put('XDR_Ticket_Status', 'solved'); 
                IntgEvt.Event_Type__c = 'XDRCaseSolved';
                IntgEvt.Object_Payload__c=JSON.serialize(payloadMap);
                System.debug('Payload::: '+JSON.serialize(payloadMap));
                evetpayloadList.add(IntgEvt);  
            } else {
                payloadMap.put('Id', cs.Id);
                payloadMap.put('XDR_Ticket_Number', cs.XDR_Ticket_Number__c);
                payloadMap.put('Comments', 'Case ' + cs.CaseNumber + ' has be re-escalated to XDR Team ' + cs.XDR_Escalation_Team__c + '. Please pick up case and review updates.');
                payloadMap.put('Payload_Type', 'XDRCaseEscalation');
                payloadMap.put('XDR_Ticket_Status', 'Open');
                IntgEvt.Event_Type__c = 'XDRCaseEscalation';
                IntgEvt.Object_Payload__c=JSON.serialize(payloadMap);
                System.debug('Payload::: '+JSON.serialize(payloadMap));
                evetpayloadList2.add(IntgEvt);  
            }                        
            
        }
        
        if(!evetpayloadList.isEmpty()){            
            ZendeskIntegrationHandler.publishObject('XDRCaseSolved', evetpayloadList);
        }  
        if(!evetpayloadList2.isEmpty()){            
            ZendeskIntegrationHandler.publishObject('XDRCaseEscalation', evetpayloadList2);
        }  
    }
    // SFDC 19360 Start
    @future
    public static void postCommentToZendeskOnFieldUpdate(String newMapReq,String OldMapReq){
        Map<Id,Case> newMap=(Map<Id,Case>)JSON.deserializeStrict(newMapReq,Map<Id,Case>.Class);
        Map<Id,Case> caseChangeoldMap=(Map<Id,Case>)JSON.deserializeStrict(OldMapReq,Map<Id,Case>.class);        
        isExecuted=true;
        Set<Id> xdrEscalatedUserSet=new Set<Id>();
        Set<Id> accountIdset=new Set<Id>();
        Set<Id> contactIdset=new Set<Id>();
        List<Integration_Event__e> evetpayloadList = new List<Integration_Event__e>();
        List<String> includeOnlyField=new List<String>{'Account_s_Name__c',
            'ContactId','AccountId','Contact.Name','Contact.Email','Engineering_Escalated_By__r.Name','Account.Name',
            'Subject',
            'Escalation_Reason__c',
            'Escalation_Description__c',
            'Engineering_Escalated_By__c'}; 
         
        List<String> changeFieldset=new List<String>{'ContactId','AccountId',
            'Subject',
            'Escalation_Reason__c',
            'Escalation_Description__c',
            'Engineering_Escalated_By__c'}; 
        Set<Id> caseIdSet=new Set<id>();
        Set<String> onlyChangeField=new Set<String>();
        for(Case oldCs:caseChangeoldMap.values()){
            xdrEscalatedUserSet.add(oldCs.Engineering_Escalated_By__c);
            accountIdset.add(oldCs.accountId);
            contactIdset.add(oldCs.contactId);
        }
        Map<Id,Contact> contactMap =new Map<Id,Contact>([select id,email,name from contact where ID IN: contactIdset]);
        Map<Id,account> accountMap=new Map<Id,Account>([select id,name from Account where ID IN: accountIdSet]);
        Map<Id,user> esclatedByEngMap=new Map<Id,user>([select id,name from user where ID IN: xdrEscalatedUserSet]);
        
        for(case cs:newMap.values()){
            if(cs.XDR_Ticket_Number__c!=null && cs.XDR_Ticket_Number__c == caseChangeoldMap.get(cs.Id).XDR_Ticket_Number__c ){
            	caseIdSet.add(cs.Id);
            }
        for(String f:changeFieldset){
            
            if(cs.get(f)!=caseChangeoldMap.get(cs.Id).get(f)){
                onlyChangeField.add(f);
            }
        }
            
    }
        if(!onlyChangeField.isEmpty()){
            
        Map<Id,Case> caseMap=new Map<Id,Case>((List<case>)Database.query('SELECT Id,XDR_Ticket_Number__c ,'+String.join(new List<string>(includeOnlyField),',')+' FROM CASE WHERE Id IN:caseIdSet'));
        for(Case event:caseMap.values()){
            Map<String, String> payloadMap = new Map<string, String>();
            
            String commentBody='Information on the ticket has been updated \n'+'\nField: \n';
            Integration_Event__e IntgEvt = new Integration_Event__e();
            IntgEvt.Object_Name__c = 'Case';
            IntgEvt.UUID__c = PlatformEventHelper.GUIDGenerator();
            IntgEvt.Record_ID__c =event.Id;
            IntgEvt.Event_Type__c = 'CaseZenDeskUpdate';
            
            for(String field:onlyChangeField){
                
                 
                if(field=='AccountId'){
                    commentBody=commentBody+'Account_s_Name__c: '+(caseChangeoldMap.get(event.Id).AccountId!=null?accountMap.get(caseChangeoldMap.get(event.Id).AccountId).Name:'') +' Changed to :'+event.Account.Name+ '\n';   
                    payloadMap.put('Account_s_Name__c',event.Account.Name);
                }else if(field=='ContactId'){
                    commentBody=commentBody+' Contact_Name: '+(caseChangeoldMap.get(event.Id).ContactId!=null?contactMap.get(caseChangeoldMap.get(event.Id).ContactId).Name:'') +' Changed to :'+event.Contact.Name+ '\n';  
                    commentBody=commentBody+' Contact_Email: '+(caseChangeoldMap.get(event.Id).ContactId!=null?contactMap.get(caseChangeoldMap.get(event.Id).ContactId).Email:'') +' Changed to :'+event.Contact.Email+  '\n';  
                    payloadMap.put('Contact_Name',event.Contact.Name);
                    payloadMap.put('Contact_Email',event.Contact.Email);
                }
                 else if(field=='Engineering_Escalated_By__c'){
                     commentBody=commentBody+' Engineering_Escalated_By__c: '+(caseChangeoldMap.get(event.Id).Engineering_Escalated_By__c!=null?esclatedByEngMap.get(caseChangeoldMap.get(event.Id).Engineering_Escalated_By__c).Name:'') +' Changed to :'+event.Engineering_Escalated_By__r.Name+ '\n';  
                     payloadMap.put('Engineering_Escalated_By__r_Name',event.Engineering_Escalated_By__r.Name);
                    
                }
                else{
                    commentBody=commentBody+field+': '+String.valueOf(caseChangeoldMap.get(event.Id).get(field))+' Changed to :'+String.valueOf(event.get(field))+  '\n'; 
                    payloadMap.put(field,String.valueOf(event.get(field)));
                }
                    
                
            }
            
            payloadMap.put('Comments',commentBody);
            payloadMap.put('Id', event.Id);
            payloadMap.put('XDR_Ticket_Number', event.XDR_Ticket_Number__c);
            
            IntgEvt.Object_Payload__c=JSON.serialize(payloadMap);
            if(event.XDR_Ticket_Number__c!=null){
                evetpayloadList.add(IntgEvt);
            }
            System.debug('payload::: '+JSON.serialize(evetpayloadList));
            System.debug('payload size=::: '+JSON.serialize(evetpayloadList.size()));
             
        }
        if(!evetpayloadList.isEmpty()){
            ZendeskIntegrationHandler.publishObject('CaseZenDeskUpdate', evetpayloadList);
        }
        }
        
    }
    // SFDC 19360 End
    
    // SFDC 19321 Start
    public static void xdrOwnerChange(Map<id,Case> newMap,Map<Id,case> oldMap){
        isExecuted=true;
        List<feedItem> feedList=new List<feedItem>();
        for(Case cs:newMap.values()){
            if(cs.XDR_Ticket_Owner__c!=oldMap.get(cs.Id).XDR_Ticket_Owner__c){
                feedItem fItem=new feedItem();
                fItem.body='XDR Ticket '+cs.XDR_Ticket_Number__c+' has been reassigned to '+cs.XDR_Ticket_Owner__c;
                fItem.ParentId=cs.Id;
                feedList.add(fItem);
            }
        }
        if(!feedList.isEmpty()){
            insert feedList;
        }
        
    }
     // SFDC 19321 End
}