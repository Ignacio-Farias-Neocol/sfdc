/**
* @author Yuli, 
* @date 04/23/2020
*
* SFDC-11529: The Order Line's "Start Date" and "End Date" must match with what is calculated in Quote Line's "Discount Start Date" and "Discount End Date" respectively for any DiscMo Products.

Modified By             Date                     User Story

Keerthi Atluri          05/28/2020         SFDC-11920: The order Line's Subscription should be updated with the Quote Line's Upgraded Subscription for RMA Replaced Orders.
*/

public class DynamicBusinessRuleOrderItemBefore implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        if (triggerContext.contains('Insert')) {
            DiscMoOrderDates(records);
        }
        else if (triggerContext.contains('Update')) {
            updateSubscription(records);
        }

        if (triggerContext.contains('Insert') ||  (triggerContext.contains('Update'))){

            updateOrderLine(records,triggerContext);
        }
    }

    //SFDC-11529
    private static void DiscMoOrderDates(List<SObject> records) {
        List<OrderItem> candidates = new List<OrderItem>();
        Set<String> qlIds = new Set<String>();
        for (OrderItem oi : (List<OrderItem>)records) {
            if (!String.isEmpty(oi.SBQQ__QuoteLine__c)) {
                candidates.add(oi);
                qlIds.add(oi.SBQQ__QuoteLine__c);
            }
        }
        
        if (!candidates.isEmpty() && !qlIds.isEmpty()) {
            Map<String, SBQQ__QuoteLine__c> qls = new Map<String, SBQQ__QuoteLine__c>([Select ID, Discount_Start_Date__c, Discount_End_Date__c From SBQQ__QuoteLine__c Where ID in: qlIds and SBQQ__Product__r.ProductCode = 'DiscMo']);
            for (OrderItem oi : candidates) {
                if (oi.UnitPrice == null) {
                    oi.UnitPrice = 0;
                }
                if (qls.containsKey(oi.SBQQ__QuoteLine__c)) {
                    SBQQ__QuoteLine__c ql = qls.get(oi.SBQQ__QuoteLine__c);
                    oi.ServiceDate = ql.Discount_Start_Date__c;
                    oi.EndDate = ql.Discount_End_Date__c;
                }
            }
        }
    }
    
    //SFDC-11920
    
    
    //  SFDC -11920 Starts
    private static void updateSubscription(list<OrderItem> orderItem){
        set<Id> orderId = new set<Id>();
        set<Id> quoteId = new set<Id>();
        
        
    try{
        for (OrderItem ordItem: orderItem){
          //  system.debug('@@');
              if(ordItem.SBQQ__QuoteLine__c != null){
                  quoteId.add(ordItem.SBQQ__QuoteLine__c);
              }
              if(ordItem.OrderId != null){
                orderId.add(ordItem.OrderId);
             } 
          }
      //  system.debug('@@ Order ID:'+orderId+'  @@ Quote Id:'+quoteId);
        Map<Id,Order> orderLst = new Map<Id,Order>([select id, Has_RMA_Replace__c from order where id IN:orderId ]);
        Map<Id,SBQQ__QuoteLine__c> quoteLst = new Map<Id,SBQQ__QuoteLine__c>([select id, SBQQ__UpgradedSubscription__c from SBQQ__QuoteLine__c where id IN: quoteId ]);
        
          for(OrderItem ordItem : orderItem){
            //   system.debug('@@ orderItem Subscription '+ordItem.SBQQ__Subscription__c);
            //   system.debug('@@ Orders Has_RMA_Replace__c  : '+orderLst.get(ordItem.OrderId).Has_RMA_Replace__c);
            //   system.debug('@@ OrderItem Quote Line'+ordItem.SBQQ__QuoteLine__c);
            if(ordItem.SBQQ__Subscription__c == null && orderLst.get(ordItem.OrderId).Has_RMA_Replace__c == true &&
               ordItem.SBQQ__QuoteLine__c != null){
                   ordItem.SBQQ__Subscription__c = quoteLst.get(ordItem.SBQQ__QuoteLine__c).SBQQ__UpgradedSubscription__c;
               }
          }     
        } Catch (Exception e){
            system.debug('@@'+e);
        }

    }

