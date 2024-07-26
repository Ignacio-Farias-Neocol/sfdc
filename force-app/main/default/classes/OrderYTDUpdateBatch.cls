global class OrderYTDUpdateBatch implements Database.Batchable<sObject>{
    global Database.QueryLocator start(Database.BatchableContext bc){ 
        String query = 'Select Id,Opportunity.Reseller__c,Opportunity.Distributor__c,Status,TotalAmount,Quote_Business_Group__c,SBCF_Order_Type__c FROM Order WHERE TotalAmount != NULL AND ActivatedDate >=  2020-03-01T00:00:00Z AND Status = \'Placed\'  ';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc,List<Order> orderList){
        Set<Id> acctIdSet = new Set<Id>();
        Map<Id,Order> idToOrderMap = new Map<Id,Order>();
        Map<Id,Account> idToAcctMap = new Map<Id,Account>();
        Map<Id,Account> acctToUpdate = new Map<Id,Account>();
        for(Order eachUpdatedOrder : orderList){
            if(eachUpdatedOrder.Opportunity.Reseller__c != null){
                idToOrderMap.put(eachUpdatedOrder.id,eachUpdatedOrder);
                acctIdSet.add(eachUpdatedOrder.Opportunity.Reseller__c);
            }
            if(eachUpdatedOrder.Opportunity.Distributor__c != null){
                idToOrderMap.put(eachUpdatedOrder.id,eachUpdatedOrder);
                acctIdSet.add(eachUpdatedOrder.Opportunity.Distributor__c);
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
                acctToUpdate.put(resellerAcct.id,resellerAcct); 
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
                acctToUpdate.put(distiAcct.id,distiAcct);
            }  
        }
        
        if(acctToUpdate.size() > 0){
            UPDATE acctToUpdate.values();
        }
    }
    global void finish(Database.BatchableContext bc){
        
    }
}