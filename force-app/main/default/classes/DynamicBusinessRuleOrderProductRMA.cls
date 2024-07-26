/**
* @author Dilowar Hussain
* @date 2022/03/18
*
* @group DynamicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description This is part of SFDC-16681
*/
public with sharing class DynamicBusinessRuleOrderProductRMA implements DynamicBusinessRuleAction{
    /*******************************************************************************************************
    * @description 
    * @param trigger.new map
    * @return none, 
    * @example
    */
    public void processRecords(Map<Id,SObject> newRecordMap, 
                                                            Map<Id,SObject> oldRecordMap,
                                                            List <SObject> records, 
                                                            String jsonParameter, 
                                                            String triggerOrder, 
                                                            String triggerContext) {

       // LogModel log = LogModel.startLog('DynamicBusinessRuleAPIForJudge', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        List<OrderItem> lstOrderItems = new List<OrderItem>();
        Set<ID> parentIDs = new Set<ID>();
        Map<String, String> mapRMAIds = new Map<String, String>();
        try{
            //Write your code.
            if(triggerContext.contains('Update') || triggerContext.contains('Insert')){
                for(SObject rec: records){
                    OrderItem  orderIt01 = (OrderItem) rec;
                    OrderItem  orderIt02 = oldRecordMap == null ? null : (OrderItem)oldRecordMap.get(orderIt01.Id);
                    if (orderIt02 == null){orderIt02 = new OrderItem ();}
              //      System.debug('orderIt01 is:' +orderIt01);
              //      System.debug('orderIt02 is:' +orderIt02);
                    if(orderIt01.SBQQ__RequiredBy__c != NULL || (orderIt01.SBQQ__RequiredBy__c != NULL && orderIt01.SBQQ__RequiredBy__c != orderIt02.SBQQ__RequiredBy__c)){
                        parentIDs.add(orderIt01.SBQQ__RequiredBy__c);
                    }
                }
             //   System.debug('parentIDs is:' +parentIDs);
                if(!parentIDs.isEmpty()){
                    lstOrderItems = [select id, RMA_Id__c from OrderItem where id in :parentIDs];
                  //  System.debug('lstOrderItems is:' +lstOrderItems);
                    for(OrderItem ot: lstOrderItems){
                        mapRMAIds.put(String.valueOf(ot.id), String.valueOf(ot.RMA_Id__c));
                    }
               //     System.debug('mapRMAIds is:' +mapRMAIds);
                    if(!mapRMAIds.isEmpty()){
                        for(SObject rec: records){
                            OrderItem  orderIt03 = (OrderItem) rec;
                            if(orderIt03.SBQQ__RequiredBy__c != NULL){
                                orderIt03.RMA_Id__c = mapRMAIds.get(orderIt03.SBQQ__RequiredBy__c);
                            } 
                        }
                    }
                }
            }
        }Catch(Exception e){
            System.debug('Exception'+ e.getMessage()+'occurred at:' +e.getStackTraceString());
          //  log.addExceptionLog(e);
        }
    }
}