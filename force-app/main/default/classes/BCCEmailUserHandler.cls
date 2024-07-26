public class BCCEmailUserHandler {
    
    public static void publishBCCEmailEvent(List<Case_Additional_Info__c> bccEmailList,Map<Id,Case_Additional_Info__c> OldMap){
        Set<Id> csIdset=new Set<Id>();
        List<Integration_Event__e> IntgEvtList = new List<Integration_Event__e>();

        for(Case_Additional_Info__c caInfo:bccEmailList){
            if(Trigger.isInsert||(!Trigger.isInsert && caInfo.Bcc_User_Emails__c!=OldMap.get(caInfo.Id).Bcc_User_Emails__c )){
                csIdset.add(caInfo.Case__c);
            }
        }
       List<Case> caseLs=[SELECT Id,(select Bcc_User_Emails__c FROM Case_Additional_Info__r),status,CaseNumber,Serial_Number__c,Owner.Username, Engineering_Escalated_By__r.Username,Escalated_To__r.Username, Escalation_Approver__r.Username, Escalated_to_support_escalations_by__r.Username,RMA_Submitted_By__r.Username, RMA_Approval_1__r.Username, RMA_Approval_2__r.Username,Missing_Serial_Number__c FROM Case where Id IN:csIdset];
       //new PlatformEventHelper().publishObject('JUD-UPDATE',caseLs);
       for(Case cs:caseLs){
       Map<String,Object> payloadMap=new Map<String,Object>();
       Set<string> bccEmailSet=new Set<String>();
           payloadMap.put('Id',cs.Id); 
           payloadMap.put('CaseNumber',cs.CaseNumber);
           if(cs.Serial_Number__c!=null){
               payloadMap.put('Serial_Number__c',cs.Serial_Number__c!=null?cs.Serial_Number__c:'');
           }
           payloadMap.put('Status',cs.Status);
           payloadMap.put('Owner',(Object)(cs.owner));
           if(cs.Engineering_Escalated_By__c!=null){
               payloadMap.put('Engineering_Escalated_By__r',cs.Engineering_Escalated_By__c!=null?(Object)(cs.Engineering_Escalated_By__r):'');
           }
           if(cs.Escalated_To__c!=null){
               payloadMap.put('Escalated_To__r',cs.Escalated_To__c!=null?(Object)(cs.Escalated_To__r):'');
           }
           if(cs.Escalation_Approver__c!=null){
               payloadMap.put('Escalation_Approver__r',cs.Escalation_Approver__c!=null?(Object)(cs.Escalation_Approver__r):'');
           }
           if(cs.Escalated_to_support_escalations_by__c!=null){
               payloadMap.put('Escalated_to_support_escalations_by__r',cs.Escalated_to_support_escalations_by__c!=null?(Object)(cs.Escalated_to_support_escalations_by__r):'');
           }
           if(cs.RMA_Submitted_By__c!=null){
               payloadMap.put('RMA_Submitted_By__r',cs.RMA_Submitted_By__c!=null?(Object)(cs.RMA_Submitted_By__r):'');
           }
           if(cs.RMA_Approval_1__c!=null){
               payloadMap.put('RMA_Approval_1__r',cs.RMA_Approval_1__c!=null?(Object)(cs.RMA_Approval_1__r):'');
           }
           if(cs.RMA_Approval_2__c!=null){
               payloadMap.put('RMA_Approval_2__r',cs.RMA_Approval_2__c!=null?(Object)(cs.RMA_Approval_2__r):'');
           }
           if(cs.Missing_Serial_Number__c!=null){
               payloadMap.put('Missing_Serial_Number__c',cs.Missing_Serial_Number__c!=null?cs.Missing_Serial_Number__c:'');
           }
        
           
           for(Case_Additional_Info__c caInfo:cs.Case_Additional_Info__r){
               bccEmailSet.add(caInfo.Bcc_User_Emails__c);
           }
           payloadMap.put('bccUserEmails',bccEmailSet);
           
           Integration_Event__e IntgEvt = new Integration_Event__e();
                           IntgEvt.Object_Name__c='Case';
                           IntgEvt.UUID__c = PlatformEventHelper.GUIDGenerator();
                           IntgEvt.Record_ID__c=cs.Id;
                           IntgEvt.Event_Type__c = Trigger.isUpdate?'JUD-UPDATE':'JUD-INSERT';
                           IntgEvt.Object_Payload__c=JSON.serialize(payloadMap);
                           System.debug('Payload::: '+JSON.serialize(payloadMap));
                           IntgEvtList.add(IntgEvt);
		   
			}
        if(!IntgEvtList.isEmpty()){
            if(Trigger.isUpdate){
               ZendeskIntegrationHandler.publishObject('JUD-UPDATE', IntgEvtList); 
            }
               ZendeskIntegrationHandler.publishObject('JUD-INSERT', IntgEvtList); 
                  

        }
         
    }

}