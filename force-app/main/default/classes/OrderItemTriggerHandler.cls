/**
* Trigger handler for Order Object
*
* @Author Ivan Yeung
* @Date 2018/10/15
* @group Trigger
*/
public with sharing class OrderItemTriggerHandler extends TriggerHandler {
    
    /*
public override void beforeInsert() {
// placeHolder(Trigger.new);
}
*/
    
    /*
public override void beforeUpdate() {
// placeHolder((Map<Id,Account>)Trigger.oldMap, Trigger.new);
// System.debug('~~~~~~~~ order item trigger');
}
*/
    
    /*
public override void afterDelete() {
// 11/30/2018- move to DynamicBusinessRuleAction framework and control by Business_Rule_Action__mdt
// PlatformEventHelper.publishObject( PlatformEventHelper.EVENT_TYPE_DELETE,  Trigger.old);
}
*/
    
    public override void afterInsert() {
        /*
List<OrderItem> newList = Trigger.new;
List<OrderItem> orderItemList = new List<OrderItem>();
for(OrderItem oi: newList){
if(oi.SBCF_Serial_Number__c != null){
orderItemList.add(oi);
}
}

if(!orderItemList.isEmpty()){
//OrderItemTriggerHelper.createProfServCases(orderItemList);
}	
*/
    }
    
    
    
    public override void afterUpdate() {
        System.debug('##After update Order line trigger');
        // 11/30/2018- move to DynamicBusinessRuleAction framework and control by Business_Rule_Action__mdt
        // PlatformEventHelper.publishObject( PlatformEventHelper.EVENT_TYPE_UPDATE, Trigger.new);
        List<OrderItem> newList = Trigger.new;
        Map<Id, OrderItem> oldMap = (Map<Id, OrderItem>) Trigger.oldMap;
        Set<Id> orderIdSet = new Set<Id>();
        List<Professional_Service_Case_Creation__e> peList = new List<Professional_Service_Case_Creation__e>();
        
        for(OrderItem oi: newList){
            if(oi.SBCF_Serial_Number__c != null && oldMap.get(oi.Id).SBCF_Serial_Number__c == null && oi.SBCF_Order_Line_Type__c == 'New'){
                orderIdSet.add(oi.OrderId);
            }
        }
        
        System.debug('##orderIdSet:: ' + JSON.serialize(orderIdSet));
        
        if(!orderIdSet.isEmpty()){
            for(Id orderId: orderIdSet){
                Professional_Service_Case_Creation__e pe = new Professional_Service_Case_Creation__e();
                pe.Order_Id__c = orderId;
                peList.add(pe);                
            }
            
            List<Database.SaveResult> results = EventBus.publish(peList);
            
            // Inspect publishing result for each event
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' +
                                     err.getStatusCode() +
                                     ' - ' +
                                     err.getMessage());
                    }
                }       
            }              
        }              
    }	
    
}