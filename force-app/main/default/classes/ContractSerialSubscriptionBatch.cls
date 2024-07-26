/**
 * Created by iyeung on 7/15/19.
 *
 *
 * @description
 * https://bugs.cudaops.com/browse/SFDC-1849
 * https://success.salesforce.com/ideaview?id=08730000000BqRXAA0
 *
 *  *  There are four ways to run this match
 *  1. run this batch immediately from dev console (Database.executeBatch): ContractSerialSubscriptionBatch.executeBatch();
 *  2. run this batch x mins from dev console (System.scheduleBatch):   ContractSerialSubscriptionBatch.scheduleBatch(null, null);
 *  3. run this batch x mins from now, using scheduler (System.schedule) : ContractSerialSubscriptionBatchSch.runOnce(minuteAfter);
 *  4. run this batch every weekly/monthly at specifc time using UI (but the code will limit to only once): ContractSerialSubscriptionBatchSch
 *
 *  For Cuda, only option 1 and 4 is setup
 *
 *  @Date 2019/7/15
 *  @group Batchable
 *  SFDC-10845: If customer has pool license need a checkbox to show SN# is a pool
 *  SFDC-10890: Business Group needs to be populated on Serial and Assigned Serial records. Adding additional filter prevent batch job run against all serials in the system after the mass update.
 *  SFDC-10845: Mark contract and serial IsPool flag
 */
