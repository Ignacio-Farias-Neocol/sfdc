/**
 * Created by iyeung on 1/2/19.
 *
 *  @Date 2019/1/2
 *  @group Batchable
 *
 *  Yuli FIntescu   11/21/2019  Redo
 */
global with sharing  class CPQPlaceOrderBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Integer defaultBatchSize = null;
    private Integer defaultLoadSize = null;

    public String SOQL = 'select ID, Name, ' + 
                            'Status, ' + 
                            'Auto_Renew__c, ' + 
                            'SBQQ__Contracted__c, ' + 
                            'Opportunity.CloseDate, ' + 
                            'Type ' + 
                        'from Order ' + 
                        'where Has_Contract_Error__c = FALSE and ' + 
                            '(Contracted_Date_Time__c != null OR ' + 
                            'Assets_Created_Date_Time__c != null) and ' + 
                            '(Status = \'Activated\') and ' + 
                            'Auto_Renew__c = true and ' + 
                            /***
                             * SFDC-17285: Added extra condition as All_Subs_RMA__c  = false: START
                             * */
                            'SBQQ__Contracted__c = true  and ' +
                            'Contract.All_Subs_RMA__c = false';
                            /***
                             * SFDC-17285: Added extra condition as All_Subs_RMA__c  = false: END
                             * */

    public CPQPlaceOrderBatch() {
        List<Batch_Job_System_Property__mdt> props = [Select ID, DeveloperName, MasterLabel, Value__c, Business_Group__c From Batch_Job_System_Property__mdt];

        for (Batch_Job_System_Property__mdt prop : props) {
            if ((prop.DeveloperName == 'Place_Order_Load_Size' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
                try {
                    defaultLoadSize = Integer.valueOf(prop.Value__c);
                } catch (Exception e) {}
            }
            
            if ((prop.DeveloperName == 'Place_Order_BatchJob_Size' && !String.isEmpty(prop.Value__c)) || (Test.isRunningTest() && prop.DeveloperName == 'TestClassOnly')) {
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
            System.Debug('*** process order ' + o.Id);
            o.Status = 'Placed';

            o.Contract_Error_Check__c = null;
            o.Has_Contract_Error__c = FALSE;

            ordersToUpdate.add(o);
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
                o.Contract_Error_Check__c = 'PlaceOrderBatchJob Error: ' + errorMsg;
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
    CPQPlaceOrderBatch batch = new CPQPlaceOrderBatch();
    if (batch.defaultBatchSize == null)
        Database.executeBatch(batch);
    else {
        Integer batchSize = batch.defaultBatchSize;
        Database.executeBatch(batch, batchSize);
    }
*/
}