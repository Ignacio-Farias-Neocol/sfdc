/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 01-31-2023
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class EmailMessageTriggerHelper {
    
    public static void updateCaseOwner(){
        LogModel log = LogModel.startLog('EmailMessageTriggerHelper', 'updateCaseOwner');
        try {        
            List<EmailMessage> emList = Trigger.new;
            for(EmailMessage em: emList){
                if(em.Incoming && !em.Subject.contains('Automatic Reply') && !em.Subject.contains('OOO') && em.ParentId != null){
                    em = [Select ParentId, Parent.Status, Parent.RecordType.DeveloperName, ToAddress from EmailMessage where Id =: em.Id];
                    if(em.Parent.Status == 'Waiting for Customer Response' && em.Parent.RecordType.DeveloperName == 'Web_Case'){
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
                        Set<String> fromEmails = new Set<String>(em.ToAddress.split(';'));                   
                        for(String emailStr: fromEmails){
                            emailStr = emailStr.trim();
                            System.debug('##emailStr:: ' + emailStr);
                            System.debug('##emailToQueueMap:: ' + JSON.serialize(emailToQueueMap));
                            if(emailToQueueMap.containsKey(emailStr)){
                                Case c = new Case();
                                c.Id = em.ParentId;                             
                                c.OwnerId = QueueToIdMap.get(emailToQueueMap.get(emailStr));                            
                                update c;                                                     
                                break;
                            }
                        }                    
                        
                    }
                }
            }
        } catch (Exception e) {
            log.addExceptionLog(e);
        }               
    }
    public static void updateFromAddress(List<EmailMessage> emailMessage){
        Boolean caseFlowBefore =FlowActionTriggerHandler.isExecutedBeforeUpdate;
        Boolean caseFlowAfter = FlowActionTriggerHandler.isExecutedAfterUpdate;
        FlowActionTriggerHandler.isExecutedBeforeUpdate = true;
        FlowActionTriggerHandler.isExecutedAfterUpdate = true;
        LogModel log = LogModel.startLog('EmailMessageTriggerHelper', 'updateCaseFromAddress');
        try{ 	List<EmailMessage> incommingEmailList=new List<EmailMessage>();
        
        List<String> toAndCCAddressList=new List<String>();
        
        List<Case> caselistTObeUpdate=new List<Case>();
        for(EmailMessage em:emailMessage){
            if(em.Incoming && ((String)Em.ParentId).startsWith('500')){
                incommingEmailList.add(em);
            }
        }
        
        if(!incommingEmailList.isEmpty()){
            for(CaseToAdresss__mdt toAddress:[SELECT Id,EmailAddress__c FROM CaseToAdresss__mdt]){
                if(toAddress.EmailAddress__c!=null){
                    toAndCCAddressList.add(toAddress.EmailAddress__c);
                }
            }
            System.debug('v::: '+toAndCCAddressList);
            
            for(EmailMessage em:incommingEmailList){
                for(String address:toAndCCAddressList){
                    if((em.ToAddress!=null && em.ToAddress.ContainsIgnoreCase(address)) || (em.CcAddress!=null && em.CcAddress.ContainsIgnoreCase(address))){ 
                        String toAddress= em.CcAddress==null?em.ToAddress:(em.ToAddress+';'+ em.CcAddress);
                            caselistTObeUpdate.add(new Case(Id=em.ParentId,From_Address_New__c=toAddress));
                        break;
                        
                    }  
                }
                
            }
        }
            if(!caselistTObeUpdate.isEmpty()){
                System.debug('Casesss::: '+caselistTObeUpdate);
                update caselistTObeUpdate;
            } 
           } catch (Exception e) {
            log.addExceptionLog(e);
        } 
            FlowActionTriggerHandler.isExecutedBeforeUpdate = caseFlowBefore;
            FlowActionTriggerHandler.isExecutedAfterUpdate = caseFlowAfter;
    }
}