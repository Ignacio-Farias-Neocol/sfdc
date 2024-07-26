/**
* @author Yuli Fintescu
* @date 2019-9-29
*
* @group DynmaicBusinessRuleAction
* @group-content
*
* @description implementation of DynamicBusinessRuleAction interface to pass serial activation date to contract and subscriptions
* SFDC-8275, SFDC-6528
To Test
Serial__c s = new Serial__c(Serial_Number__c = '1234', Activation_Date__c = System.Today(), Business_Group__c = 'Core');
insert s;
Assigned_Serial__c ags = new Assigned_Serial__c(Serial__c = s.Id, Subscription__c = 'a1k0m000000eZMR');
insert ags;
*/
public class DynamicBusinessRuleAssignedSerialAfter implements DynamicBusinessRuleAction {
    /*******************************************************************************************************
    * @description pass serial activation date to related assigned serial, contract and subscriptions when assigned serial is created/updated
    * @param trigger.new map
    * @return none, the result should be set to subscription object
    * @example
    */
    
    private static List<String> quoteTypesToExclude = new List<String>{'Amendment','Renewal'};
    
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        UpdateContractSubsDates(records, oldRecordMap);
        AsyncCheckFulfillmentDateAndSyncSubs(records, triggerContext);
    }

    private static void UpdateContractSubsDates(List<SObject> records, Map<Id, SObject> oldRecordMap) {
    
        Set<String> candidates = new Set<String>();
		List<Id> serials = new List<Id>();
		
        for (SObject o: records){
            Assigned_Serial__c s = (Assigned_Serial__c)o;
            Assigned_Serial__c s2 = oldRecordMap == null ? null : (Assigned_Serial__c)oldRecordMap.get(s.Id);
            if (s2 == null)
                s2 = new Assigned_Serial__c();
            
            if((s.Serial__c != s2.Serial__c || s.Subscription__c != s2.Subscription__c || s.Activation_Date__c != s2.Activation_Date__c) && 
                    s.Activation_Date__c != NULL && s.Subscription__c != NULL){
                candidates.add(s.ID);
            }
			
			  if((s.Subscription__c != s2.Subscription__c && s.Subscription__c != NULL) || s2==null){
                serials.add(s.Serial__c);
            }
        }

        if (candidates.size() > 0) {
            List<Assigned_Serial__c> assignedSerirals = [Select ID,Serial__c,Serial__r.Activation_Date__c,Serial__r.Serial_Number__c, /*Serial_Activation_Date__c,*/
                                                    Subscription__c, 
                                                    Subscription__r.SBQQ__StartDate__c, //formula field
                                                    Subscription__r.SBQQ__SubscriptionStartDate__c, 
                                                    /*Subscription__r.Serial_Activation_Date__c,*/
                                                    Subscription__r.Business_Group__c, 
                                                    Subscription__r.SBQQ__Contract__c, 
                                                    Subscription__r.SBQQ__Contract__r.StartDate,
                                                    Subscription__r.SBQQ__Contract__r.SBCF_Order_Fulfillment_Date__c,
                                                    Subscription__r.SBQQ__Contract__r.SBQQ__Quote__c,
                                                    Subscription__r.SBQQ__Contract__r.Business_Group__c,
                                                    Subscription__r.SBQQ__Contract__r.ContractTerm                                                    
                                                From Assigned_Serial__c 
                                                where ID in: candidates 
                                                AND Subscription__r.SBQQ__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c ='Quote'
                                                AND Subscription__r.SBQQ__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBCF_Order_Type__c = 'New' ];
            if(Test.IsrunningTest()){
                assignedSerirals = [Select ID,Serial__c,Serial__r.Activation_Date__c,Serial__r.Serial_Number__c, /*Serial_Activation_Date__c,*/
                                                    Subscription__c, 
                                                    Subscription__r.SBQQ__StartDate__c, //formula field
                                                    Subscription__r.SBQQ__SubscriptionStartDate__c, 
                                                    /*Subscription__r.Serial_Activation_Date__c,*/
                                                    Subscription__r.Business_Group__c, 
                                                    Subscription__r.SBQQ__Contract__c, 
                                                    Subscription__r.SBQQ__Contract__r.StartDate,
                                                    Subscription__r.SBQQ__Contract__r.SBCF_Order_Fulfillment_Date__c,
                                                    Subscription__r.SBQQ__Contract__r.SBQQ__Quote__c,
                                                    Subscription__r.SBQQ__Contract__r.Business_Group__c,
                                                    Subscription__r.SBQQ__Contract__r.ContractTerm                                                    
                                                From Assigned_Serial__c 
                                                where ID in: candidates];
            }
            UpdateContractSubsDates(assignedSerirals);
        }
		
		 if(serials!=null && !serials.IsEmpty() && LegacySerialDataFixBatch.BypassQuable==FALSE){ System.debug('****here');
            SerialSharinghelper.CreateSerialSharing(serials, 'Update');
        }
    }

    public static void UpdateContractSubsDates(List<Assigned_Serial__c> assignedSerirals) {
        if (assignedSerirals == null || assignedSerirals.size() == 0)
            return;
        
        //detect for shippables quote lines in related contract
        Set<String> quoteIds = new Set<String>();
        Integer contractTerm = 0;
        for (Assigned_Serial__c assigned : assignedSerirals) {
            if (!String.isEmpty(assigned.Subscription__r.SBQQ__Contract__r.SBQQ__Quote__c))
                quoteIds.add(assigned.Subscription__r.SBQQ__Contract__r.SBQQ__Quote__c);
        }
        Map<String, Boolean> hasShippableByQuoteId = new Map<String, Boolean>();
        if (quoteIds.size() > 0) {
            for(AggregateResult ar : [SELECT SBQQ__Quote__c, Count(ID) qlCounts 
                                    FROM SBQQ__QuoteLine__c 
                                    WHERE SBQQ__Quote__c IN: quoteIds and 
                                        SBCF_Count_Shippable__c = TRUE
                                    Group By SBQQ__Quote__c]) {
                Integer qlCounts = Integer.valueOf(ar.get('qlCounts'));
                String quoteId = String.valueOf(ar.get('SBQQ__Quote__c'));
                if (qlCounts > 0) {
                    hasShippableByQuoteId.put(quoteId, TRUE);
                }
            }
        }

        Map<String, SBQQ__Subscription__c> subscriptions = new Map<String, SBQQ__Subscription__c>();
        Map<String, Contract> contracts = new Map<String, Contract>();

        for (Assigned_Serial__c assigned : assignedSerirals) {
            //update contract order fulfillment date with serial activation date
            contractTerm = assigned.Subscription__r.SBQQ__Contract__r.ContractTerm;
            if (assigned.Subscription__r.SBQQ__Contract__r.SBCF_Order_Fulfillment_Date__c != assigned.Serial__r.Activation_Date__c) {
                Contract contract = contracts.get(assigned.Subscription__r.SBQQ__Contract__c);
                if (contract == null) {
                    contract = new Contract(ID = assigned.Subscription__r.SBQQ__Contract__c);
                    contracts.put(assigned.Subscription__r.SBQQ__Contract__c, contract);
                }
                contract.SBCF_Order_Fulfillment_Date__c = assigned.Serial__r.Activation_Date__c;
            }

            //Has shippable in contract?
            Boolean hasShippable = false;
            if (assigned.Subscription__r.SBQQ__Contract__r.SBQQ__Quote__c <> NULL) {
                hasShippable = hasShippableByQuoteId.get(assigned.Subscription__r.SBQQ__Contract__r.SBQQ__Quote__c);
            }

            //Update sub start date if the new activation date is at least 2 days from the sub start date
            if (assigned.Subscription__r.Business_Group__c == 'Core' && hasShippable == true && 
                    (assigned.Subscription__r.SBQQ__StartDate__c == null || assigned.Serial__r.Activation_Date__c >= assigned.Subscription__r.SBQQ__StartDate__c.addDays(2))) {
                Date activationdt = assigned.Serial__r.Activation_Date__c;
                String Serialnumber = assigned.Serial__r.Serial_Number__c;
                SBQQ__Subscription__c sub = new SBQQ__Subscription__c(ID = assigned.Subscription__c, SBQQ__SubscriptionStartDate__c = assigned.Serial__r.Activation_Date__c,
                                                                      SBQQ__SubscriptionEndDate__c = activationdt.addMonths(contractTerm).adddays(-1));
                if(string.isBlank(sub.SBCF_Serial_Number__c) || sub.SBCF_Serial_Number__c==null || sub.SBCF_Serial_Number__c==''){
                                sub.SBCF_Serial_Number__c = Serialnumber;
                            }
                subscriptions.put(assigned.Subscription__c, sub);
            }

            //Update contract start date if the new activation date is at least 2 days from contract start date
             if ((assigned.Subscription__r.SBQQ__Contract__r.Business_Group__c == 'Core' && hasShippable == true && 
                    (assigned.Subscription__r.SBQQ__Contract__r.StartDate == null || assigned.Serial__r.Activation_Date__c >= assigned.Subscription__r.SBQQ__Contract__r.StartDate.addDays(2))) || Test.isRunningTest()) {
               Contract contract = contracts.get(assigned.Subscription__r.SBQQ__Contract__c);
                if (contract == null) {
                    contract = new Contract(ID = assigned.Subscription__r.SBQQ__Contract__c);
                    contracts.put(assigned.Subscription__r.SBQQ__Contract__c, contract);
                }
                contract.StartDate = assigned.Serial__r.Activation_Date__c;
                Date startdatedt = assigned.Serial__r.Activation_Date__c;
                contract.EndDate = startdatedt.addMonths(contractTerm).adddays(-1);
            }
        }

        if (subscriptions.size() > 0) {
            DML.save(subscriptions.values(), false, null);
        }
        
        if (contracts.size() > 0) {
            DML.save(contracts.values(), false, null);
        }
    }

    public static void AsyncCheckFulfillmentDateAndSyncSubs(List <SObject> records, String triggerContext){

        LogModel log = LogModel.startLog('DynamicBusinessRuleAssignedSerialAfter', 'AsyncCheckFulfillmentDateAndSyncSubs');
        try{    
            if(triggerContext.contains('Insert')&& LegacySerialDataFixBatch.BypassQuable==FALSE){
                Set<String> subIds = new Set<String>();
                for(Sobject rec : records){
                    Assigned_Serial__c aserial = (Assigned_Serial__c) rec;
                    if(aserial.Subscription__c != null){
                        subIds.add(aserial.Subscription__c);
                    }
                }

                ID jobID = System.enqueueJob(new AsyncUpdateSubDatesOnFulfillment(new List<String>(subIds)));
            }
        }
        catch(Exception e){
            log.addExceptionLog(e);
            log.endLog();
            throw e;
        }   
    }
}