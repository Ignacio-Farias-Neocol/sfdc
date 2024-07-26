/**
* @author        Abi
* @date          2019-10-15
* @description   Unit Test class for DynamicBusinessRuleOrderProductInfoSync
* @group         Test
*
*/
@isTest
public with sharing class DynamicBusinessRuleOrderProductSyncTest {
    
     @isTest 
     static void testProductInfoSyncUpdate() {

        // by pass business action
    	TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); 
        List<Product2> products = TestDataFactory.products;
        List<Order> orders = TestDataFactory.orders;
        TriggerHandler.clearAllBypasses();

        Test.startTest();

        products[0].ProductCode = 'TEST';
        products[0].Family = 'TEST';
        update products;

        // Create and insert an integration snapshot record
        Integration_Snapshot__c s = new Integration_Snapshot__c();
        s.Object_Name__c      = 'Order';
        s.External_ID__c      = 'Order' + orders[0].Id + '-order-sync-bos-event';
        s.Message_Payload__c  = 'BOS SYNC TEST';
        s.Record_ID__c        = orders[0].Id;
        s.System_Name__c      = 'BOS';
        s.Sync_Status__c      = 'Success';
        s.System_Record_Id__c = '12345678'; 
        s.Integration_App__c  = 'proc-order-sync-bos-event'; 
        insert s;

        List<Integration_Snapshot__c> snapshots = new List<Integration_Snapshot__c>{s};

        DynamicBusinessRuleOrderProductInfoSync d = new DynamicBusinessRuleOrderProductInfoSync();
        d.processRecords(null, null, snapshots, '', '', '');
        
        // Update integration snapshot to set product information
        update s;
        
        Test.stopTest();

        // Fetch the updated record
        List<Integration_Snapshot__c> snapshot = [Select Id, Product_List__c, Product_Family__c, Total_Amount__c from Integration_Snapshot__c];
        System.assertEquals(snapshot[0].Product_List__c, 'TEST');
        System.assertEquals(snapshot[0].Product_Family__c, 'TEST');
        System.assertEquals(snapshot[0].Total_Amount__c, 1);
    }
}