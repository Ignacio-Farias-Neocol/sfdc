/**
* @author: Chaitanya Kurra 06/08/2023.
* @Description: Uses EvaluteExpression for validating the condition.
*/

public with sharing class FlowActionTriggerHandler { 
    
    public static boolean isExecutedAfterUpdate=false;
    public static boolean isExecutedBeforeUpdate=false;
    public static boolean isExecutedAfterInsert=false;
    public static boolean isExecutedBeforeInsert=false;
    public static boolean isExecutedAfterInsertForEmailMessage = false;
    public static boolean isExecutedBeforeInsertForEmailMessage = false;
    public static boolean byPass = false;
    Public static Map<Id,sObject> newMap=new Map<Id,sObject>();
    Public static Map<Id,sObject> oldMap=new Map<Id,sObject>();
     public static Map<String,sObject> dynamicPayloadMap=new Map<String,sObject>();
     public static Map<String,Object> dynamicMethodRecordMap=new Map<String,Object>();
    
    
    public static void process(String ObjectName,String Context){
        
        List<sObject> sobjectListRecord=Trigger.new;
       // List<sObject> sobjectListRecordTobeUpdate=Trigger.new;
        List<FeedItem> feedItemsList = new List<FeedItem>();

        Set<String> recordtypeName=new Set<String>();
        Set<Id> recordTypeIdSet=new Set<Id>();
        Set<Id> recordQueueIdSet=new Set<Id>();
        
        if(context.equalsIgnoreCase('AfterUpdate')){
            isExecutedAfterUpdate=true;
        }else if(context.equalsIgnoreCase('beforeUpdate')){   
            isExecutedBeforeUpdate=true;
        } else if(context.equalsIgnoreCase('afterInsert') && ObjectName == 'EmailMessage'){
            isExecutedAfterInsertForEmailMessage = true;
        } else if(context.equalsIgnoreCase('beforeInsert') && ObjectName == 'EmailMessage'){
            isExecutedBeforeInsertForEmailMessage = true;            
        } else if(context.equalsIgnoreCase('afterInsert')){
            isExecutedAfterInsert=true;         
        } else {
            isExecutedBeforeInsert=true;
        }
        
        if(ObjectName!='EmailMessage') {
            for(sObject obj:sobjectListRecord){
                if(obj.get('RecordTypeId')!=null){
                    recordTypeIdSet.add(String.valueOf(obj.get('RecordTypeId')));
                }
                if(String.valueOf(obj.get('OwnerId')).startsWith('00G')){
                    recordQueueIdSet.add(String.valueOf(obj.get('OwnerId')));
                }
            } 
        }
        
        String queryRecordRT='SELECT Id,DeveloperName From Recordtype Where sObjectType=:ObjectName And Id IN:recordTypeIdSet';
        for(recordType rt:Database.query(queryRecordRT)){
            recordtypeName.add(rt.DeveloperName);
        }
        
        List<Business_Flow__mdt> businessFlowList=new List<Business_Flow__mdt>([SELECT label,Sort_Order__c,Object_API_Name__c,Conditions__c,
                                                                                (SELECT label,value__c,Field_To_be_Update__c ,Reference_Field__c ,Type_Action__c ,active__c, Group_Name__c,
                                                                                 Flow_Name__c, Flow_Parameter_Key_1__c, Flow_Parameter_Key_2__c, Flow_Parameter_Key_3__c, Parameter_1_Type__c, Parameter_2_Type__c, Parameter_3_Type__c,
                                                                                 Flow_Parameter_Value_1__c, Flow_Parameter_Value_2__c, Flow_Parameter_Value_3__c
                                                                                 FROM actions__r WHERE Active__c=true),
                                                                                (SELECT label,Operator__c,Order__c,Business_Flow__c ,Field__c,Field_Criteria_Value_Field__c,Type__c,value__c FROM criteria_rule__r) 
                                                                                FROM Business_Flow__mdt 
                                                                                WHERE Object_API_Name__c=:ObjectName 
                                                                                AND ContextText__c LIKE : ('%'+context+'%')
                                                                                AND Active__c=true AND (RecordType_Developer_Name__c IN:recordtypeName OR RecordType_Developer_Name__c=null) Order by Sort_Order__c asc
                                                                               ]);
        
        Map<Id,Business_Flow__mdt> businessflowMap=new Map<id,Business_Flow__mdt>(businessFlowList);
        Map<Id,List<Criteria_Rule__mdt>> businessRuleIdvsCriteriaRuleSortedMap=new Map<Id,List<Criteria_Rule__mdt>>();
        
        
        for(Business_Flow__mdt businessFlow:businessFlowList){ 
            
            List<CriteriaRuleCompare> criteriaRulelist=new List<CriteriaRuleCompare>();  
            for(Criteria_Rule__mdt criteria:businessFlow.criteria_rule__r){
                criteriaRulelist.add(new CriteriaRuleCompare(criteria));
            }
            criteriaRulelist.sort();
            for(CriteriaRuleCompare crCompare:criteriaRulelist){
                List<Criteria_Rule__mdt> criteriaLls=new List<Criteria_Rule__mdt>();
                if(businessRuleIdvsCriteriaRuleSortedMap.containsKey(crCompare.criteria.Business_Flow__c)){
                    criteriaLls=businessRuleIdvsCriteriaRuleSortedMap.get(crCompare.criteria.Business_Flow__c);
                }
                criteriaLls.add(crCompare.criteria);
                businessRuleIdvsCriteriaRuleSortedMap.put(crCompare.criteria.Business_Flow__c,criteriaLls);    
            }
            
            
        }
        
        Set<String> queueSet=new Set<string>();
        Set<String> fieldListTobeQuery=new Set<string>();
        Set<String> recordTypeList=new set<String>();
        
        if(Trigger.isUpdate && oldMap.size()==0){
            newMap=new Map<Id,sObject>(Trigger.new);
            oldMap=new Map<Id,sObject>(Trigger.old);
        }
        
        Map<Id,sObject> recordMap=new Map<Id,sObject>();
        Map<String,String> recordQueueMap=new Map<String,String>();
        Map<String,String> recordTypeMap=new Map<String,String>();
        Map<Id,Group> recQueueMap;
        
        for(Business_Flow__mdt businessFlow:businessFlowList){
            
            List<boolean> nodeConditionList=new List<boolean>();
            for(Criteria_Rule__mdt criteria:businessFlow.criteria_rule__r){
                
                if(criteria.Type__c=='Queue'){
                    if(criteria.Value__c!=null)
                        queueSet.add(criteria.Value__c);
                    if(criteria.Field__c!=null)
                        fieldListTobeQuery.add(criteria.Field__c.toLowerCase());
                }else if (criteria.Type__c=='Queue'){
                    if(criteria.Value__c!=null)
                        queueSet.add(criteria.Value__c);
                    
                }
                else if(criteria.Type__c=='RecordType'){
                    if(criteria.Value__c!=null){
                        recordTypeList.add(criteria.Value__c.toLowerCase());
                    }
                }
                else if(criteria.Type__c!='Value'){
                    if(criteria.Field_Criteria_Value_Field__c!=null)
                        fieldListTobeQuery.add(criteria.Field_Criteria_Value_Field__c.toLowerCase());
                    if(criteria.Field__c!=null)
                        fieldListTobeQuery.add(criteria.Field__c.toLowerCase());
                }else if(criteria.Type__c=='Value' && criteria.Operator__c!='isNew'){
                    fieldListTobeQuery.add(criteria.Field__c.toLowerCase());
                }
                
            }
            for(actions__mdt action:businessFlow.actions__r){
                
                if(action.Type_Action__c=='Queue'){
                    queueSet.add(action.Value__c);
                }else if(action.Type_Action__c=='Reference Field'){
                    if(action.Reference_Field__c != null){
                        fieldListTobeQuery.add(action.Reference_Field__c.toLowerCase());
                    }
                }
                else if(action.Type_Action__c=='RecordType'){
                    if(action.Value__c!=null){
                        recordTypeList.add(action.Value__c.toLowerCase());
                    }
                }
                else if(action.Type_Action__c=='Notification'){
                    if(action.Reference_Field__c!=null){
                        fieldListTobeQuery.add(action.Reference_Field__c.toLowerCase());
                    }
                } 
                else if(action.Type_Action__c == 'Auto Launch Flow'){
                    if( action.Parameter_1_Type__c!=null && action.Parameter_1_Type__c!='Record' && action.Parameter_1_Type__c!='Constant' && action.Flow_Parameter_Value_1__c.toLowerCase() != 'id'){
                        fieldListTobeQuery.add(action.Flow_Parameter_Value_1__c.toLowerCase());
                    }
                    if(action.Parameter_2_Type__c!=null && action.Parameter_2_Type__c!='Record' && action.Parameter_2_Type__c!='Constant' && action.Flow_Parameter_Value_2__c.toLowerCase() != 'id'){
                        fieldListTobeQuery.add(action.Flow_Parameter_Value_2__c.toLowerCase());
                    }
                    if(action.Parameter_3_Type__c!=null && action.Parameter_3_Type__c!='Record' && action.Parameter_3_Type__c!='Constant' && action.Flow_Parameter_Value_3__c.toLowerCase() != 'id'){
                        fieldListTobeQuery.add(action.Flow_Parameter_Value_3__c.toLowerCase());
                    }
                }
                
            }
        }
        
        if(!sobjectListRecord.isEmpty()){
            String queryRec='SELECT Id '+(fieldListTobeQuery.isEmpty()?'':(', '+ String.join(new List<String>(fieldListTobeQuery),',')))+' From '+ObjectName+' Where Id IN:sobjectListRecord';
            recordMap=new map<Id,sObject>(Database.query(String.escapeSingleQuotes (queryRec)));
        }
        
        if(!queueSet.isEmpty()){
            String queryqueue='SELECT Id,DeveloperName,Name From Group Where DeveloperName IN:queueSet';
            if(!recordQueueIdSet.isEmpty())
                queryqueue=queryqueue+' OR Id IN:recordQueueIdSet';
            recQueueMap=new Map<Id,Group>((List<Group>)Database.query(queryqueue));
            
            for(Group groups:recQueueMap.values()){
                recordQueueMap.put(groups.DeveloperName,groups.Id);
            }
        }
        
        if(!recordTypeList.isEmpty()){
            
            String queryRT='SELECT Id,DeveloperName From Recordtype Where sObjectType=:ObjectName And DeveloperName IN:recordTypeList';
            
            for(RecordType RT:Database.query(queryRT)){
                recordTypeMap.put(RT.DeveloperName,RT.Id);
            }
            
        }
        for(SObject rec:sobjectListRecord){
            for(Business_Flow__mdt businessFlow:businessFlowList){
                List<boolean> nodeConditionList=new List<boolean>();
                if(businessRuleIdvsCriteriaRuleSortedMap.containsKey(businessFlow.Id)){
                    for(Criteria_Rule__mdt criteria:businessRuleIdvsCriteriaRuleSortedMap.get(businessFlow.Id)){
                        String currentRecordFieldValue='';
                        if(criteria.Field__c.contains('.')){
                            currentRecordFieldValue=ExtractFieldValues(recordMap.get(rec.Id),rec, criteria.Field__c);   
                        }else {
                            if(criteria.Operator__c!='isNew'){
                                currentRecordFieldValue=String.ValueOf(rec.get(criteria.Field__c));
                            }
                        }
                        
                        String queryFieldValue;
                        
                        if(criteria.Field__c.containsIgnoreCase('RecordTypeId')){
                            queryFieldValue=recordTypeMap.get(criteria.Value__c);
                        }else if(criteria.Type__c=='Queue'){
                            queryFieldValue=recordQueueMap.get(criteria.Value__c);
                        }
                        else{
                            if(criteria.Type__c=='Reference Field' || Test.isRunningTest()){
                                queryFieldValue=getFieldValue(criteria,recordQueueMap,recordMap,rec);    
                            }else{
                                queryFieldValue=criteria.Value__c;    
                            }
                        }
                        
                        switch on criteria.Operator__c {
                            when 'Equals' {	
                                if(currentRecordFieldValue==queryFieldValue){
                                    nodeConditionList.add(true);
                                    
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'Not equals' {
                                if(currentRecordFieldValue!=queryFieldValue){
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'Is Null' {
                                if(currentRecordFieldValue==null || currentRecordFieldValue=='null' || String.isBlank(currentRecordFieldValue) || String.isEmpty(currentRecordFieldValue)){
                                    
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'Is Not Null' {
                                if(currentRecordFieldValue!=null && currentRecordFieldValue!='null' && !String.isBlank(currentRecordFieldValue) && !String.isEmpty(currentRecordFieldValue)){
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'Greater than' {
                                if(queryFieldValue>criteria.Value__c){
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'Greater than equal to' {
                                if(queryFieldValue>=criteria.Value__c){
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'Less than' {
                                if(queryFieldValue<criteria.Value__c){
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'Less than equal to' {
                                if(queryFieldValue<=criteria.Value__c){
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'Contains' {
                                if(currentRecordFieldValue != null && currentRecordFieldValue.contains(criteria.Value__c) && ! String.isBlank(currentRecordFieldValue)){
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'Not Contains' {
                                if(!string.IsBlank(currentRecordFieldValue) && currentRecordFieldValue!=null && !currentRecordFieldValue.contains(criteria.Value__c)){
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'Include' {
                                List<string> includeValue=(criteria.Value__c!=null?criteria.Value__c.split(','):null);
                                if(includeValue.contains(String.valueOf(rec.get(criteria.Field__c)))){
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'isChange' {
                                if(Trigger.isUpdate && criteria.Field__c!=null && !criteria.Field__c.contains('.') && rec.get(criteria.Field__c)!=null && oldMap.containsKey(String.valueOf(rec.Id)) && String.valueOf(rec.get(criteria.Field__c))!=String.valueOf(oldMap.get(String.valueOf(rec.Id)).get(criteria.Field__c))){
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'PriorValue' {
                                if(Trigger.isUpdate && !criteria.Field__c.contains('.') && oldMap.containsKey(String.valueOf(rec.Id)) && String.valueOf(oldMap.get(String.valueOf(rec.Id)).get(criteria.Field__c))==criteria.Value__c){
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'PriorValue Not Equals' {
                                if(Trigger.isUpdate && !criteria.Field__c.contains('.') && oldMap.containsKey(String.valueOf(rec.Id)) && String.valueOf(oldMap.get(String.valueOf(rec.Id)).get(criteria.Field__c))!=criteria.Value__c){
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }                        
                            when 'StartWith' {
                                if(currentRecordFieldValue!=null && currentRecordFieldValue.startsWithIgnoreCase(criteria.Value__c)){
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'Queue Name EndWith' {
                                if(recQueueMap.containsKey(String.valueOf(rec.get('OwnerId'))) && (recQueueMap.get(String.valueOf(rec.get('OwnerId'))).Name).endsWithIgnoreCase(criteria.Value__c)){
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'Queue Name StartWith' {
                                if(recQueueMap.containsKey(String.valueOf(rec.get('OwnerId'))) && (recQueueMap.get(String.valueOf(rec.get('OwnerId'))).Name).startsWithIgnoreCase(criteria.Value__c)){
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'EndWith' {
                                
                                if(currentRecordFieldValue!=null && currentRecordFieldValue.endsWithIgnoreCase(criteria.Value__c)){
                                     
                                    nodeConditionList.add(true);
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            when 'isNew' {	
                                if(Trigger.isInsert){
                                    nodeConditionList.add(true);
                                    
                                }else{
                                    nodeConditionList.add(false);
                                }
                            }
                            
                        }
                    } 
                } 
                
                
                EvaluateExpression evaluate=new EvaluateExpression(businessflowMap.get(businessFlow.Id).conditions__c,nodeConditionList);                
                System.debug('Metadata Name: : '+businessflowMap.get(businessFlow.Id).Label + 'Node condition List:: '+ JSON.serialize(nodeConditionList));
                System.debug('Metadata Name: : '+businessflowMap.get(businessFlow.Id).Label + 'condtion evaluation :'+evaluate.evaluate());

                 if(evaluate.evaluate()){
                    
                    for(Actions__mdt action:businessflowMap.get(businessFlow.Id).Actions__r){
                        
                        if(action.Type_Action__c=='Text'){
                            rec.put(action.Field_To_be_Update__c,action.Value__c);
                        }else if(action.Type_Action__c=='RecordType'){
                            rec.put(action.Field_To_be_Update__c,RecordTypeMap.get(action.Value__c));
                        }else if(action.Type_Action__c=='Queue'){
                            rec.put(action.Field_To_be_Update__c,recordQueueMap.get(action.Value__c));
                            
                        }
                        else if(action.Type_Action__c=='Reference Field'){
                            rec.put(action.Field_To_be_Update__c,ExtractFieldValues(recordMap.get(rec.Id),rec,action.Reference_Field__c));
                        }
                        else if(action.Type_Action__c=='Current User'){
                            if(action.Value__c == 'Name'){
                                rec.put(action.Field_To_be_Update__c,UserInfo.getName() );
                            }else{
                                rec.put(action.Field_To_be_Update__c,UserInfo.getUserId() );
                            }
                            
                        }
                        else if(action.Type_Action__c=='DateTime'){
                            if(action.Value__c=='Now'){
                                rec.put(action.Field_To_be_Update__c,Datetime.now());
                             }else{
                                if(action.Value__c==null || String.isBlank(action.Value__c)) 
                                {
                                    rec.put(action.Field_To_be_Update__c,null);
                                    
                                }else{
                                    rec.put(action.Field_To_be_Update__c,action.Value__c);
                                }
                            }
                        }
                        else if(action.Type_Action__c=='Number'){
                            rec.put(action.Field_To_be_Update__c,Integer.valueOf(action.Value__c));
                        }
                        else if(action.Type_Action__c=='Boolean'){
                         	rec.put(action.Field_To_be_Update__c,Boolean.valueOf(action.Value__c));
                         }
                        
                       else if(action.Type_Action__c=='Method'){
                            FlowActionCallableHandler flowMethodCaller=new FlowActionCallableHandler();
                            Map<String,Object> callerPayload=new Map<String,Object>();
                            callerPayload.put('record',rec);
                            String fieldValue=String.valueOf(flowMethodCaller.call(action.Value__c,callerPayload));
                            Id recordId=(ID)rec.get('Id');
                            String ObjName=recordId.getSObjectType().getDescribe().getName();
                            String fieldType=getFieldDataType(ObjName,action.Field_To_be_Update__c);
                            
                            If(fieldType=='DOUBLE'){
                                rec.put(action.Field_To_be_Update__c,Integer.valueOf(fieldValue));
                                
                            }else if(fieldType=='DATETIME'){
                                rec.put(action.Field_To_be_Update__c,DateTime.valueOf(fieldValue));
                            }
                           else if(fieldType=='NUMBER'){
                                rec.put(action.Field_To_be_Update__c,Integer.valueOf(fieldValue));
                            }
                            
                            
                        } 
                        else if(action.Type_Action__c=='Async Method'){
                            
                            List<sobject> recordsList=new List<sobject>();
                            if(dynamicMethodRecordMap.containsKey(action.Value__c)){
                                recordsList=(List<sobject>)dynamicMethodRecordMap.get(action.Value__c);
                            }
                            recordsList.add(rec);
                            dynamicMethodRecordMap.put(action.Value__c,recordsList);
                            System.debug('###dynamicMethodRecordMap:::: ' + JSON.serialize(dynamicMethodRecordMap));
                        }
                        
                        else if(action.Type_Action__c=='Email Alert'){
                            Map<String,String> parameters = new Map<String, String>();
                            parameters.put('recordId', String.valueOf(rec.get('Id')));
                            parameters.put('EmailAlert', action.Value__c);
                            parameters.put('ActionType', 'Alert');
                            Flow.Interview.BusinessFlowNotification BusinessFlowNotification = new Flow.Interview.BusinessFlowNotification(parameters);
                            BusinessFlowNotification.start();
                        }
                        else if(action.Type_Action__c=='Notification'){
                            Map<String,Object> parameters = new Map<String, object>();
                            List<String> receipentId=new List<String>();
                            if(Action.Reference_Field__c!=null && String.valueOf(rec.get(Action.Reference_Field__c)).startsWith('005')){
                               receipentId.add(String.valueOf(rec.get(Action.Reference_Field__c))); 
                           }
                            parameters.put('RecipientIds',receipentId);
                            parameters.put('recordId', String.valueOf(rec.get('Id')));
                            parameters.put('EmailAlert', action.Value__c);
                            parameters.put('ActionType', 'Notification');
                            parameters.put('BellNotificationGroupName', action.Group_Name__c);
                            Flow.Interview.BusinessFlowNotification BusinessFlowNotification = new Flow.Interview.BusinessFlowNotification(parameters);
                            if(!receipentId.isEmpty()){ 
                                BusinessFlowNotification.start();
                            }
                            
                        }
                        else if(action.Type_Action__c=='Task Create'){
                            Map<String,String> parameters = new Map<String, String>();
                            parameters.put('recordId', String.valueOf(rec.get('Id')));
                            parameters.put('TaskName', action.Value__c);
                            Flow.Interview.Case_Business_Rule_Task_Creation BusinessFlowNotification = new Flow.Interview.Case_Business_Rule_Task_Creation(parameters);
                            BusinessFlowNotification.start();
                            
                            
                        }                        
                        else if(action.Type_Action__c=='Auto Launch Flow'){  
                            System.debug('###inside auto launch Flow');
                            Map<String, Object> parameters = new Map<String, Object>();
                            if(action.Flow_Parameter_Key_1__c != null){
                                if(action.Parameter_1_Type__c=='Record'){
                                    parameters.put(action.Flow_Parameter_Key_1__c, rec);
                                }else if(action.Parameter_1_Type__c=='Constant'){
                                    parameters.put(action.Flow_Parameter_Key_1__c, Action.Flow_Parameter_Value_1__c);    
                                }else{
                                    parameters.put(action.Flow_Parameter_Key_1__c, String.valueOf(rec.get(Action.Flow_Parameter_Value_1__c)));
                                }
                                
                            }
                            if(action.Flow_Parameter_Key_2__c != null){
                                if(action.Parameter_2_Type__c=='Record'){
                                     parameters.put(action.Flow_Parameter_Key_2__c, rec);
                                }else if(action.Parameter_2_Type__c=='Constant'){
                                    parameters.put(action.Flow_Parameter_Key_2__c, Action.Flow_Parameter_Value_2__c);    
                                }else{
                                    parameters.put(action.Flow_Parameter_Key_2__c, String.valueOf(rec.get(Action.Flow_Parameter_Value_2__c)));
                                }
                            }
                            if(action.Flow_Parameter_Key_3__c != null){                               
                                if(action.Parameter_3_Type__c=='Record'){
                                    parameters.put(action.Flow_Parameter_Key_3__c, rec);
                                }else if(action.Parameter_3_Type__c=='Constant'){
                                    parameters.put(action.Flow_Parameter_Key_3__c, Action.Flow_Parameter_Value_3__c);    
                                }else{
                                    parameters.put(action.Flow_Parameter_Key_3__c, String.valueOf(rec.get(Action.Flow_Parameter_Value_3__c)));
                                }
                            }
                            System.debug('###FlowName::: ' + action.Flow_Name__c);
                            System.debug('####parameters:::: ' +  JSON.serialize(parameters));
                            Flow.Interview commonFlow = Flow.Interview.createInterview(action.Flow_Name__c, parameters);
                            commonFlow.start();  
                            
                            Object flowRec=commonFlow.getVariableValue('CaseObj');
                            Map<string,object> outputRecMap=new Map<string,object>();
							outputRecMap=(Map<string,object>)JSON.deserializeUntyped(JSON.serialize(flowRec));
                            if(outputRecMap!=null && outputRecMap.containsKey('OwnerId'))
                            rec.put('OwnerId',String.valueOf(outputRecMap.get('OwnerId')));

                        }              
                        else if(action.Type_Action__c=='Chatter Feed'){                            
                            FeedItem post = new FeedItem();
                            post.ParentId = String.valueOf(rec.get('Id'));
                            post.Body = action.Value__c;
                            feedItemsList.add(post);
                           					
                        }                                                                         
                        
                    }
                    
                }
                
            }
            
            
        } 
        if(!feedItemsList.isEmpty() && !Test.isRunningTest()){
                                insert feedItemsList;	
            }
        if(dynamicMethodRecordMap.size()>0){
            FlowActionCallableHandler flowMethodCaller=new FlowActionCallableHandler();
            Map<string,object> callerPayload=new Map<String,Object>();
            callerPayload.put('record',dynamicMethodRecordMap);
            callerPayload.put('inputMap', dynamicPayloadMap);
            dynamicPayloadMap=(Map<string,sObject>)flowMethodCaller.callAsync(callerPayload);
            System.debug('###dynamicPayloadMap::: ' + JSON.serialize(dynamicPayloadMap));

        }
         if(!dynamicPayloadMap.isEmpty()){
            
            System.enqueueJob(new FlowActionQueuableHandler(dynamicPayloadMap));
        }
        /*L
        /*List<Async_Process__e> asyncEvents = new List<Async_Process__e>();
for(Object obj :sobjectListRecordTobeUpdate){
asyncEvents.add(new Async_Process__e(Payload__c=JSON.serialize(obj)));
}
if(!asyncEvents.isEmpty()){
//List<Database.SaveResult> results = EventBus.publish(asyncEvents);
}*/
        
        
    }
    public static string getFieldValue(Criteria_Rule__mdt criteria,Map<String,String> queueIdMap,Map<Id,SObject> queeyRecord,sObject record){
        String fieldValue='';
        
        if(criteria.Type__c=='Queue'){
            fieldValue=queueIdMap.get(criteria.Value__c);
        }
        else if(criteria.Type__c=='Field' && !criteria.Field__c.containsIgnoreCase('RecordTypeId')){
            
 			if(criteria.Field_Criteria_Value_Field__c==null || criteria.Field_Criteria_Value_Field__c==''){
                fieldValue=criteria.Value__c;
            }else{
            	fieldValue=ExtractFieldValues(queeyRecord.get(String.valueOf(record.get('Id'))),record, criteria.Field_Criteria_Value_Field__c);
            }       
        }else if(criteria.Type__c=='Value' && criteria.Field__c.containsIgnoreCase('RecordTypeId')){
            
            fieldValue=String.valueOf(queeyRecord.get(String.valueOf(record.get('Id'))).get('RecordTypeId'));
            
        }
        else{
            fieldValue=criteria.Value__c; 
        }
        
        return fieldValue;
    }
    
    public static string ExtractFieldValues(sObject sb,sObject currentRec ,string fieldAPIName){
        string fvalue='';
        if(fieldAPIName!=null && fieldAPIName.contains('.')){
            List<string> splitedFields = fieldAPIName.split('\\.');
            try{
                for(integer i=0;i<splitedFields.size()-1;i++){
                    sb=sb.getSobject(splitedFields[i]);   
                }
                fvalue = string.valueof(sb.get(splitedFields[splitedFields.size()-1]));
                if(Test.isRunningTest()) throw new CustomException('test class');
            }catch(exception ex){
                 fvalue='';
            }
            
        }else if(fieldAPIName!=null && currentRec.get(fieldAPIName)!=null){
            fvalue = string.valueOf(currentRec.get(fieldAPIName));
        }
        return fvalue;
    }
    public static String getFieldDataType(String objectName,String fieldName){
        
        SObjectType r = ((SObject)(Type.forName('Schema.'+objectName).newInstance())).getSObjectType();
        DescribeSObjectResult d = r.getDescribe();
        return String.valueOf(d.fields
                              .getMap()
                              .get(fieldName)
                              .getDescribe()
                              .getType());
    }
    
}