/**
 * Created by Dilowar Hussain on 29/06/2011.
 *  @Date 2022/06/29
 *
 *  Description:
 *  This class has been a replica of the process builder "Subscription Process", contains all conditions as that of the 
 *  Process Builder. 
 *  The class gets invoked before insertion /updating of a subscription record. 
 *  
 *  Added as a part of SFDC-17447 and SFDC-17406
 */
public with sharing class SubscriptionProcessBuilderClass implements DynamicBusinessRuleAction {

    /*******************************************************************************************************
    * @description: Process Method
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

        LogModel log = LogModel.startLog('SubscriptionProcessBuilderClass', 'processRecords', LogModel.LOG_CATEGORY_APEX);
        Set<ID> AccountIDs = new Set<ID>();
        Set<ID> orderProdIDs = new Set<ID>();
        Set<ID> contractIDs = new Set<ID>();
        Map<ID, OrderItem> MapOrderItem = new Map<ID, OrderItem>();
        Map<ID, Contract> mapContracts = new Map<ID, Contract>();
        Map<String, String> mapAccount = new Map<String, String>();
        /**
        * Added as a part of SFDC-19862: START
        */
        Set<ID> quoteLineIDs = new Set<ID>();
        Map<Id, SBQQ__QuoteLine__c> mapQuoteLines = new Map<Id, SBQQ__QuoteLine__c>();
        /**
        * Added as a part of SFDC-19862: END
        */
        try{
            if(triggerContext.contains('Update') || triggerContext.contains('Insert')){
                for(SObject rec: records){
                    SBQQ__Subscription__c subs01 = (SBQQ__Subscription__c) rec;
                    SBQQ__Subscription__c subs02 = oldRecordMap == null ? null : (SBQQ__Subscription__c)oldRecordMap.get(subs01.Id);
                    if (subs02 == null){subs02 = new SBQQ__Subscription__c();}
                    //1st condition: Set Renewal Method For RBM to Custom : START
                    if(subs01.RBM_Price__c != NULL || (subs02 != NULL && subs01.RBM_Price__c != NULL && subs01.RBM_Price__c != subs02.RBM_Price__c)){
                        //Update Renewal Method and Price
                        subs01.SBQQ__PricingMethod__c = 'Custom';
                        subs01.SBQQ__RenewalPrice__c = subs01.RBM_Price__c;

                    }
                    //1st condition: Set Renewal Method For RBM to Custom : END
                    //2nd condition: Set Renewal Method To List for NonRBM Core
                    // START
                    //System.debug('Account is:' +subs01.SBQQ__Account__c);
                    if(subs01.SBQQ__Account__c != NULL || (subs02 != NULL && subs01.SBQQ__Account__c != NULL && subs01.SBQQ__Account__c != subs02.SBQQ__Account__c)){
                        AccountIDs.add(subs01.SBQQ__Account__c);
                    }
                    if(subs01.SBQQ__OrderProduct__c != NULL || (subs02 != NULL && subs01.SBQQ__OrderProduct__c != NULL && subs01.SBQQ__OrderProduct__c != subs02.SBQQ__OrderProduct__c)){
                        orderProdIDs.add(subs01.SBQQ__OrderProduct__c);
                    }
                    if(subs01.SBQQ__Contract__c != NULL || (subs02 != NULL && subs01.SBQQ__Contract__c != NULL && subs01.SBQQ__Contract__c != subs02.SBQQ__Contract__c)){
                        contractIDs.add(subs01.SBQQ__Contract__c);
                    }
                    /**
                     * Added as a part of SFDC-19862: START
                     */
                    if(subs01.SBQQ__QuoteLine__c != NULL || (subs02 != NULL && subs01.SBQQ__QuoteLine__c != NULL && subs01.SBQQ__QuoteLine__c != subs02.SBQQ__QuoteLine__c)){
                        quoteLineIDs.add(subs01.SBQQ__QuoteLine__c);
                    }
                    /**
                     * Added as a part of SFDC-19862: END
                     */
                }
                //2nd condition : Extension: START 
                if(!AccountIDs.isEmpty()){
                    List<Account> lstAcc = [Select id, Business_Group__c from Account where id in :AccountIDs];
                    for(Account acc : lstAcc){
                        mapAccount.put(acc.id, acc.Business_Group__c);
                    }
                    if(!mapAccount.isEmpty()){
                        for(SObject rec: records){
                            SBQQ__Subscription__c subs03 = (SBQQ__Subscription__c) rec;
                            SBQQ__Subscription__c subs04 = oldRecordMap == null ? null : (SBQQ__Subscription__c)oldRecordMap.get(subs03.Id);
                            if (subs04 == null){subs04 = new SBQQ__Subscription__c();}
                            
                            if((subs03.RBM_Price__c == NULL || (subs04 != NULL && subs03.RBM_Price__c == NULL && subs03.RBM_Price__c != subs04.RBM_Price__c))
                            && (subs03.SBQQ__Account__c != NULL && mapAccount.containsKey(subs03.SBQQ__Account__c) && mapAccount.get(subs03.SBQQ__Account__c) == 'Core')){
                                subs03.SBQQ__PricingMethod__c = 'List';
                            }
                        }
                    }
                }
                /**
                * Added as a part of SFDC-19862: START
                */
                if(!quoteLineIDs.isEmpty()){
                    for(SBQQ__QuoteLine__c qL : [select id, Reseller__c from SBQQ__QuoteLine__c where id in :quoteLineIDs]){
                        mapQuoteLines.put(qL.id, qL);
                    }if(!mapQuoteLines.isEmpty()){
                        for(SObject rec: records){
                            SBQQ__Subscription__c subs07 = (SBQQ__Subscription__c) rec;
                            SBQQ__Subscription__c subs08 = oldRecordMap == null ? null : (SBQQ__Subscription__c)oldRecordMap.get(subs07.Id);
                            if (subs08 == null){subs08 = new SBQQ__Subscription__c();}
                            subs07.Reseller__c = mapQuoteLines.get(subs07.SBQQ__QuoteLine__c).Reseller__c != NULL ? mapQuoteLines.get(subs07.SBQQ__QuoteLine__c).Reseller__c : '';
                        }
                    }
                }
                /**
                * Added as a part of SFDC-19862: END
                */
                //2nd condition : Extension: END
                if(!orderProdIDs.isEmpty()){
                    List<OrderItem> lstOrderItems = [select id, OrderId, Order.OrderNumber, Order.PoNumber from OrderItem where id in :orderProdIDs];
                    for(OrderItem ordIt : lstOrderItems){
                        MapOrderItem.put(ordIt.id, ordIt);
                    }
                    if(!contractIDs.isEmpty()){
                        List<Contract> lstContract = [select id, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Type__c from Contract where id in :contractIDs];
                        for(Contract con : lstContract){
                            mapContracts.put(con.id, con);
                        }
                    }
                    if(!MapOrderItem.isEmpty()){
                        for(SObject rec: records){
                            SBQQ__Subscription__c subs05 = (SBQQ__Subscription__c) rec;
                            SBQQ__Subscription__c subs06 = oldRecordMap == null ? null : (SBQQ__Subscription__c)oldRecordMap.get(subs05.Id);
                            if(subs06 == null){subs06 = new SBQQ__Subscription__c();}
                            //Added as a part of SFDC-19009: START 
                            subs05.Original_Order_Number__c = NULL;
                            //Added as a part of SFDC-19009: END
                
                            if(subs05.SBQQ__OrderProduct__c != NULL || (subs06 != NULL && subs05.SBQQ__OrderProduct__c != NULL && subs05.SBQQ__OrderProduct__c != subs06.SBQQ__OrderProduct__c)){
                                subs05.Last_Purchase_Order__c = MapOrderItem.get(subs05.SBQQ__OrderProduct__c).Order.PoNumber != NULL ? MapOrderItem.get(subs05.SBQQ__OrderProduct__c).Order.PoNumber : '';
                                subs05.Related_Order__c	 = MapOrderItem.get(subs05.SBQQ__OrderProduct__c).OrderId != NULL ? MapOrderItem.get(subs05.SBQQ__OrderProduct__c).OrderId : NULL;
                                if(subs05.SBQQ__RequiredById__c != NULL && String.valueOf(subs05.SBQQ__RequiredById__c).startsWithIgnoreCase('02i')){
                                    subs05.Required_By_Asset__c	 = subs05.SBQQ__RequiredById__c;
                                }
                                /*else{
                                    subs05.Required_By_Asset__c	 = NULL;
                                }*/
                                if(subs05.SBQQ__Contract__c != NULL && mapContracts.containsKey(subs05.SBQQ__Contract__c) && mapContracts.get(subs05.SBQQ__Contract__c).SBQQ__Quote__c != NULL){
                                    if((subs05.Original_Order_Number__c == NULL || (subs06 != NULL && subs05.Original_Order_Number__c == NULL && subs05.Original_Order_Number__c != subs06.Original_Order_Number__c))
                                        || mapContracts.get(subs05.SBQQ__Contract__c).SBQQ__Quote__r.SBQQ__Type__c == 'Renewal'){
                                            
                                            subs05.Original_OrderItem_Id__c	 = MapOrderItem.get(subs05.SBQQ__OrderProduct__c).Id != NULL ? MapOrderItem.get(subs05.SBQQ__OrderProduct__c).Id : '';
                                            //system.debug('Get Original Order Item Id:' +subs05.Original_OrderItem_Id__c);
                                            subs05.Original_Order_Id__c	 = MapOrderItem.get(subs05.SBQQ__OrderProduct__c).OrderId != NULL ? MapOrderItem.get(subs05.SBQQ__OrderProduct__c).OrderId : '';
                                            //system.debug('Get Original Order Id:' +subs05.Original_Order_Id__c);
                                            subs05.Original_Order_Number__c	 = MapOrderItem.get(subs05.SBQQ__OrderProduct__c).Order.OrderNumber != NULL ? MapOrderItem.get(subs05.SBQQ__OrderProduct__c).Order.OrderNumber : '';
                                            //system.debug('Get Original Order Number:' +subs05.Original_Order_Number__c);
                                    }
                                } 
                            }
                        }
                    }
                } 
            }

        }Catch(Exception e){
            System.debug('Exception'+ e.getMessage()+'occurred at:' +e.getStackTraceString());
            log.addExceptionLog(e);
        }
    }
    
}