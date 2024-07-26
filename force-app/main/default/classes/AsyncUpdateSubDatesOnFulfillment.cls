public with sharing class AsyncUpdateSubDatesOnFulfillment implements Queueable{

    private static List<String> orderLineTypes = new List<String>{'New'};
    private static List<String> businessGroups = new List<String>{'Core'};
    private static List<String> quoteTypesToExclude = new List<String>{'Amendment','Renewal'};

    private map<String,Date> fulfillmentDateBySerial = new map<String,Date>();
    private map<String,String> Serialnumbers = new map<String,String>();
    private map<String,List<SBQQ__Subscription__c>> subsBySerial = new map<String,List<SBQQ__Subscription__c>>();
    Private Set<Id> Amendedcontract = new Set<Id>();
    Private Set<Id> ContractIds = new Set<Id>();

    private List<String> subIds = new List<String>();

    public AsyncUpdateSubDatesOnFulfillment(List<String> sIds) {
        subIds = sIds;
    }

    public void execute(QueueableContext context){
        processSyncDates(subIds);
    }

    public void processSyncDates(List<String> subscriptionIds){
        LogModel log = LogModel.startLog('AsyncUpdateSubDatesOnFulfillment', 'processSyncDates');
        try{
                if(subscriptionIds != null && subscriptionIds.size() > 0){
                    for(SBQQ__Subscription__c sub : [Select Id, Name, SBQQ__OrderProduct__r.SBCF_Order_Line_Type__c, Business_Group__c, 
                                                    SBQQ__SubscriptionStartDate__c, SBQQ__SubscriptionEndDate__c, SBQQ__Contract__r.ContractTerm,
                                                    Renewed_By_Subscription__c,SBCF_Serial_Number__c,SBQQ__Contract__c,
                                                    (Select Id From RenewedSubscriptions__r LIMIT 1),
                                                    (Select Id From SBQQ__Revisions__r LIMIT 1),
                                                    (Select Id, Subscription__c, Serial__c, Serial__r.Fulfillment_Date__c,Serial__r.Serial_Number__c from Assigned_Serials__r ORDER BY CreatedDate DESC LIMIT 1)
                                                    From SBQQ__Subscription__c
                                                    Where 
                                                    SBQQ__OrderProduct__r.SBCF_Order_Line_Type__c IN:  orderLineTypes 
                                                    AND SBQQ__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c NOT IN: quoteTypesToExclude 
                                                    AND Business_Group__c IN: businessGroups
                                                    AND Id IN: subscriptionIds
                                                    ]){
                        
                        ContractIds.add(sub.SBQQ__Contract__c);
                        
                        //Only consider subs that dont have anything in the Renewed subs related list
                        system.debug('----sub renewed Subscriptions---' + sub.RenewedSubscriptions__r);
                        if((sub.RenewedSubscriptions__r == null || sub.RenewedSubscriptions__r.size() == 0) && sub.Renewed_By_Subscription__c==null &&
                            (sub.SBQQ__Revisions__r == null || sub.SBQQ__Revisions__r.size() == 0)){

                            if(sub.Assigned_Serials__r != null && sub.Assigned_Serials__r.size() > 0 && sub.Assigned_Serials__r[0].Serial__c != null && sub.Assigned_Serials__r[0].Serial__r.Fulfillment_Date__c != null){
                                
                                if(!fulfillmentDateBySerial.containsKey(sub.Assigned_Serials__r[0].Serial__c)){
                                    fulfillmentDateBySerial.put(sub.Assigned_Serials__r[0].Serial__c,sub.Assigned_Serials__r[0].Serial__r.Fulfillment_Date__c);
                                }
                                
                                if(!Serialnumbers.containsKey(sub.Assigned_Serials__r[0].Serial__c)){
                                    Serialnumbers.put(sub.Assigned_Serials__r[0].Serial__c,sub.Assigned_Serials__r[0].Serial__r.Serial_Number__c);
                                }

                                if(subsBySerial.containsKey(sub.Assigned_Serials__r[0].Serial__c)){
                                    subsBySerial.get(sub.Assigned_Serials__r[0].Serial__c).add(sub);
                                }
                                else{
                                    subsBySerial.put(sub.Assigned_Serials__r[0].Serial__c,new list<SBQQ__Subscription__c>{sub});
                                }
                            }
                        }
                    }   
                    
                    syncSubDatesWithFulfillmentDate();
                }
        }
        catch(Exception e){
            log.addExceptionLog(e);
            log.endLog();
        }

    }

    private void syncSubDatesWithFulfillmentDate(){

        Set<SBQQ__Subscription__c> subsToUpdate = new Set<SBQQ__Subscription__c>();
        
        if(ContractIds!=null && ContractIds.size()>0){
            for(Contract ocon : [Select Id,(Select Id from SBQQ__AmendmentOpportunities__r limit 1) from Contract where Id IN :ContractIds]){
                If(ocon.SBQQ__AmendmentOpportunities__r!=null && ocon.SBQQ__AmendmentOpportunities__r.size()>0){
                   Amendedcontract.add(ocon.Id);
                }
                
            }
         }

        if(!subsBySerial.isEmpty()){

            for(String serialId : subsBySerial.keySet()){

                Date fulfillmentDate = fulfillmentDateBySerial.get(serialId);

                for(SBQQ__Subscription__c sub : subsBySerial.get(serialId)){
                    if(Amendedcontract.size() == 0 || (Amendedcontract.size()>0 && !Amendedcontract.contains(sub.SBQQ__Contract__c))){
                        Integer contractTerm = sub.SBQQ__Contract__r.ContractTerm;
                        if(contractTerm != null){
    
                            Date startDate = fulfillmentDate;
                            Date endDate = fulfillmentDate.addMonths(contractTerm);
                            endDate = endDate.addDays(-1);
    
                            if(sub.SBQQ__SubscriptionStartDate__c != startDate || sub.SBQQ__SubscriptionEndDate__c != endDate){
                                sub.SBQQ__SubscriptionStartDate__c = startDate;
                                sub.SBQQ__SubscriptionEndDate__c = endDate;
                                if(string.isBlank(sub.SBCF_Serial_Number__c) || sub.SBCF_Serial_Number__c==null || sub.SBCF_Serial_Number__c==''){
                                    sub.SBCF_Serial_Number__c = Serialnumbers.get(serialId);
                                }
                                subsToUpdate.add(sub);
                            }
                        }
                    }
                }
            }
        }
        
        if(!subsToUpdate.isEmpty()){
            Database.SaveResult[] updateResult = Database.update(new list<SBQQ__Subscription__c>(subsToUpdate),false);
            for(Database.SaveResult sr : updateResult){
                if(!sr.isSuccess()){
                    //Log error
                    system.debug('---DML EXCEPTION----');
                }
            }
        }
    }
}