//SFDC- 11920 End
    private static void updateOrderLine(List<SObject> records,String triggerContext ){


        // 1.   Set Product Code from QL
        // 2.   Set Product Description from QL
        // 3.   Set Extended Price
        // 4.    Set Serial Number from Quote Line
        // 5.   Set SKU # on Order Product
        // 6.   Set checkbox for Assets
        // 7.   Order Product Start Date (MSP)


        set<Id> quoteLineId = new set<Id>();
        set<Id> prodId = new set<Id>();
        set<Id> qlProdId = new set<Id>();
        set<Id> orderId=new set<Id>();
        set<Id> accId= new set<Id>();
        set<Id> qId= new set<Id>();
        Map<Id, Map<Id,Product2>> qlProdMap=new Map<Id, Map<Id,Product2>>();
        Map<Id, Map<Id,Account>> oAccMap=new Map<Id, Map<Id,Account>>();
        Map<Id, Map<Id,SBQQ__Quote__c>> oqMap=new Map<Id, Map<Id,SBQQ__Quote__c>>();
        
            for (OrderItem oItem: (List<OrderItem>)records){

                if(oItem.SBQQ__QuoteLine__c != null){
                  quoteLineId.add(oItem.SBQQ__QuoteLine__c);
                   
              }
              if(oItem.Product2Id != null){
                prodId.add(oItem.Product2Id);
              }

              if(oItem.orderId !=null){
                orderId.add(oItem.orderId);

              }
            }

            Map<Id,Order> oMap=new Map<Id,Order>([Select Id,SBQQ__Quote__c, AccountId,Quote_Business_Group__c,EffectiveDate,
                                              Status  , Sync_Order_Start_Date_MSP__c from Order where Id IN: orderId]);
            for(Id id : oMap.keyset()){

                accId.add(oMap.get(id).AccountId);
                qId.add(oMap.get(id).SBQQ__Quote__c);
            }

            Map<Id,Account> accMap= new  Map<Id,Account>([Select Id, MSP_First_Order__c from Account where Id in : accId]);

            Map<Id,SBQQ__Quote__c> qMap= new  Map<Id,SBQQ__Quote__c>([Select Id ,Business_Group__c,SBQQ__Type__c,Min_IR_Start_Date__c from SBQQ__Quote__c 
                                                                      where Id in : qId]);
        

            for( Order o : [Select Id , accountId ,SBQQ__Quote__c,Quote_Business_Group__c from  order where id in : oMap.keyset()
                            and accountId in : accId]){

                if(!oAccMap.containsKey(o.Id)) {
                    oAccMap.put(o.Id, new Map<Id,Account>());
                }

                oAccMap.get(o.Id).put(accMap.get(o.accountId).Id,accMap.get(o.accountId));

                if(!oqMap.containsKey(o.Id)) {
                    oqMap.put(o.Id, new Map<Id,SBQQ__Quote__c>());
                }
              
              if(o.SBQQ__Quote__c!=null && qMap!=null && !qMap.IsEmpty() && oqMap.containsKey(o.Id) && qMap.containskey(o.SBQQ__Quote__c)){
                oqMap.get(o.Id).put(qMap.get(o.SBQQ__Quote__c).Id,qMap.get(o.SBQQ__Quote__c));
              }
            }


            Map<Id,SBQQ__QuoteLine__c> qLMap =
             new Map<Id,SBQQ__QuoteLine__c>([select id,Document_Product_Code__c,Doc_Product_Description__c,Extended_Price__c,
             SBCF_Serial_Number__c,SKU__c ,SBQQ__Product__c,SBQQ__StartDate__c,SBQQ__EndDate__c,prod_subtype__c,SBQQ__EffectiveStartDate__c,SBCF_EffectiveEndDate_Calculated__c  
             from SBQQ__QuoteLine__c where id IN: quoteLineId ]);

             Map<Id,Product2> prodMap =
             new Map<Id,Product2>([select id,ProductCode from Product2 where id IN: prodId ]);     
             
             for(Id id : qLMap.keyset()){                

                qlProdId.add(qLMap.get(Id).SBQQ__Product__c);
             }

             Map<Id,Product2> pMap =
             new Map<Id,Product2>([select id,ProductCode,SBQQ__AssetConversion__c,SBQQ__SubscriptionPricing__c from Product2 
                                    where id IN: qlProdId ]);

            
            for(SBQQ__QuoteLine__c ql : [Select id,SBQQ__Product__c from SBQQ__QuoteLine__c where SBQQ__Product__c in: qlProdId 
                                             and Id in:qLMap.keyset()]){
                  
                if(!qlProdMap.containsKey(ql.Id)){

                    qlProdMap.put(ql.Id, new Map<Id,Product2>());                      

                  }

                if( pMap!=null && !pMap.IsEmpty() && qlProdMap.containsKey(ql.Id) && pMap.containskey(ql.SBQQ__Product__c)){
                     qlProdMap.get(ql.Id).put(pMap.get(ql.SBQQ__Product__c).Id,pMap.get(ql.SBQQ__Product__c));
                    }
                }

            

               
            for(OrderItem ordItem : (List<OrderItem>)records){

                if (triggerContext.contains('Insert')){

                  // 1

                    if( !qLMap.Isempty() && qLMap.containskey(ordItem.SBQQ__QuoteLine__c) ){

                        ordItem.Document_Product_Code__c= qLMap.get((ordItem.SBQQ__QuoteLine__c))==null ? null : 
                        qLMap.get((ordItem.SBQQ__QuoteLine__c)).Document_Product_Code__c;
    
                    }

                 // 2
                    if( !qLMap.Isempty() && qLMap.containskey(ordItem.SBQQ__QuoteLine__c) ){
                    
                        ordItem.Doc_Product_Description__c=qLMap.get(ordItem.SBQQ__QuoteLine__c).Doc_Product_Description__c==null ? null : 
                        qLMap.get((ordItem.SBQQ__QuoteLine__c)).Doc_Product_Description__c ;

                    }

                  // 4
                  
                    if(!qLMap.Isempty() && qLMap.containskey(ordItem.SBQQ__QuoteLine__c)){
                                        
                        ordItem.SBCF_Serial_Number__c=qLMap.get(ordItem.SBQQ__QuoteLine__c).SBCF_Serial_Number__c==null ? null : 
                        qLMap.get((ordItem.SBQQ__QuoteLine__c)).SBCF_Serial_Number__c ;                        
                    }


                 // 9

                    if (!oqMap.Isempty() && oqMap.containskey(ordItem.OrderId)) {
                        for(Id qoId: oqMap.get(ordItem.OrderId).keyset()){
                            //SFDC-20721: Start date will set with order product flow after CPQ trigger run
                            /*if(oqMap.get(ordItem.OrderId).get(qoId).Business_Group__c =='Core' && 
                            ordItem.ServiceDate != Date.today() &&
                            oqMap.get(ordItem.OrderId).get(qoId).SBQQ__Type__c =='Quote' ){

                                ordItem.ServiceDate=Date.today();
                            }*/
                            //SFDC-19909: Populate backdated start date and end date on IR from Quote line to OrderItem
                            //SFDC-20105: backdating IR then updates dates on other subscription
                            if(oqMap.get(ordItem.OrderId).get(qoId).Business_Group__c =='Core' && oqMap.get(ordItem.OrderId).get(qoId).SBQQ__Type__c =='Amendment' && qLMap.get(ordItem.SBQQ__QuoteLine__c).SBQQ__EffectiveStartDate__c!=null && oqMap.get(ordItem.OrderId).get(qoId).Min_IR_Start_Date__c !=null){
                                ordItem.ServiceDate=qLMap.get(ordItem.SBQQ__QuoteLine__c).SBQQ__EffectiveStartDate__c;
                                ordItem.EndDate=qLMap.get(ordItem.SBQQ__QuoteLine__c).SBCF_EffectiveEndDate_Calculated__c;
                            }
                        }
                    }                  
                }

                // 3
                if( !qLMap.Isempty() && qLMap.containskey(ordItem.SBQQ__QuoteLine__c) ){                   
                    
                    ordItem.Extended_Price__c=qLMap.get(ordItem.SBQQ__QuoteLine__c).Extended_Price__c==null ? null : 
                    qLMap.get((ordItem.SBQQ__QuoteLine__c)).Extended_Price__c ;
                }                

                // 5 
                if(ordItem.SKU__c==null && prodMap.containskey(ordItem.Product2Id)){

                    ordItem.SKU__c=prodMap.get((ordItem.Product2Id)).ProductCode==null ? null :
                    prodMap.get((ordItem.Product2Id)).ProductCode;              
                }

                // 6
                if(!qlProdMap.IsEmpty() && qlProdMap.containskey(ordItem.SBQQ__QuoteLine__c)){
                 for(Id pId: qlProdMap.get(ordItem.SBQQ__QuoteLine__c).keyset()){
                    if(qlProdMap.get((ordItem.SBQQ__QuoteLine__c)).get(pId).SBQQ__AssetConversion__c=='One per unit' &&
                    qlProdMap.get(ordItem.SBQQ__QuoteLine__c).get(pId).SBQQ__SubscriptionPricing__c==null &&
                    qlProdMap.get(ordItem.SBQQ__QuoteLine__c).get(pId).ProductCode.indexOf('SHIP')==-1) {
                    
                        ordItem.Is_Asset_Checkbox__c=true;
                    }                  

                    // 7
                    if(qlProdMap.get(ordItem.SBQQ__QuoteLine__c).get(pId).SBQQ__SubscriptionPricing__c!=null){

                        ordItem.Is_Subscription_Checkbox__c=true;
                    }
                  }       
                }

                 // 8

                if(!oAccMap.Isempty() && oAccMap.containskey(ordItem.OrderId)){
                    for(Id aId: oAccMap.get(ordItem.OrderId).keyset()){

                        if(oMap.get(ordItem.OrderId).Quote_Business_Group__c =='Barracuda MSP' &&
                        ordItem.ServiceDate != oMap.get(ordItem.OrderId).EffectiveDate && 
                        oMap.get(ordItem.OrderId).Status !='Placed' &&
                        oMap.get(ordItem.OrderId).Sync_Order_Start_Date_MSP__c &&
                        oMap.get(ordItem.OrderId).Id==oAccMap.get(ordItem.OrderId).get(aId).MSP_First_Order__c){                  
                        
                            ordItem.ServiceDate= oMap.get(ordItem.OrderId).EffectiveDate;
                        }
                    }
                }            
            }
        }
}