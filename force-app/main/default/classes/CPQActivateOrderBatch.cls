/**
 * Created by iyeung on 1/2/19.
 * Modified by IY 8/30/2019: add condition to include order with at least one order product
 *
 *  @Date 2019/1/2
 *  @group Batchable
 *
 *  Yuli FIntescu   11/21/2019  Redo
 */
global with sharing  class CPQActivateOrderBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Integer defaultBatchSize = 1;
    private Integer defaultLoadSize = null;

    public String SOQL = ' select Status, ' + 
                            'StatusCode, ' + 
                            'Auto_Renew__c, ' + 
                            'SBQQ__Contracted__c, ' + 
                            'Opportunity.CloseDate, ' + 
                            'Type, ' + 
                            'Order_Item_Count__c, ' + 
                            'Bill_To_Contact__c, ' + 
                            'Bill_To_Contact_Email__c, ' + 
                            'Ship_To_Contact__c, ' + 
                            'Ship_To_Contact_Email__c, ' + 
                            'Bill_To_Account__c, ' + 
                            'Bill_To_Street__c, ' + 
                            'Bill_To_City__c, ' + 
                            'Bill_To_State__c, ' + 
                            'Bill_To_Country__c, ' + 
                            'Bill_To_CountryCode__c	, ' + 
                            'Bill_To_Postal_Code__c, ' + 
                            'Ship_To_Account__c, ' + 
                            'Ship_To_Street__c	, ' + 
                            'Ship_To_City__c, ' + 
                            'Ship_To_State__c, ' + 
                            'Ship_To_Country__c, ' + 
                            'Ship_To_CountryCode__c, ' + 
                            'Ship_To_Zip_Postal_Code__c, ' + 
                            'Billing_Address__c, ' + 
                            'Billing_Address__r.Account__r.Bill_To_Contact__c, ' + 
                            'Billing_Address__r.Account__r.Bill_To_Email__c, ' + 
                            'Shipping_Address__c, ' + 
                            'BillingStreet, ' + 
                            'BillingCity, ' + 
                            'BillingState, ' + 
                            'BillingCountry, ' + 
                            'BillingCountryCode, ' + 
                            'BillingPostalCode, ' + 
                            'ShippingStreet, ' + 
                            'ShippingCity, ' + 
                            'ShippingState, ' + 
                            'ShippingCountry, ' + 
                            'ShippingCountryCode, ' + 
                            'ShippingPostalCode, ' + 
                            'Contract_Error_Check__c, ' + 
                            'Has_Contract_Error__c, ' + 
                            'Opportunity.Primary_Contact__r.FirstName, ' + 
                            'Opportunity.Primary_Contact__r.LastName, ' + 
                            'Opportunity.Primary_Contact__r.Email, ' + 
                            'Opportunity.Primary_Contact__c ' + 
                        'from Order ' + 
                        'where Has_Contract_Error__c = FALSE and ' + 
                            '((Status != \'Activated\' and Status != \'Placed\') or ' + 
                            'SBQQ__Contracted__c = false) and ' + 
                            'Auto_Renew__c = true and ' + 
                            /***
                             * SFDC-17285: Added extra condition as All_Subs_RMA__c  = false: START
                             * */
                            'Order_Item_Count__c != 0 AND ' +
                            'Contract.All_Subs_RMA__c = false';
                            /***
                             * SFDC-17285: Added extra condition as All_Subs_RMA__c  = false: END
                             * */

    public CPQActivateOrderBatch() {
        List<Batch_Job_System_Property__mdt> props = [Select ID, DeveloperName, MasterLabel, Value__c, Business_Group__c From Batch_Job_System_Property__mdt];

        for (Batch_Job_System_Property__mdt prop : props) {
            if ((prop.DeveloperName == 'Activate_Order_Load_Size' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                try {
                    defaultLoadSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
            
            if ((prop.DeveloperName == 'Activate_Order_BatchJob_Size' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
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

    global void execute(Database.BatchableContext BC, List<Order> oList){
        Map<ID, Order> errors = new Map<ID, Order>();
        
        List<Order> ordersToUpdate = new List<Order>();

        for (Order o: oList){
            System.Debug('*** pre-process order ' + o.Id);
            
            Boolean tobeupdate = false;
            
            /* From Order PB
            o.Bill_To_Account__c = o.Opportunity.Bill_To_Account__c;
            o.Bill_To_City__c = o.Opportunity.City__c;
            o.Bill_To_Contact_Email__c = o.Billing_Address__r.Account__r.Bill_To_Email__c;
            o.Bill_To_Contact__c = o.Billing_Address__r.Account__r.Bill_To_Contact__c;
            o.Bill_To_CountryCode__c = o.Opportunity.Country_ISO_Code__c;
            o.Bill_To_Country__c = o.Opportunity.Country__c;
            o.Bill_To_Postal_Code__c = o.Opportunity.Zip_Postal_Code__c;
            o.Bill_To_State__c = o.Opportunity.State__c;
            o.Bill_To_Street__c = o.Opportunity.Street__c;
            o.End_User_Contact__c = o.Opportunity.Primary_Contact__c;
            o.PoNumber = o.Opportunity.PurchaseOrderID__c;
            o.ShipToContactId = o.Opportunity.Primary_Contact__c;
            o.Ship_To_Account__c= o.Shipping_Address__r.Account__c;
            o.Ship_To_City__c = o.Opportunity.Ship_To_City__c;
            o.Ship_To_Contact_Email__c = o.Shipping_Address__r.Account__r.Ship_To_Email__c;
            o.Ship_To_Contact__c = o.Shipping_Address__r.Account__r.Ship_To_Contact__c;
            o.Ship_To_CountryCode__c = o.Shipping_Country_ISO_Code__c;
            o.Ship_To_Country__c = o.Opportunity.Ship_To_Country__c;
            o.Ship_To_State__c = o.Opportunity.Ship_To_State__c;
            o.Ship_To_Street__c = o.Opportunity.Ship_To_Street__c;
            o.Ship_To_Zip_Postal_Code__c = o.Opportunity.Ship_To_Zip_Postal_Code__c;
            */

            if (String.isEmpty(o.BillingCity) ||
                    String.isEmpty(o.BillingPostalCode) ||
                    String.isEmpty(o.BillingState) ||
                    String.isEmpty(o.BillingCountry) ||
                    String.isEmpty(o.BillingCountryCode) ||
                    String.isEmpty(o.BillingStreet)) {
                o.BillingStreet = o.Bill_To_Street__c;
                o.BillingCity = o.Bill_To_City__c;
                o.BillingPostalCode = o.Bill_To_Postal_Code__c;
                o.BillingState = o.Bill_To_State__c;
                o.BillingCountry = o.Bill_To_Country__c;
                o.BillingCountryCode = o.Bill_To_CountryCode__c;

                tobeupdate = true;
            }

            if (String.isEmpty(o.ShippingCity) ||
                    String.isEmpty(o.ShippingPostalCode) ||
                    String.isEmpty(o.ShippingState) ||
                    String.isEmpty(o.ShippingCountry) ||
                    String.isEmpty(o.ShippingCountryCode) ||
                    String.isEmpty(o.ShippingStreet)) {
                o.ShippingStreet = o.Ship_To_Street__c;
                o.ShippingCity = o.Ship_To_City__c;
                o.ShippingPostalCode = o.Ship_To_Zip_Postal_Code__c;
                o.ShippingState = o.Ship_To_State__c;
                o.ShippingCountry = o.Ship_To_Country__c;
                o.ShippingCountryCode = o.Ship_To_CountryCode__c;

                tobeupdate = true;
            }

            if (String.isEmpty(o.Ship_To_Contact__c)) {
                o.Ship_To_Contact__c = o.Opportunity.Primary_Contact__r.FirstName + '  ' + o.Opportunity.Primary_Contact__r.LastName;

                tobeupdate = true;
            }

            if (String.isEmpty(o.Ship_To_Contact_Email__c)) {
                o.Ship_To_Contact_Email__c = o.Opportunity.Primary_Contact__r.Email;

                tobeupdate = true;
            }

            if (!String.isEmpty(o.Contract_Error_Check__c)) {
                o.Contract_Error_Check__c = null;
            
                tobeupdate = true;
            }

            if (o.Has_Contract_Error__c == TRUE) {
                o.Has_Contract_Error__c = FALSE;

                tobeupdate = true;
            }

            if (tobeupdate == true)
                ordersToUpdate.add(o);
        }

        if (ordersToUpdate.size() > 0)
            Database.update(ordersToUpdate, false);
        
        //Yuli added 08/20/2019: the Status field is the only field you can update when activating the order.
        ordersToUpdate = new List<Order>();
        for (Order o: oList){
            System.Debug('*** process order ' + o.Id);
            
            Order o1 = new Order(ID = o.ID, Status = 'Activated');
            ordersToUpdate.add(o1);
        }

        System.Debug('***  ordersToUpdate ' + ordersToUpdate);

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.allowFieldTruncation = true;

        Database.SaveResult[] srList = Database.update(ordersToUpdate, false);
        for (Integer i = 0; i < srList.size(); i++) {
            Order o = new Order(ID = ordersToUpdate[i].Id);

            Database.SaveResult sr = srList[i];
            if (!sr.isSuccess()) {
                String errorMsg = '';
                for(Database.Error err : sr.getErrors()) {
                    errorMsg = errorMsg + err.getMessage() + '\n';
                }

                System.Debug('*** error order ' + o.Id + ', errorMsg ' + errorMsg);
                o.setOptions(dml);
                o.Contract_Error_Check__c = 'ActivateOrderBatchJob Error: ' + errorMsg;
                o.Has_Contract_Error__c = TRUE;
                errors.put(o.Id, o);
            } else {
                System.Debug('*** success order ' + o.Id);
            }
        }

        if (errors.size() > 0)
            Database.update(errors.values(), false);
    }

    global void finish(Database.BatchableContext BC){}

/*
    CPQActivateOrderBatch batch = new CPQActivateOrderBatch();
    Integer batchSize = batch.defaultBatchSize;
    Database.executeBatch(batch, batchSize);

    CPQActivateOrderBatchSched p = new CPQActivateOrderBatchSched();
    String sch = '0 0 * * * ?';
    system.schedule('CPQActivateOrderBatchSched 0', sch, p);
    sch = '0 15 * * * ?';
    system.schedule('CPQActivateOrderBatchSched 15', sch, p);
    sch = '0 30 * * * ?';
    system.schedule('CPQActivateOrderBatchSched 30', sch, p);
    sch = '0 45 * * * ?';
    system.schedule('CPQActivateOrderBatchSched 45', sch, p);

    Map<ID, Country__c> countries = new Map<ID, Country__c> ([Select ID, Name From Country__c]);
    Map<ID, State__c> states = new Map<ID, State__c> ([Select ID, Name From State__c]);

    List<Order> opps = new List<Order>();
    for (Order o : [select Id, Bill_To_State__c  , Bill_To_Country__c , Ship_To_State__c , Ship_To_Country__c  from Order 
                            where Bill_To_State__c like 'a3e%' OR Bill_To_Country__c like 'a3F%' or Ship_To_State__c like 'a3e%' OR Ship_To_Country__c like 'a3F%'
                            LIMIT 400]) {
        o.Bill_To_State__c = states.containsKey(o.Bill_To_State__c) ? states.get(o.Bill_To_State__c).Name : null;
        o.Bill_To_Country__c = countries.containsKey(o.Bill_To_Country__c) ? countries.get(o.Bill_To_Country__c).Name : null;
        o.Ship_To_State__c = states.containsKey(o.Ship_To_State__c) ? states.get(o.Ship_To_State__c).Name : null;
        o.Ship_To_Country__c = countries.containsKey(o.Ship_To_Country__c) ? countries.get(o.Ship_To_Country__c).Name : null;
        opps.add(o);
    }
    System.Debug('*** opps ' + opps);
    if (opps.size() > 0)
        update opps;

    List<Order> orders = new List<Order>();
    for (Order o : [select Id, Status, CreatedBy.Name, CreatedDate From Order Where CreatedDate = TODAY and CreatedByID in ('005f200000A0DWo', '005f2000009PWpV') and (Status = 'Activated' or Status = 'Placed')]) {
        o.Status = 'Draft';
        orders.add(o);
    }
    update orders;
*/
}