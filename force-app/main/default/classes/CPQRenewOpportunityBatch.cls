/**
 * Created by iyeung on 1/2/19.
 *
 *  @Date 2019/1/2
 *  @group Batchable
 *
 *  Yuli FIntescu   11/21/2019  Redo
 */
global with sharing  class CPQRenewOpportunityBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Integer defaultBatchSize = 1;
    private Integer defaultLoadSize = null;
    public String ownerName = 'Legacy Load';
    //public String accID = '0017d00001PSUc0AAH';
    public String SOQL = 'select Id, ' + 
                            'Status, ' + 
                            'SBQQ__ExpirationDate__c, ' + 
                            'Auto_Renew__c, ' + 
                            'SBQQ__RenewalQuoted__c, ' + 
                            'Demo_Opp__c, ' + 
                            'SBQQ__RenewalForecast__c, ' +  
                            'EndDate, ' + 
                            'Lead_Source__c, ' + 
                            'SBCF_EndDate__c, ' + 
                            'Has_Contract_Error__c, ' + 
                            'Contract_Error_Check__c, ' + 
                            'Business_Group__c, ' + 
                            'SBQQ__RenewalOpportunity__c, ' + 
                            /**
                             * SFDC-19803: POC changes: START
                             */
                            'SBQQ__Order__r.OrderNumber,' +
                            'CreatedBy.Name,' +
                            'Owner.Name,' +
                            '(select ID from SBQQ__Subscriptions__r)'+
                            /**
                             * SFDC-19803: POC changes: END
                             */
                            'from Contract ' + 
                            'where Has_Contract_Error__c = FALSE and ' + 
                            'SBQQ__RenewalQuoted__c = false and ' + 
                            'Status = \'Activated\' and ' + 
                            'Auto_Renew__c = true and ' + 
                            'Exclude_from_Batch__c != true and ' + 
                            'Demo_Opp__c != true and ' + 
                            /***
                             * SFDC-17285: Added extra condition as All_Subs_RMA__c  = false: START
                             * */
                            'SBQQ__RenewalForecast__c != true AND ' +
                            'All_Subs_RMA__c  = false';
                            //'All_Subs_RMA__c  = false AND ' +
                            //'accountId = :accID';
                            /***
                             * SFDC-17285: Added extra condition as All_Subs_RMA__c  = false: END
                             * */
                                                                                

    public CPQRenewOpportunityBatch() {

        Integer coreMonthsFuture   = 0;
        Integer coreMonthsPast   = 0;

        List<Batch_Job_System_Property__mdt> props = [Select ID, DeveloperName, MasterLabel, Value__c, Business_Group__c From Batch_Job_System_Property__mdt];

        for (Batch_Job_System_Property__mdt prop : props) {
            if ((prop.DeveloperName == 'Renewal_Forecast_Load_Size' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                try {
                    defaultLoadSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
            
            if ((prop.DeveloperName == 'Renewal_Forecast_BatchJob_Size' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                try {
                    defaultBatchSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
 
            // SFDC-16021 
            if ((prop.DeveloperName == 'RenewalOpptyBatch_CoreFutureMonths' && String.isNotBlank(prop.Value__c))|| (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                System.debug('Core Future Months:' + prop.Value__c);
                try {
                    coreMonthsFuture = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {
                    system.debug('Exception setting CoreFutureMonths: ' + e.getMessage());
                }
            }

            if ((prop.DeveloperName == 'RenewalOpptyBatch_CorePastMonths' && String.isNotBlank(prop.Value__c))|| (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                System.debug('Core Past Months:' + prop.Value__c);
                try {
                    coreMonthsPast = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {
                    system.debug('Exception setting CorePastMonths: ' + e.getMessage());
                }
            }
        }

        Date coreFutureDate   = Date.today().addMonths(coreMonthsFuture);
        Date corePastDate   = Date.today().addMonths(-coreMonthsPast);

        System.debug('Core Future Date for Oppty Renewal: ' + coreFutureDate);

        SOQL=SOQL + ' AND (' +
        /**
        * SFDC-19803: POC changes: START
        */
        //'(Business_Group__c = \'Core\')' +
       //'(Business_Group__c = \'Core\' AND SBCF_EndDate__c >'+ String.valueOf(corePastDate) + ' AND SBCF_EndDate__c <' + String.valueOf(coreFutureDate) + ')' + 
       '(Business_Group__c = \'Core\' AND SBCF_EndDate__c >'+ String.valueOf(Date.today()) + ')' + 
       ' OR (Business_Group__c = \'MSP\' )' + 
       ' OR (Business_Group__c = \'Sonian\' ))' +
       ' AND (createdBy.name != :ownerName AND Owner.Name != :ownerName)' +
        'order by SBQQ__Order__r.OrderNumber desc';
        /**
        * SFDC-19803: POC changes: END
        */

        // if (defaultLoadSize != null)
        //     SOQL += ' LIMIT ' + String.valueOf(defaultLoadSize);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.Debug('*** defaultBatchSize ' + defaultBatchSize);
        System.Debug('*** SOQL ' + SOQL);
        return Database.getQueryLocator(SOQL);
    }

    global void execute(Database.BatchableContext BC, List<Contract> contractList){

        Map<ID, Contract> errors = new Map<ID, Contract>();        
        List<Contract> contractsToUpdate = new List<Contract>();

        System.Debug('*** Total Scope Size ::' + contractList.size());
        /**
        * SFDC-19803: POC changes: START
        */
        List<Contract> lstContract = new List<Contract>();
        for(Contract cont : contractList){
            System.Debug('Contract Ordernumber is:' + cont.SBQQ__Order__r.OrderNumber);
           if(cont.SBQQ__Subscriptions__r.size()>0){
              lstContract.add(cont);
           }
        }
        System.Debug('lstContract is:' + lstContract);
        System.Debug('*New contract list Size :' + lstContract.size());
        //SFDC-19803 POC: Added this extra condition to stop execution for contracts without subscriptions.
        if(!lstContract.isEmpty()){
            // SFDC-14041
            Map<Id,List<SBQQ__Subscription__c>> conSubEnddateMap = new Map<Id,List<SBQQ__Subscription__c>>();
            Map<Id,List<SBQQ__Subscription__c>> conSubRenewedMap = new Map<Id,List<SBQQ__Subscription__c>>();
            Map<Id,List<Opportunity>> conSubRenOpsMap = new Map<Id,List<Opportunity>>();

            List<SBQQ__Subscription__c> subsEnddate = [Select Id,SBQQ__Contract__c, Name from SBQQ__Subscription__c where 
                                                    SBQQ__EndDate__c>Today and  SBQQ__Contract__c in :lstContract];

            List<SBQQ__Subscription__c> subsRenewed = [Select Id, SBQQ__Contract__c,Name from SBQQ__Subscription__c where
                                                    Renewed_By_Subscription__c =null and  SBQQ__Contract__c in :lstContract];

            List<Opportunity> subsRenOps = [Select Id, SBQQ__RenewedContract__c,Name from Opportunity  where stagename='Closed Won'
                                                    and SBQQ__RenewedContract__c in :lstContract];


            for( SBQQ__Subscription__c s :subsEnddate)
            {
                List<SBQQ__Subscription__c> sublst = conSubEnddateMap.get(s.SBQQ__Contract__c);
                if(sublst == null)
                sublst = new List<SBQQ__Subscription__c>();
                sublst.add(s);
                conSubEnddateMap.put(s.SBQQ__Contract__c,sublst);
            
            }

            for( SBQQ__Subscription__c s :subsRenewed)
            {
                List<SBQQ__Subscription__c> sublst = conSubRenewedMap.get(s.SBQQ__Contract__c);
                if(sublst == null)
                sublst = new List<SBQQ__Subscription__c>();
                sublst.add(s);
                conSubRenewedMap.put(s.SBQQ__Contract__c,sublst);
            
            }

            for( Opportunity o :subsRenOps)
            {
                List<Opportunity> oplst = conSubRenOpsMap.get(o.SBQQ__RenewedContract__c);
                if(oplst == null)
                oplst = new List<Opportunity>();
                oplst.add(o);
                conSubRenOpsMap.put(o.SBQQ__RenewedContract__c,oplst);
            
            }

        
            //SFDC-14041
            //SFDC-19803 POC: Replaced contractList with lstContract
            for (Contract c: lstContract){
                System.Debug('*** process contract ' + c.Id);
                
                // SFDC-14041
                
                if(c.Business_Group__c =='Core' ) {
                
                if(c.SBQQ__RenewalOpportunity__c !=null)
                continue;
                        
                if(conSubEnddateMap.get(c.id)==null ) 
                    continue;
            
                if(conSubRenewedMap.get(c.id)==null ) 
                    continue;            

                if(conSubRenOpsMap.get(c.id)!=null )
                    continue;
            }
                // SFDC-14041
                
                if (c.Lead_Source__c == null)
                    c.Lead_Source__c = 'Renewal';

                c.Contract_Error_Check__c = null;
                c.Has_Contract_Error__c = FALSE;

                c.SBQQ__RenewalForecast__c = true;

                contractsToUpdate.add(c);
            }
            System.Debug('***  contractsToUpdate ' + contractsToUpdate);

            Database.DMLOptions dml = new Database.DMLOptions();
            dml.allowFieldTruncation = true;

            Database.SaveResult[] srList = Database.update(contractsToUpdate, false);
            
            for (Integer i = 0; i < srList.size(); i++) {
                Contract o = new Contract(ID = contractsToUpdate[i].Id);

                Database.SaveResult sr = srList[i];
                if (!sr.isSuccess()) {
                    String errorMsg = '';
                    for(Database.Error err : sr.getErrors()) {
                        errorMsg = errorMsg + err.getMessage() + '\n';
                    }

                    System.Debug('*** error contract ' + o.Id + ', errorMsg ' + errorMsg);
                    o.setOptions(dml);
                    o.Contract_Error_Check__c = 'RenewalOpptyBatchJob Error: ' + errorMsg;
                    o.Has_Contract_Error__c = TRUE;
                    errors.put(o.Id, o);
                } else {
                    System.Debug('*** success contract ' + o.Id);
                }
            }

            if (errors.size() > 0)
                Database.update(errors.values(), false);
            /***
             * Make the system to wait till next 5 secondsto 
             * get the related DML operations completed.
             * 
             * Added as a part of SFDC-19803
            **/
           if(!Test.isRunningTest()) { 
                PageReference exeDelay = Page.CPQRnwBtDelayExecution;
                exeDelay.getParameters().put('CPQRnwBtDelayExecution','15000');
                exeDelay.getContent();
            }
        }
    }

    global void finish(Database.BatchableContext BC){}
}