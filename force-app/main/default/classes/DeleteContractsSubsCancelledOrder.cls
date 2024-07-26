/**
* @author Dilowar Hussain
* @date 2022-05-15
*
* @description 
* This Apex Class gets invoked by when an order gets Cancelled. The main porupose of this class is to 
* delete all related contracts and subscriptions of a Cancelled Order. 
*
* 
* This has been added as a part of SFDC-17002 (Related to SFDC-15817)
*/
public with sharing class DeleteContractsSubsCancelledOrder implements DynamicBusinessRuleAction{
     /***************************
     * Method Description: 
     * Deletes related Contracts and Subscriptions.
     * 
     * @Param: 
     * @return void
     */
    public static void processRecords(Map<Id,SObject> newRecordMap, 
                                        Map<Id,SObject> oldRecordMap,
                                        List <SObject> records, 
                                        String jsonParameter, 
                                        String triggerOrder, 
                                        String triggerContext) {
        LogModel log = LogModel.startLog('DeleteContractsSubsCancelledOrder', 'processRecords');
        List<Contract> lstContract = new List<Contract>();
        List<SBQQ__Subscription__c> lstSubscriptions = new List<SBQQ__Subscription__c>();
        List<SBQQ__Subscription__c> lstSubscriptionsDel = new List<SBQQ__Subscription__c>();
        List<Contract> lstContractDel = new List<Contract>();
        Set<ID> orderIds = new Set<ID>();
        Map<Id, Order> mapOrder = new Map<Id, Order>();
        try{
            if(triggerContext.contains('Update')){
                for(SObject rec: records){
                    Order ord = (Order)rec;
                    Order ord2 = oldRecordMap == null ? null : (Order)oldRecordMap.get(ord.Id);
                    if (ord2 == null){ord2 = new Order();}
                    //if(String.valueOf(ord.status).equals('Cancelled')){
                    if(ord.Is_Order_Cancelled__c == TRUE){
                        orderIds.add(ord.id);
                        mapOrder.put(ord.id, ord);
                    }
                }if(!mapOrder.isEmpty()){
                    lstContract = [select id, SBQQ__Order__c from contract where SBQQ__Order__c in :mapOrder.keySet()];
                    lstSubscriptions = [select id, Related_Order__c from SBQQ__Subscription__c where Related_Order__c in :mapOrder.keySet()];
                    if(!lstContract.isEmpty()){
                        for(Contract con : lstContract){
                            if(mapOrder.containsKey(con.SBQQ__Order__c)){
                                lstContractDel.add(con);
                            }
                        }
                        if(!lstContractDel.isEmpty()){
                            delete lstContractDel;
                        }
                    }
                    if(!lstSubscriptions.isEmpty()){
                        for(SBQQ__Subscription__c subs : lstSubscriptions){
                            if(mapOrder.containsKey(subs.Related_Order__c)){
                                lstSubscriptionsDel.add(subs);
                            }
                        }
                        if(!lstSubscriptionsDel.isEmpty()){
                            delete lstSubscriptionsDel;
                        }
                    }
                }
            }

        }Catch(Exception e){
            system.debug('Exception occurred at:' +e.getMessage());
            log.addExceptionLog(e);
        }
    }
}