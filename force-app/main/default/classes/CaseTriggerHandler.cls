public with sharing class CaseTriggerHandler extends TriggerHandler {
        
    public override void beforeInsert() {
        
        List<Case> newCases = Trigger.New;        
        CaseModel.processLiveChatCases(newCases);   
        CaseModel.updateCaseSupportRegion(newCases);  //SFDC-12495 
        CaseModel.beforeInsertHelper(newCases);
        CaseModel.updateComplianceStatus(newCases);
        CaseModelBeforeInsertHelper.processRecords(newCases);
        if(!FlowActionTriggerHandler.isExecutedBeforeInsert){
            FlowActionTriggerHandler.process('Case', 'BeforeInsert');
        } 
    }  
    
    public override void afterInsert() {
        
        List<Case> newCases = Trigger.New; 
        CaseModel.PopulateSendCallbackNotificationOnInsert(newCases);  
        if(!FlowActionTriggerHandler.isExecutedAfterInsert){ 
            FlowActionTriggerHandler.process('Case', 'AfterInsert');
        }
    }  
    
    // This method is use for Before Update.
    public override void beforeUpdate() {
        
        
       
        List<Case> newCases = Trigger.New;
        Map<Id, Case> oldMap = (Map<Id, Case>) Trigger.oldMap;
         
        List<Case> modifiedCaseList = new List<Case>();
        CaseModel.PopulateSendCallbackNotificationOnUpdate(newCases, oldMap); 
        CaseModel.beforeUpdateHelper(newCases, oldMap);
		CaseModel.updateComplianceStatus(newCases);
        CaseModelBeforeUpdateHelper.processRecords(newCases, oldMap);
       	ZendeskIntegrationHandler.xdrCasePendingAssignment(newCases,oldMap); //SFDC-19319, 19320
        if(!FlowActionTriggerHandler.isExecutedBeforeUpdate || Test.isRunningTest()){
            if(!FlowActionTriggerHandler.byPass){
                 FlowActionTriggerHandler.process('Case', 'BeforeUpdate');
            }
        } 
        
        
    }
    // This method is use for after Update.
    public override void afterUpdate() { 
        Map<Id, Case> oldMap = (Map<Id, Case>) Trigger.oldMap;
        Map<Id, Case> MapNew = (Map<Id, Case>) Trigger.newMap;
         List<Case> newList = (List<Case>) Trigger.new;
        CaseModel.feedOwnerChangesTracking(oldMap,MapNew);//SFDC-18898
       	ZendeskIntegrationHandler.createTicketInZendesk(oldMap,MapNew); //SFDC-19300
        ZendeskIntegrationHandler.updateTicketInZendesk(oldMap,MapNew); //SFDC-20309
        CaseModelAfterUpdateHelper.afterUpdateClosedCaseReason(newList,oldMap); //SFDC-19334
        CaseModelAfterUpdateHelper.afterUpdate(newList, oldMap); // SFDC-19367; SFDC-19355
       if(!FlowActionTriggerHandler.isExecutedAfterUpdate){
             if(!FlowActionTriggerHandler.byPass){
                 FlowActionTriggerHandler.process('Case', 'AfterUpdate');
             }else{
                  FlowActionTriggerHandler.byPass = false;
             }
        }

        If(!CaseXDREscalationHelper.isExecuted){
            CaseXDREscalationHelper.isExecuted=true;
            CaseXDREscalationHelper.xdrOwnerChange(MapNew,oldMap);//SFDC-19321
            if(System.IsBatch() == false && System.isFuture() == false){
                Map<Id,Case> technicalMapNew=New Map<Id,Case>();
                Map<Id,Case> technicalMapOld=New Map<Id,Case>();
                Id technicalRecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Support').getRecordTypeId();
                for(case cs:MapNew.values()){
                     if(technicalRecordTypeId==cs.RecordTypeId){
                        technicalMapNew.put(cs.Id,cs);
                        technicalMapOld.put(cs.Id,oldMap.get(cs.Id));
                    }
                }
                if(technicalMapNew.size()>0){
                    CaseXDREscalationHelper.postCommentToZendeskOnFieldUpdate(JSON.serialize(technicalMapNew),JSON.serialize(technicalMapOld));//SFDC-19360
                }
            }
       	}
       
        
    } 
}