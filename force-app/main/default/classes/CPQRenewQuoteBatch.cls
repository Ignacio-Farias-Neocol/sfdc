/**
 * Created by iyeung on 1/2/19.
 *
 *  @Date 2019/1/2
 *  @group Batchable
 *  Modified on 10/30/2019 for SFDC 7270. Updated query conditions.
 *  Yuli FIntescu   11/21/2019  Redo
 *  Modified on 11/02/2020 for SFDC 13214. Using Custom Metadata to set the number of days in future.
 */
global with sharing  class CPQRenewQuoteBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Integer defaultBatchSize = 1;
    private Integer defaultLoadSize = null;

    //SFDC-13214Default days for figuring out future date
    private final Integer CORE_FUTURE_DAYS   = 90;
    private final Integer MSP_FUTURE_DAYS    = 2;
    private final Integer SONIAN_FUTURE_DAYS = 2;

    //SFDC-7270 Commenting out the following query string and adding a new query string to include Business Group filtering
    //public String SOQL = 'select Id, Status, SBQQ__ExpirationDate__c, Auto_Renew__c, SBQQ__RenewalQuoted__c, Demo_Opp__c, SBQQ__RenewalForecast__c, EndDate, SBCF_EndDate__c from Contract where SBQQ__RenewalQuoted__c = false and Status = \'Activated\' and Auto_Renew__c = true and Exclude_from_Batch__c != true and Demo_Opp__c != true and SBQQ__RenewalQuoted__c != true';
    public String queryString = 'SELECT Id, ' + 
                                    'Status, ' + 
                                    'SBQQ__ExpirationDate__c, ' + 
                                    'Auto_Renew__c, ' + 
                                    'SBQQ__RenewalQuoted__c, ' + 
                                    'Demo_Opp__c, ' + 
                                    'SBQQ__RenewalForecast__c, ' + 
                                    'EndDate, ' + 
                                    'SBCF_EndDate__c, ' + 
                                    'Has_Contract_Error__c, ' + 
                                    'Contract_Error_Check__c, ' + 
                                    'Business_Group__c, ' + 
                                    'SBQQ__RenewalOpportunity__c ' + 
                                'FROM Contract ' + 
                                'WHERE Has_Contract_Error__c = FALSE' + 
                                    ' AND SBQQ__RenewalQuoted__c = FALSE' + 
                                    ' AND Status = \'Activated\'' + 
                                    ' AND Auto_Renew__c = TRUE' + 
                                    ' AND Exclude_from_Batch__c = FALSE' + 
                                    /***
                                     * SFDC-17285: Added extra condition as All_Subs_RMA__c  = false: START
                                     * */
                                    ' AND Demo_Opp__c = false and ' +
                                    'All_Subs_RMA__c  = false';
                                    /***
                                     * SFDC-17285: Added extra condition as All_Subs_RMA__c  = false: START
                                     * */
                                    

    public CPQRenewQuoteBatch() {
        
        List<Batch_Job_System_Property__mdt> props = [Select ID, DeveloperName, MasterLabel, Value__c, Business_Group__c From Batch_Job_System_Property__mdt];

        //SFDC-13214 Days to add
        Integer coreDaysToAdd   = CORE_FUTURE_DAYS;
        Integer mspDaysToAdd    = MSP_FUTURE_DAYS;
        Integer sonianDaysToAdd = SONIAN_FUTURE_DAYS;
        Integer coreMonthsPast   = 0;

        //Loop through custom metadata to set batch job properties
        for (Batch_Job_System_Property__mdt prop : props) {
            if ((prop.DeveloperName == 'Renewal_Quote_Load_Size' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                try {
                    defaultLoadSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
            
            if ((prop.DeveloperName == 'Renewal_Quote_BatchJob_Size' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                try {
                    defaultBatchSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }

            //SFDC-13214 Set future dates for query
            //CORE - Set the future date
            if ((prop.DeveloperName == 'RenewalQuoteBatch_CoreFutureDays' && String.isNotBlank(prop.Value__c))) {
                System.debug('MSP:' + prop.Value__c);
                try {
                    coreDaysToAdd = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {
                    system.debug('Exception setting coreDaysToAdd: ' + e.getMessage());
                }
            }

            //MSP - Set the future date
            if ((prop.DeveloperName == 'RenewalQuoteBatch_MSPFutureDays' && String.isNotBlank(prop.Value__c))) {
                System.debug('MSP:' + prop.Value__c);
                try {
                    mspDaysToAdd = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {
                    system.debug('Exception setting mspDaysToAdd: ' + e.getMessage());    
                }
            }
            
            //SONIAN - Set the future date
            if ((prop.DeveloperName == 'RenewalQuoteBatch_SonianFutureDays' && String.isNotBlank(prop.Value__c))) {
                System.debug('Sonian:' + prop.Value__c);
                try {
                    sonianDaysToAdd = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {
                    system.debug('Exception setting sonianDaysToAdd: ' + e.getMessage());   
                }
            }           

            if ((prop.DeveloperName == 'RenewalQuoteBatch_CorePastMonths' && String.isNotBlank(prop.Value__c))|| (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                System.debug('Core Past Months:' + prop.Value__c);
                try {
                    coreMonthsPast = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {
                    system.debug('Exception setting CorePastMonths: ' + e.getMessage());
                }
            }

        } //END FOR

        //SFDC-7270 Added new future dates for Core, MSP, and Sonian
        Date coreFutureDate   = Date.today().addDays(coreDaysToAdd);
        Date mspFutureDate    = Date.today().addDays(mspDaysToAdd);
        Date sonianfutureDate = Date.today().addDays(sonianDaysToAdd);
        Date corePastDate   = Date.today().addMonths(-coreMonthsPast);

        System.debug('Core Date: ' + coreFutureDate);
        System.debug('MSP Date: ' + mspFutureDate);
        System.debug('Sonian Date: ' + sonianFutureDate);

        //SFDC-7270 Adding additional filter to the query string for each of the business group
        queryString = queryString + ' AND (' +
                                    '(Business_Group__c = \'Core\' AND SBCF_EndDate__c >'+ String.valueOf(corePastDate) + ' AND SBCF_EndDate__c <=' + String.valueOf(coreFutureDate) + ')' + 
                                    ' OR (Business_Group__c = \'MSP\' AND SBCF_EndDate__c <=' + String.valueOf(mspFutureDate) +')' + 
                                    ' OR (Business_Group__c = \'Sonian\' AND SBCF_EndDate__c <=' + String.valueOf(sonianfutureDate) + '))';

       // if (defaultLoadSize != null)
       // queryString = queryString + ' LIMIT ' + String.valueOf(defaultLoadSize);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.Debug('*** defaultBatchSize ' + defaultBatchSize);
        System.Debug('*** queryString ' + queryString);
        return Database.getQueryLocator(queryString);
    }

    global void execute(Database.BatchableContext BC, List<Contract> contractList){
        Map<ID, Contract> errors = new Map<ID, Contract>();
        
        List<Contract> contractsToUpdate = new List<Contract>();

         // SFDC-14041
         Map<Id,List<SBQQ__Subscription__c>> conSubEnddateMap = new Map<Id,List<SBQQ__Subscription__c>>();
         Map<Id,List<SBQQ__Subscription__c>> conSubRenewedMap = new Map<Id,List<SBQQ__Subscription__c>>();
         Map<Id,List<Opportunity>> conSubRenOpsMap = new Map<Id,List<Opportunity>>();
 
         List<SBQQ__Subscription__c> subsEnddate = [Select Id,SBQQ__Contract__c, Name from SBQQ__Subscription__c where 
                                                    SBQQ__EndDate__c>Today and  SBQQ__Contract__c in :contractList];
 
         List<SBQQ__Subscription__c> subsRenewed = [Select Id, SBQQ__Contract__c,Name from SBQQ__Subscription__c where
                                                    Renewed_By_Subscription__c =null and  SBQQ__Contract__c in :contractList];
 
         List<Opportunity> subsRenOps = [Select Id, SBQQ__RenewedContract__c,Name from Opportunity  where stagename='Closed Won'
                                                    and SBQQ__RenewedContract__c in :contractList];
 
 
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
        
        for (Contract c: contractList){
            System.Debug('*** process contract ' + c.Id); 
            
            // SFDC-14041
            
            if(c.Business_Group__c =='Core' ) {
            
         //   if(c.SBQQ__RenewalOpportunity__c !=null)
           //    continue;
        
          if(conSubEnddateMap.get(c.id)==null ) //|| conSubEnddateMap.get(c.id).size()<1)
             continue;         
            
          if(conSubRenewedMap.get(c.id)==null ) //|| conSubRenewedMap.get(c.id).size()<1)
             continue;

           if(conSubRenOpsMap.get(c.id)!=null )//&& conSubRenOpsMap.get(c.id).size()>0)
             continue;
           
           }
            // SFDC-14041

            c.Contract_Error_Check__c = null;
            c.Has_Contract_Error__c = FALSE;

            c.SBQQ__RenewalQuoted__c = true;

            contractsToUpdate.add(c);
        }

        System.Debug('***  contractsToUpdate ' + contractsToUpdate);

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.allowFieldTruncation = true;

        Database.SaveResult[] srList = Database.update(contractsToUpdate, false);

        List<Auto_Approve_Contract__c> autoApproveRecordsToCreate = new List<Auto_Approve_Contract__c>();
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
                o.Contract_Error_Check__c = 'RenewalQuoteBatchJob Error: ' + errorMsg;
                o.Has_Contract_Error__c = TRUE;
                errors.put(o.Id, o);
            } else {
                System.Debug('*** success contract ' + o.Id);
                // SFDC-17488 - Create Auto Approve Contract records for successfully renewal quoted Contracts
                Auto_Approve_Contract__c aacRecord = new Auto_Approve_Contract__c();
                aacRecord.Quote_Approval_Status__c = 'Pending';
                aacRecord.Contract_ID__c = sr.getId();
                
                autoApproveRecordsToCreate.add(aacRecord);
            }
        }

        if(!autoApproveRecordsToCreate.isEmpty()) {
            insert autoApproveRecordsToCreate;
        }

        if (errors.size() > 0)
            Database.update(errors.values(), false);
    }

    global void finish(Database.BatchableContext BC){
        
    }

    /*
    CPQRenewQuoteBatch batch = new CPQRenewQuoteBatch();
    Integer batchSize = batch.defaultBatchSize;
    Database.executeBatch(batch, batchSize);

    CPQRenewQuoteBatchSched p = new CPQRenewQuoteBatchSched();
    String sch = '0 0 22,23 * * ?';
    system.schedule('CPQRenewQuoteBatchSched 0', sch, p);
    sch = '0 15 22,23 * * ?';
    system.schedule('CPQRenewQuoteBatchSched 15', sch, p);
    sch = '0 30 22,23 * * ?';
    system.schedule('CPQRenewQuoteBatchSched 30', sch, p);
    sch = '0 45 22,23 * * ?';
    system.schedule('CPQRenewQuoteBatchSched 45', sch, p);

    private Integer defaultScheduleMinFromNow = 10;
        global static void scheduleBatch( Integer minFromNow, Integer batchSize){
        CPQRenewQuoteBatch batch = new CPQRenewQuoteBatch();
        if (batchSize == null){
            batchSize = batch.defaultBatchSize;
        }
        if (minFromNow == null){
            minFromNow = batch.defaultScheduleMinFromNow;
        }
        String jobName = 'CPQRenewQuoteBatch ' + String.valueOf(Datetime.now());
        System.scheduleBatch(batch, jobName, minFromNow, batchSize);
    }

    select Id, CreatedBy.Name, CreatedDate, LastModifiedDate, 
        SBQQ__RenewalForecast__c, SBQQ__RenewalQuoted__c, 
        SBQQ__RenewalOpportunity__c, SBQQ__RenewalOpportunity__r.CloseDate
    from Contract 
    where SBQQ__RenewalQuoted__c = false and 
        Status = 'Activated' and 
        Auto_Renew__c = true and 
        Exclude_from_Batch__c = false and 
        Demo_Opp__c = false  and 
        ((Business_Group__c = 'Core' and SBCF_EndDate__c <=2020-02-19) or 
        (Business_Group__c = 'MSP' and SBCF_EndDate__c <=2019-12-05) or 
        (Business_Group__c = 'Sonian' and SBCF_EndDate__c <=2019-12-05)) 
*/
}