global class ContractSerialSubscriptionBatch implements Database.Batchable<SObject>, Database.Stateful {

//    private List<string> messages = new List<String>();
//    protected DateTime startTime = DateTime.Now();
//    protected string env = System.URL.getSalesforceBaseUrl().getHost();
//    protected integer successCount = 0;
//    protected integer failureCount = 0;
    public Integer defaultBatchSize = null;
    public Integer defaultHour = 48;  // 48; // cover last 48 hours. in case there is a lapse
    private String additionalFitlers = ''; 
    protected string batchName;
    protected Database.BatchableContext batchableContext;

// note in order to retain the same SOQL statement between run, Database.Stateful interface is used.
// only instance member variables retain their values between transactions
// Static member variables don’t retain their values and are reset between transactions.
// https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_batch_interface.htm
    public String SOQL = 'select id, Serial_Number__c, createdDate, Has_Pool_License__c from Serial__c where  LastModifiedDate > ';


    public ContractSerialSubscriptionBatch() {
        List<Batch_Job_System_Property__mdt> props = [Select ID, DeveloperName, MasterLabel, Value__c, Business_Group__c From Batch_Job_System_Property__mdt];

        for (Batch_Job_System_Property__mdt prop : props) {
            if ((prop.DeveloperName == 'ContractSerialSubBatch_HoursOffset' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                try {
                    defaultHour = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
            
            if ((prop.DeveloperName == 'ContractSerialSubBatch_FilterCriteria' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                additionalFitlers = prop.Value__c;
            }
            
            if ((prop.DeveloperName == 'ContractSerialSubBatch_BatchSize' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                try {
                    defaultBatchSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
        }

        Datetime yesterday = DateTime.now().addHours( -(defaultHour));
        String dateTimeFormat = yesterday.formatGMT('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        SOQL = SOQL + dateTimeFormat;

        if ( Test.isRunningTest()){
            additionalFitlers = 'Name <> NULL';
        }

        if (!String.isEmpty(additionalFitlers)) {
            SOQL = SOQL + ' and ' + additionalFitlers;
        }    
        
        System.debug('~~#@~~ SOQL at constructor ' + SOQL);

    }


    global Database.QueryLocator start(Database.BatchableContext BC) {
        batchableContext = BC;
        batchName = 'ContractSerialSubscriptionBatch';
        System.debug('~~#@~~ SOQL at start ' + SOQL);
        return Database.getQueryLocator(SOQL);
    }


    global void execute(Database.BatchableContext BC, List<Serial__c> serials){


        try {

            System.debug('~~#@~~ serials ' + serials);

            Map<Id, Map<String, List<ContractSubscription>>> contractSubscriptionMap = new Map<Id, Map<String, List <ContractSubscription>>>();
            //SFDC-10845: collect rootid to get asset's Appliance Line Type info. if Appliance Line Type = 'Hardware Only(Pool)', mark contract and serial IsPool flag
            Map<Id, Set<String>> rootIdsByContract = new Map<Id, Set<String>>();
            Map<Id, Set<String>> rootIdsBySerial = new Map<Id, Set<String>>();
            Set<String> rootIds = new Set<String>();

            Set <Id> serialIds = new Set <Id>();
            for (Serial__c o : serials) {
                serialIds.add(o.id);
            }

            // find all the subscriptions that are associated the serials


            Set <Id> contractIds = new Set<Id>();
            for (Assigned_Serial__c assignedSerial : [
                    select id, Subscription__c, Subscription__r.SBQQ__Contract__c, Asset__c, Serial__c
                    from Assigned_Serial__c
                    where Serial__c in:serialIds
            ]) {
                if (assignedSerial.Subscription__r.SBQQ__Contract__c != null) {
                    contractIds.add(assignedSerial.Subscription__r.SBQQ__Contract__c);
                }
            }

            System.debug('~~#@~~ contractIds ' + contractIds);


            // now, find all the active asigned serials for all those contracts
            for (Assigned_Serial__c assignedSerial : [
                    select Subscription__c, Subscription__r.SBQQ__Product__r.ProductCode,
                            Subscription__r.SBQQ__ProductName__c, Subscription__r.SBQQ__Contract__c, Appliance_Line_Type__c, Asset__c,
                            Asset__r.ProductCode, Asset__r.Product2.Name, Base_SKU__c, Contract__c, Date_Of_Replacement__c,
                            End_User_Account__c, External_ID__c, Id, IsDeleted, Name, Parent_Subscription__c,Parent_Subscription__r.SBQQ__Product__r.ProductCode,
                            Subscription__r.SBQQ__Product__r.CPQ_Product_Family__c,
                            Serial__c, Serial__r.Base_product_sku__c,Serial_Number__c, Status__c, Subscription_End_Date__c, Subscription_Name__c,
                            Subscription_Start_Date__c, Unique_Contract_ID__c, Subscription__r.SBQQ__RootId__c
                    from Assigned_Serial__c
                    where status__c = 'Active'
                    and Subscription__r.SBQQ__Contract__c in :contractIds
            ]) {

                System.debug('~~#@~~ assignedSerial ' + assignedSerial);

                Map<String, List<ContractSubscription>> csMap;

                if (contractSubscriptionMap.containsKey(assignedSerial.Subscription__r.SBQQ__Contract__c)) {
                    csMap = contractSubscriptionMap.get(assignedSerial.Subscription__r.SBQQ__Contract__c);
                } else {
                    csMap = new Map<String, List<ContractSubscription>>();
                    contractSubscriptionMap.put(assignedSerial.Subscription__r.SBQQ__Contract__c, csMap);
                }




                List<ContractSubscription> csSubs;
                // assume the key being the product family assoicated with the subscription
                String serialGroupKey = String.isBlank(assignedSerial.Subscription__r.SBQQ__Product__r.CPQ_Product_Family__c) ? 'UNKNOWN' : assignedSerial.Subscription__r.SBQQ__Product__r.CPQ_Product_Family__c;
                if (csMap.containsKey(serialGroupKey)) {
                    csSubs = csMap.get(serialGroupKey);
                } else {
                    csSubs = new List<ContractSubscription>();
                    csMap.put(serialGroupKey, csSubs);
                }



                ContractSubscription cs = new ContractSubscription();
                cs.assetId = assignedSerial.Asset__c;
                cs.contractId = assignedSerial.Contract__c;
                cs.subscriptionProductName = assignedSerial.Subscription__r.SBQQ__ProductName__c;
                cs.subscriptionProductCode = assignedSerial.Subscription__r.SBQQ__Product__r.ProductCode;
                cs.subscriptionStartDate = assignedSerial.Subscription_Start_Date__c;
                cs.subscriptionEndDate = assignedSerial.Subscription_End_Date__c;
                cs.assetProductCode = assignedSerial.Asset__r.ProductCode;
                cs.assetProductName = assignedSerial.Asset__r.Product2.Name;
                cs.serialBaseSKU = assignedSerial.Serial__r.Base_product_sku__c;
                cs.serialNumber = assignedSerial.Serial_Number__c;

                csSubs.add(cs);

                System.debug('~~#@~~ csSubs ' + csSubs);
                System.debug('~~#@~~ csMap ' + csMap);

                //SFDC-10845: collect rootids
                if (assignedSerial.Subscription__r.SBQQ__RootId__c != null && assignedSerial.Subscription__r.SBQQ__RootId__c.startsWith('02i')) {
                    //all root ids
                    rootIds.add(assignedSerial.Subscription__r.SBQQ__RootId__c);

                    //root ids by contract
                    Set<String> rootIds1 = rootIdsByContract.get(assignedSerial.Subscription__r.SBQQ__Contract__c);
                    if (rootIds1 == null) {
                        rootIds1 = new Set<String>();
                        rootIdsByContract.put(assignedSerial.Subscription__r.SBQQ__Contract__c, rootIds1);
                    }
                    rootIds1.add(assignedSerial.Subscription__r.SBQQ__RootId__c);
                    
                    //root ids by serial
                    Set<String> rootIds2 = rootIdsBySerial.get(assignedSerial.Serial__c);
                    if (rootIds2 == null) {
                        rootIds2 = new Set<String>();
                        rootIdsBySerial.put(assignedSerial.Serial__c, rootIds2);
                    }
                    rootIds2.add(assignedSerial.Subscription__r.SBQQ__RootId__c);
                }
            }

            //SFDC-10845 collect Hardware only (pool) assets
            Map<Id, Asset> assets = new Map<Id, Asset>();
            if (!rootIds.isEmpty()) {
                assets = new Map<Id, Asset>([Select ID, Appliance_Line_Type__c From Asset Where Id in: rootIds and Appliance_Line_Type__c = 'Hardware only (pool)']);
            }

            // finally update the contract with the
            List <Contract> updatedContracts = new List <Contract>();
            for (Id contractId : contractSubscriptionMap.keySet()) {
                Contract c = new Contract();
                c.Id = contractId;
                updatedContracts.add(c);

                String serialSummary = '';

                Map<String, List<ContractSubscription>> csMap = contractSubscriptionMap.get(contractId);

                System.debug('~~#@~~ csMap ' + csMap);


                if (csMap != null && csMap.size() > 0) {
                    for (String productKey : csMap.keySet()) {
                        serialSummary += productKey + ' - ';

                        List<ContractSubscription> csSubs = csMap.get(productKey);
                        Set <String> serialSet = new Set <String>();
                        for (ContractSubscription cs : csSubs) {
                            serialSet.add(cs.serialNumber);
                        }    

                        List <String> serialList = new List <String>(serialSet);


                        if (serialList != null && serialList.size() > 0) {
                            FOr (Integer i = 0; i < serialList.size() - 1; i++) {
                                serialSummary += serialList[i] + ',';
                            }    
                            serialSummary += serialList[serialList.size() - 1];
                        }    

                        serialSummary += '; ';

                    }    
                }    

                c.Serial_summary__c = serialSummary;

                //SFDC-10845 contracts to update
                c.Has_Pool_License__c = false;
                Set<String> rootIds1 = rootIdsByContract.get(contractId);
                if (rootIds1 != null) {
                    for (String rootId : rootIds1) {
                        if (assets.containsKey(rootId)) {
                            c.Has_Pool_License__c = true;
                            break;
                        }
                    }
                }
            }

            //SFDC-10845 serials to update
            List <Serial__c> updatedSerials = new List <Serial__c>();
            for (Serial__c o : serials) {
                System.Debug('*** o ' + o.Id);
                Set<String> rootIds2 = rootIdsBySerial.get(o.Id);
                Boolean hasPool = false;

                if (rootIds2 != null) {
                    for (String rootId : rootIds2) {
                        if (assets.containsKey(rootId)) {
                            hasPool = true;
                            break;
                        }
                    }
                }
                System.Debug('*** o.Has_Pool_License__c ' + o.Has_Pool_License__c + ', hasPool ' + hasPool);
                //checking if Has_Pool_License__c needs update is important, otherwise the serial will keep coming back
                if (o.Has_Pool_License__c != hasPool) {
                    o.Has_Pool_License__c = hasPool;
                    updatedSerials.add(o);
                }
            }
            
            if (updatedContracts.size() > 0) {
                DML.save(updatedContracts);
            }

            if (updatedSerials.size() > 0) {
                DML.save(updatedSerials);
            }
        } catch (Exception e){
            System.debug('~~~~~ exception: ' + e);
        }


    }

    global void finish(Database.BatchableContext BC){
    }

    public class ContractSubscription {
        public String contractId;
        public String subscriptionProductName;
        public String subscriptionProductCode;
        public Date subscriptionStartDate;
        public Date subscriptionEndDate;
        public String assetId;
        public String assetProductCode;
        public String assetProductName;
        public String serialBaseSKU;
        public String serialNumber;

    }


}