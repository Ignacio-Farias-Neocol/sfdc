/**
* @author        Sonal Agrawal(Bluvium)
* @date          16th October 2023
* @description   Has CPQReContractedOrderBatchSched class which scheduled at 3 am daily
*
*/
public class CPQReContractedOrderBatch implements Database.Batchable<SObject>{
    public Integer defaultBatchSize = 1;
    private Integer defaultLoadSize = null;
    
    public String SOQL = ' select Status, ' + 
        'StatusCode, ' + 
        'Auto_Renew__c, ' + 
        'SBQQ__Contracted__c, ' + 
        'Type, ' + 
        'Order_Item_Count__c, ' + 
        'Contract_Error_Check__c, ' + 
        'Has_Contract_Error__c ' + 
        'from Order ' + 
        'where Has_Contract_Error__c = FALSE and ' + 
        'Active_Contract__c = null and ' + 
        'SBQQ__Contracted__c = true and ' + 
        'Auto_Renew__c = true and ' + 
        'Order_Item_Count__c != 0 AND ' +
        'Contract.All_Subs_RMA__c = false and SBQQ__Quote__r.SBQQ__EndDate__c >=TODAY';
    
    public CPQReContractedOrderBatch() {
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
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.Debug('*** defaultBatchSize ' + defaultBatchSize);
        System.Debug('*** SOQL ' + SOQL);
        return Database.getQueryLocator(SOQL);
    }
    
    public void execute(Database.BatchableContext BC, List<Order> oList){
        Map<ID, Order> errors = new Map<ID, Order>();
        List<Order> ordersToUpdate = new List<Order>();
        for (Order o: oList){
            Order o1 = new Order(ID = o.ID, Status = 'Activated', SBQQ__Contracted__c=false);
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
                o.Contract_Error_Check__c = 'CPQReContractedOrderBatch Error: ' + errorMsg;
                o.Has_Contract_Error__c = TRUE;
                errors.put(o.Id, o);
            } else {
                System.Debug('*** success order ' + o.Id);
            }
        }
        
        if (errors.size() > 0)
            Database.update(errors.values(), false);
    }
    public void finish(Database.BatchableContext BC){}
}