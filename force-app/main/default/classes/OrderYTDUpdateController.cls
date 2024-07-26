public class OrderYTDUpdateController implements DynamicBusinessRuleAction{
    
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        updateBookings(records, oldRecordMap,triggerContext);
    }
    
    public static void updateBookings(List<sObject> orderList,Map<Id,sObject> oldOrderMap,String context){
        Set<Id> acctIdSet = new Set<Id>();
        Map<Id,Order> idToOrderMap = new Map<Id,Order>();
        List<Order> orderIdsToSubtract = new List<Order>();
        Map<Id,Account> idToAcctMap = new Map<Id,Account>();
        List<Account> acctToUpdate = new List<Account>();
        List<Order> orderListNew = [Select Id,Opportunity.Reseller__c,Opportunity.Distributor__c,Status,TotalAmount,Quote_Business_Group__c,SBCF_Order_Type__c FROM Order WHERE ID IN: (List<Order>)orderList ];
        for(Order eachUpdatedOrder : orderListNew){
            Order order1 = (Order)oldOrderMap.get(eachUpdatedOrder.id) ; 
            if((eachUpdatedOrder.Status == 'Placed' && order1.Status != 'Placed') || (eachUpdatedOrder.TotalAmount != order1.TotalAmount) ){
                if(eachUpdatedOrder.Opportunity.Reseller__c != null){
                    idToOrderMap.put(eachUpdatedOrder.id,eachUpdatedOrder);
                    acctIdSet.add(eachUpdatedOrder.Opportunity.Reseller__c);
                }
                if(eachUpdatedOrder.Opportunity.Distributor__c != null){
                    idToOrderMap.put(eachUpdatedOrder.id,eachUpdatedOrder);
                    acctIdSet.add(eachUpdatedOrder.Opportunity.Distributor__c);
                }
            }
            else if(eachUpdatedOrder.Status != 'Placed' && order1.Status == 'Placed'){
                orderIdsToSubtract.add(eachUpdatedOrder);
            }
        }
        for(Account eachAcct : [SELECT Id ,Total_Bookings_YTD__c,Total_Core_Bookings_YTD__c,Core_Renewal_Bookings_YTD__c,Core_New_Business_Bookings_YTD__c FROM Account WHERE Id IN: acctIdSet]){
            idToAcctMap.put(eachAcct.Id,eachAcct);
        }
        for(Id eachUpdatedOrder : idToOrderMap.keySet()){
            Order eachOrder = idToOrderMap.get(eachUpdatedOrder);
            if(eachOrder.Opportunity.Reseller__c != null){
                Account resellerAcct = idToAcctMap.get(eachOrder.Opportunity.Reseller__c);
                resellerAcct.Total_Bookings_YTD__c = resellerAcct.Total_Bookings_YTD__c == null ? eachOrder.TotalAmount : resellerAcct.Total_Bookings_YTD__c + eachOrder.TotalAmount;
                if(eachOrder.Quote_Business_Group__c == 'Barracuda'){
                    resellerAcct.Total_Core_Bookings_YTD__c = resellerAcct.Total_Core_Bookings_YTD__c == null ? eachOrder.TotalAmount : resellerAcct.Total_Core_Bookings_YTD__c + eachOrder.TotalAmount;
                    if(eachOrder.SBCF_Order_Type__c == 'Renewal' || eachOrder.SBCF_Order_Type__c == 'Renewal - Return'){
                        resellerAcct.Core_Renewal_Bookings_YTD__c = resellerAcct.Core_Renewal_Bookings_YTD__c == null ? eachOrder.TotalAmount : resellerAcct.Core_Renewal_Bookings_YTD__c + eachOrder.TotalAmount;
                    }
                    if(eachOrder.SBCF_Order_Type__c == 'New' || eachOrder.SBCF_Order_Type__c == 'New - Return'){
                        resellerAcct.Core_New_Business_Bookings_YTD__c = resellerAcct.Core_New_Business_Bookings_YTD__c == null ? eachOrder.TotalAmount : resellerAcct.Core_New_Business_Bookings_YTD__c + eachOrder.TotalAmount;
                    }
                }
                acctToUpdate.add(resellerAcct); 
            }
            if(eachOrder.Opportunity.Distributor__c != null){
                Account distiAcct = idToAcctMap.get(eachOrder.Opportunity.Distributor__c);
                distiAcct.Total_Bookings_YTD__c = distiAcct.Total_Bookings_YTD__c == null ? eachOrder.TotalAmount : distiAcct.Total_Bookings_YTD__c + eachOrder.TotalAmount;
                if(eachOrder.Quote_Business_Group__c == 'Barracuda'){
                    distiAcct.Total_Core_Bookings_YTD__c = distiAcct.Total_Core_Bookings_YTD__c == null ? eachOrder.TotalAmount : distiAcct.Total_Core_Bookings_YTD__c + eachOrder.TotalAmount;
                    if(eachOrder.SBCF_Order_Type__c == 'Renewal' || eachOrder.SBCF_Order_Type__c == 'Renewal - Return'){
                        distiAcct.Core_Renewal_Bookings_YTD__c = distiAcct.Core_Renewal_Bookings_YTD__c == null ? eachOrder.TotalAmount : distiAcct.Core_Renewal_Bookings_YTD__c + eachOrder.TotalAmount;
                    }
                    if(eachOrder.SBCF_Order_Type__c == 'New' || eachOrder.SBCF_Order_Type__c == 'New - Return'){
                        distiAcct.Core_New_Business_Bookings_YTD__c = distiAcct.Core_New_Business_Bookings_YTD__c == null ? eachOrder.TotalAmount : distiAcct.Core_New_Business_Bookings_YTD__c + eachOrder.TotalAmount;
                    }
                }
                acctToUpdate.add(distiAcct);
            }
            
            
        }
        
        if(!acctToUpdate.isEmpty()){
            UPDATE acctToUpdate;
        }
        //updateAccts(resellerIdSet,distiIdSet);
        if(orderIdsToSubtract.size() > 0){
            updateAcctsToSubtract(orderIdsToSubtract);
        }
    }
    
    
    public static void updateAcctsToSubtract(List<Order> orderListToSubtract){
        Map<Id,Account> mapAcctToSave = new Map<Id,Account>(); 
        Map<Id,Account> idToAcctMap = new Map<Id,Account>();
        Set<Id> acctIdSet = new Set<Id>();
        for(Order eachO : orderListToSubtract){
            if(eachO.Opportunity.Reseller__c != null){
                acctIdSet.add(eachO.Opportunity.Reseller__c);    
            }
            if(eachO.Opportunity.Distributor__c != null){
                acctIdSet.add(eachO.Opportunity.Distributor__c); 
            }
        }
        for(Account eachAcct : [SELECT Id ,Total_Bookings_YTD__c,Total_Core_Bookings_YTD__c,Core_Renewal_Bookings_YTD__c,Core_New_Business_Bookings_YTD__c FROM Account WHERE Id IN: acctIdSet]){
            idToAcctMap.put(eachAcct.Id,eachAcct);
        }
        for(Order eachOrderWithSubtractCondn : orderListToSubtract){
            if(eachOrderWithSubtractCondn.Opportunity.Reseller__c != null){
                Account acct1 = idToAcctMap.get(eachOrderWithSubtractCondn.Opportunity.Reseller__c);
                if(acct1.Total_Bookings_YTD__c != null){
                    acct1.Total_Bookings_YTD__c = acct1.Total_Bookings_YTD__c - eachOrderWithSubtractCondn.TotalAmount;
                }
                if(eachOrderWithSubtractCondn.Quote_Business_Group__c == 'Barracuda'){
                    if(acct1.Total_Core_Bookings_YTD__c != null){
                        acct1.Total_Core_Bookings_YTD__c = acct1.Total_Core_Bookings_YTD__c - eachOrderWithSubtractCondn.TotalAmount;
                    }
                    if((eachOrderWithSubtractCondn.SBCF_Order_Type__c == 'Renewal' || eachOrderWithSubtractCondn.SBCF_Order_Type__c == 'Renewal - Return') && acct1.Core_Renewal_Bookings_YTD__c != null ){
                        acct1.Core_Renewal_Bookings_YTD__c = acct1.Core_Renewal_Bookings_YTD__c  -  eachOrderWithSubtractCondn.TotalAmount;
                    }
                    if((eachOrderWithSubtractCondn.SBCF_Order_Type__c == 'New' || eachOrderWithSubtractCondn.SBCF_Order_Type__c == 'New - Return') && acct1.Core_New_Business_Bookings_YTD__c != null){
                        acct1.Core_New_Business_Bookings_YTD__c = acct1.Core_New_Business_Bookings_YTD__c  -  eachOrderWithSubtractCondn.TotalAmount;
                    }
                }
                mapAcctToSave.put(acct1.id,acct1);
            }
            if(eachOrderWithSubtractCondn.Opportunity.Distributor__c != null){
                Account acct1 = idToAcctMap.get(eachOrderWithSubtractCondn.Opportunity.Distributor__c);
                if(acct1.Total_Bookings_YTD__c != null){
                    acct1.Total_Bookings_YTD__c = acct1.Total_Bookings_YTD__c - eachOrderWithSubtractCondn.TotalAmount;
                }
                if(eachOrderWithSubtractCondn.Quote_Business_Group__c == 'Barracuda'){
                    if(acct1.Total_Core_Bookings_YTD__c != null){
                        acct1.Total_Core_Bookings_YTD__c = acct1.Total_Core_Bookings_YTD__c - eachOrderWithSubtractCondn.TotalAmount;
                    }
                    if((eachOrderWithSubtractCondn.SBCF_Order_Type__c == 'Renewal' || eachOrderWithSubtractCondn.SBCF_Order_Type__c == 'Renewal - Return') && acct1.Core_Renewal_Bookings_YTD__c != null){
                        acct1.Core_Renewal_Bookings_YTD__c = acct1.Core_Renewal_Bookings_YTD__c  -  eachOrderWithSubtractCondn.TotalAmount;
                    }
                    if((eachOrderWithSubtractCondn.SBCF_Order_Type__c == 'New' || eachOrderWithSubtractCondn.SBCF_Order_Type__c == 'New - Return') && acct1.Core_New_Business_Bookings_YTD__c != null){
                        acct1.Core_New_Business_Bookings_YTD__c = acct1.Core_New_Business_Bookings_YTD__c  -  eachOrderWithSubtractCondn.TotalAmount;
                    }
                }
                mapAcctToSave.put(acct1.id,acct1);
            }
        }
        UPDATE mapAcctToSave.values();
    }
    
    
    /*public static void saveMethod(Map<Id,Account> acctMapToSave){
        if(acctMapToSave.values().size() > 0){
            try{
                UPDATE acctMapToSave.values();
            }
            catch(Exception ex){
                throw(ex);
            }
        }
    }*/
    
}