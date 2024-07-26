/**
* @author Abi
* @date 10/14/2019
*
* @group DynamicBusinessRuleAction
* @group-content a relative path to a static html file that provides content about the group
*
* @description implementation of DynamicBusinessRuleAction interface to add product information to 
* Order Failure report to enable CS team to triage order failures. Related JIRA ticket SFDC-8780.
*
*
*/

public with sharing class DynamicBusinessRuleOrderProductInfoSync implements DynamicBusinessRuleAction {

    //Instantiate the log class to capture logs for error conditions
    LogModel log = LogModel.startLog('DynamicBusinessRuleOrderProductInfoSync', 'processRecords');

    public void processRecords(Map<Id,SObject> newRecordMap, 
                              Map<Id,SObject> oldRecordMap,
                              List <SObject> records, 
                              String jsonParameter, 
                              String triggerOrder, 
                              String triggerContext) {
        
        List<String> orderIds = new List<String>();
        for (SObject obj : records) {
            //Cast the sObject instance to Integration Snapshot instance
            Integration_Snapshot__c snapshot = (Integration_Snapshot__c) obj;
            if(snapshot.Object_Name__c == 'Order' && String.isNotBlank(snapshot.Record_ID__c) ) {
                orderIds.add(snapshot.Record_ID__c);
            }
        }
        
        Map<String, Integration_Snapshot__c>  snapshotMap = new Map<String, Integration_Snapshot__c>();
        
        if(!orderIds.isEmpty()) {
            for(Order o : [SELECT Id, TotalAmount, (SELECT Id,  Product2.ProductCode, Product2.Name, Product2.Family, ListPrice, TotalPrice from OrderItems) FROM Order WHERE Id IN :orderIds]) {
                Integration_Snapshot__c snapshot = new Integration_Snapshot__c();
                String productList = '';
                String productFamily = '';
                for(OrderItem item: o.OrderItems) {
                    productList = String.isNotBlank(item.Product2.ProductCode) ? productList + ';' + item.Product2.ProductCode : productList;
                    productFamily = String.isNotBlank(item.Product2.Family) ? productFamily + ';' + item.Product2.Family : productFamily;
                }
                snapshot.Product_List__c = String.isNotBlank(productList) ? productList.removeStart(';') : null;
                snapshot.Product_Family__c = String.isNotBlank(productFamily) ? productFamily.removeStart(';') : null;
                snapshot.Total_Amount__c =  o.TotalAmount;
                snapshotMap.put(o.Id, snapshot);
            }
        }

        //Loop through the Integration snapshot records.   
        for (SObject obj : records) {
            //Cast the sObject instance to Integration Snapshot instance
            Integration_Snapshot__c snapshot = (Integration_Snapshot__c) obj;
            if(snapshot.Object_Name__c == 'Order' && String.isNotBlank(snapshot.Record_ID__c) ) {
                snapshot.Product_List__c = snapshotMap.get(snapshot.Record_ID__c).Product_List__c;
                snapshot.Product_Family__c = snapshotMap.get(snapshot.Record_ID__c).Product_Family__c;
                snapshot.Total_Amount__c = snapshotMap.get(snapshot.Record_ID__c).Total_Amount__c;
            }
        }
    }
}