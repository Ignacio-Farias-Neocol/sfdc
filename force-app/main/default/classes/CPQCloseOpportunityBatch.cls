/**
 * Created by iyeung on 1/2/19.
 *
 *  @Date 2019/1/2
 *  @group Batchable
 * 
 *  Yuli FIntescu   11/21/2019  Redo
 */
global with sharing  class CPQCloseOpportunityBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Integer defaultBatchSize = 1;
    private Integer defaultLoadSize = null;

    public String SOQL = 'select Id, LeadSource, ' + 
                            'SBQQ__Ordered__c, ' + 
                            'SBQQ__Renewal__c, ' + 
                            'StageName , ' + 
                            'Auto_Renew__c, ' + 
                            'CloseDate, ' + 
                            'SBQQ__PrimaryQuote__c, ' + 
                            'SBQQ__PrimaryQuote__r.ApprovalStatus__c, ' + 
                            'SBQQ__PrimaryQuote__r.Has_Contract_Error__c, ' + 
                            'SBQQ__RenewedContract__c, ' + 
                            'SBQQ__RenewedContract__r.Lead_Source__c, ' + 
                            'SBQQ__RenewedContract__r.Primary_Contact__c, ' +                             
                            'Billing_Address__c, ' + 
                            'Billing_Address__r.Street__c, ' + 
                            'Billing_Address__r.City__c, ' + 
                            'Billing_Address__r.Zip_Postal_Code__c, ' + 
                            'Billing_Address__r.Country__c, Billing_Address__r.Country__r.Name, ' + 
                            'Billing_Address__r.State__c, Billing_Address__r.State__r.Name, ' + 
                            'Billing_Address__r.Country_ISO__c, ' + 
                            'Street__c, ' + 
                            'City__c, ' + 
                            'Zip_Postal_Code__c, ' + 
                            'Country__c, ' + 
                            'State__c, ' + 
                            'Country_ISO_Code__c, ' + 
                            'Shipping_Address__c, ' + 
                            'Shipping_Address__r.Street__c, ' + 
                            'Shipping_Address__r.City__c, ' + 
                            'Shipping_Address__r.Zip_Postal_Code__c, ' + 
                            'Shipping_Address__r.Country__c, Shipping_Address__r.Country__r.Name, ' + 
                            'Shipping_Address__r.State__c, Shipping_Address__r.State__r.Name, ' + 
                            'Shipping_Address__r.Country_ISO__c, ' + 
                            'Ship_To_Street__c, ' + 
                            'Ship_To_City__c, ' + 
                            'Ship_To_Zip_Postal_Code__c, ' + 
                            'Ship_To_Country__c, ' + 
                            'Ship_To_State__c, ' + 
                            'Shipping_Country_ISO_Code__c, ' + 
                            'Primary_Contact__c, ' + 
                            'AccountId, ' + 
                            'Account.Billing_Contact__c, ' + 
                            'Contract_Error_Check__c, ' + 
                            'Has_Contract_Error__c, ' + 
                            '(Select ID From SBQQ__Quotes2__r Where SBQQ__Primary__c = TRUE) ' + 
                        'from Opportunity ' + 
                        'where Has_Contract_Error__c = FALSE and SBQQ__Renewal__c = true and StageName <> \'Closed Lost\' and ' + 
                            '(SBQQ__Ordered__c = FALSE or StageName != \'Closed Won\') and ' + 
                            'Auto_Renew__c = true and ' + 
                            '((SBQQ__PrimaryQuote__c = null) or ' + 
                            /***
                             * SFDC-17285: Added extra condition as All_Subs_RMA__c  = false: START
                             * */
                            '(SBQQ__PrimaryQuote__r.ApprovalStatus__c = \'Approved\' and SBQQ__PrimaryQuote__r.Has_Contract_Error__c = FALSE)) And ' +
                            '(SBQQ__AmendedContract__r.All_Subs_RMA__c = false OR SBQQ__RenewedContract__r.All_Subs_RMA__c = false)';
                            /***
                             * SFDC-17285: Added extra condition as All_Subs_RMA__c  = false: END
                             * */
                        //exclude oppties which primary quote has contract error, so when the quote is corrected, the oppties can be picked up by the next batch
    public CPQCloseOpportunityBatch() {

        Date today = Date.today();
        Date tomorrow = today.addDays(1);
        SOQL += ' and ( CloseDate <=  ' + String.valueOf(today)  + ') ';

        List<Batch_Job_System_Property__mdt> props = [Select ID, DeveloperName, MasterLabel, Value__c, Business_Group__c From Batch_Job_System_Property__mdt];

        for (Batch_Job_System_Property__mdt prop : props) {
            if ((prop.DeveloperName == 'CloseWon_Opportunity_Load_Size' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                try {
                    defaultLoadSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
            
            if ((prop.DeveloperName == 'CloseWon_Opportunity_BatchJob_Size' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                try {
                    defaultBatchSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
        }

        if (defaultLoadSize != null)
            SOQL += ' LIMIT ' + String.valueOf(defaultLoadSize);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.Debug('*** defaultBatchSize ' + defaultBatchSize);
        System.Debug('*** SOQL ' + SOQL);
        return Database.getQueryLocator(SOQL);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> oList){
        Map<ID, Opportunity> errors = new Map<ID, Opportunity>();
        
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Opportunity o: oList){
            System.Debug('*** process oppty ' + o.Id);

            o.StageName = 'Closed Won';
            
            o.SBQQ__Ordered__c = true;  // not needed, set by system
            
            if (o.LeadSource  == null || o.LeadSource == ''){
                o.LeadSource = (o.SBQQ__RenewedContract__r.Lead_Source__c == null ? 'Renewal' : o.SBQQ__RenewedContract__r.Lead_Source__c);
            }
            
            if (!String.isEmpty(o.Billing_Address__c) && 
                    (String.isEmpty(o.Street__c) ||
                    String.isEmpty(o.City__c) ||
                    String.isEmpty(o.Zip_Postal_Code__c) ||
                    String.isEmpty(o.State__c) ||
                    String.isEmpty(o.Country__c) ||
                    String.isEmpty(o.Country_ISO_Code__c))) {
                o.Street__c = o.Billing_Address__r.Street__c;
                o.City__c = o.Billing_Address__r.City__c;
                o.Zip_Postal_Code__c = o.Billing_Address__r.Zip_Postal_Code__c;
                o.State__c = o.Billing_Address__r.State__r.Name;
                o.Country__c = o.Billing_Address__r.Country__r.Name;
                o.Country_ISO_Code__c = o.Billing_Address__r.Country_ISO__c;
            }

            if (!String.isEmpty(o.Shipping_Address__c) && 
                    (String.isEmpty(o.Ship_To_Street__c) ||
                    String.isEmpty(o.Ship_To_City__c) ||
                    String.isEmpty(o.Ship_To_Zip_Postal_Code__c) ||
                    String.isEmpty(o.Ship_To_State__c) ||
                    String.isEmpty(o.Ship_To_Country__c) ||
                    String.isEmpty(o.Shipping_Country_ISO_Code__c))) {
                o.Ship_To_Street__c = o.Shipping_Address__r.Street__c;
                o.Ship_To_City__c = o.Shipping_Address__r.City__c;
                o.Ship_To_Zip_Postal_Code__c = o.Shipping_Address__r.Zip_Postal_Code__c;
                o.Ship_To_State__c = o.Shipping_Address__r.State__r.Name;
                o.Ship_To_Country__c = o.Shipping_Address__r.Country__r.Name;
                o.Shipping_Country_ISO_Code__c = o.Shipping_Address__r.Country_ISO__c;
            }
            
            if (o.Primary_Contact__c == null) {
                o.Primary_Contact__c = o.SBQQ__RenewedContract__r.Primary_Contact__c;
                //o.Primary_Contact__c = (o.SBQQ__RenewedContract__r.Primary_Contact__c == null ? o.Account.Billing_Contact__c : o.SBQQ__RenewedContract__r.Primary_Contact__c);
            }
            
            if (!String.isEmpty(o.Contract_Error_Check__c)) {
                o.Contract_Error_Check__c = null;
            }

            if (o.Has_Contract_Error__c == TRUE) {
                o.Has_Contract_Error__c = FALSE;
            }
            
            //Yuli Added. SBQQ__PrimaryQuote__c is not populated for auto renewal if you don't touch the screen
            if (o.SBQQ__PrimaryQuote__c == null && o.SBQQ__Quotes2__r != null && o.SBQQ__Quotes2__r.size() > 0) {
                o.SBQQ__PrimaryQuote__c = o.SBQQ__Quotes2__r[0].Id;
            }

            if (o.SBQQ__PrimaryQuote__c != null && o.Primary_Contact__c != null) {
                oppsToUpdate.add(o);
                System.Debug('*** to be closed oppty ' + o.Id);
            } else {
                String errorMsg = '';
                if (o.SBQQ__PrimaryQuote__c == null) {
                    errorMsg = 'CloseOpptyBatchJob Error: No Primary Quote.\n';
                }

                if (o.Primary_Contact__c == null) {
                    errorMsg = 'CloseOpptyBatchJob Error: No Primary Contact.\n';
                }

                Opportunity oerr = new Opportunity(ID = o.Id, Contract_Error_Check__c = errorMsg, Has_Contract_Error__c = TRUE);
                errors.put(o.Id, oerr);
            }
        }
        
        System.Debug('***  oppsToUpdate ' + oppsToUpdate);

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.allowFieldTruncation = true;
        
        Database.SaveResult[] srList = Database.update(oppsToUpdate, false);
        for (Integer i = 0; i < srList.size(); i++) {
            Opportunity o = new Opportunity(ID = oppsToUpdate[i].Id);

            Database.SaveResult sr = srList[i];
            if (!sr.isSuccess()) {
                String errorMsg = '';
                for(Database.Error err : sr.getErrors()) {
                    errorMsg = errorMsg + err.getMessage() + '\n';
                }

                System.Debug('*** error oppty ' + o.Id + ', errorMsg ' + errorMsg);
                o.setOptions(dml);
                o.Contract_Error_Check__c = 'CloseOpptyBatchJob Error: ' + errorMsg;
                o.Has_Contract_Error__c = TRUE;
                errors.put(o.Id, o);
            } else {
                System.Debug('*** success oppty ' + o.Id);
            }
        }
        
        if (errors.size() > 0)
            Database.update(errors.values(), false);
    }

    global void finish(Database.BatchableContext BC){}

/*
    CPQCloseOpportunityBatch batch = new CPQCloseOpportunityBatch();
    Integer batchSize = batch.defaultBatchSize;
    Database.executeBatch(batch, batchSize);

    CPQCloseOpportunityBatchSched p = new CPQCloseOpportunityBatchSched();
    String sch = '0 0 * * * ?';
    system.schedule('CPQCloseOpportunityBatchSched 0', sch, p);
    sch = '0 15 * * * ?';
    system.schedule('CPQCloseOpportunityBatchSched 15', sch, p);
    sch = '0 30 * * * ?';
    system.schedule('CPQCloseOpportunityBatchSched 30', sch, p);
    sch = '0 45 * * * ?';
    system.schedule('CPQCloseOpportunityBatchSched 45', sch, p);

    List<Opportunity> opps = new List<Opportunity>();
    for (Opportunity o : [select Id, StageName, (Select ID From Orders) from Opportunity 
                            where SBQQ__Ordered__c = TRUE and 
                                StageName = 'Closed Won' and 
                                SBQQ__Ordered__c = TRUE and 
                                LastModifiedDate >= Last_n_Days:7 and 
                                Business_Group__c = 'MSP' ]) {
        if (o.Orders.size() == 0) {
            o.SBQQ__Ordered__c = false;
            o.StageName = 'Not Contacted';
            opps.add(o);
            
            System.Debug('*** o.Id ' + o.Id);
        }
    }
    System.Debug('*** opps ' + opps);
    if (opps.size() > 0)
        update opps;

    List<Opportunity> opps = new List<Opportunity>();
    for (Opportunity o : [select Id, StageName from Opportunity 
                            where SBQQ__Ordered__c = false and 
                                StageName <> 'Closed Won' and 
                                Has_Contract_Error__c = TRUE
                            LIMIT 100]) {
        o.Has_Contract_Error__c = false;
        o.Contract_Error_Check__c = null;
        opps.add(o);
    }
    System.Debug('*** opps ' + opps);
    if (opps.size() > 0)
        update opps;

    Map<ID, Country__c> countries = new Map<ID, Country__c> ([Select ID, Name From Country__c]);
    Map<ID, State__c> states = new Map<ID, State__c> ([Select ID, Name From State__c]);

    List<Opportunity> opps = new List<Opportunity>();
    for (Opportunity o : [select Id, State__c, Country__c, Ship_To_State__c, Ship_To_Country__c from Opportunity 
                            where SBQQ__Ordered__c = false and StageName <> 'Closed Won' and Has_Contract_Error__c = TRUE
                            LIMIT 100]) {
        o.State__c = states.containsKey(o.State__c) ? states.get(o.State__c).Name : null;
        o.Country__c = countries.containsKey(o.Country__c) ? countries.get(o.Country__c).Name : null;
        o.Ship_To_State__c = states.containsKey(o.Ship_To_State__c) ? states.get(o.Ship_To_State__c).Name : null;
        o.Ship_To_Country__c = countries.containsKey(o.Ship_To_Country__c) ? countries.get(o.Ship_To_Country__c).Name : null;
        opps.add(o);
    }
    System.Debug('*** opps ' + opps);
    if (opps.size() > 0)
        update opps;

    select Id, LeadSource, SBQQ__RenewedContract__c, SBQQ__PrimaryQuote__c, Primary_Contact__c, CloseDate,
        CreatedBy.Name, CreatedDate, Business_Group__c 
    from Opportunity 
    where Has_Contract_Error__c = FALSE and SBQQ__Renewal__c = true and 
        (SBQQ__Ordered__c = FALSE or
        (StageName != 'Closed Won' and StageName != 'Closed Lost')) and 
        Auto_Renew__c = true and ( CloseDate <= TODAY)
*/
}