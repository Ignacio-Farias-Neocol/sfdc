/**
* @author        Ivan Yeung/salesforce services
* @date          2019-07-01
* @description   Unit Test class for DynamicBusinessRuleNotifyFailSync
* @group         Test
*
*/
@isTest
public with sharing class DynamicBusinessRuleNotifyFailSyncTest {

    @isTest static void unitTest() {


        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        Order o = TestDataFactory.orders[0];
        o.SBCF_Order_Type__c = 'New';
        update o;
        TriggerHandler.clearAllBypasses();


        Test.startTest();

        Integration_Snapshot__c s = new Integration_Snapshot__c();
        s.Object_Name__c = 'Order';
        s.External_ID__c  = s.Object_Name__c + '_' + 'SF' + '_' + 'Platform' + '_' + o.Id;
        s.Record_ID__c = o.id;
        s.System_Name__c = 'Salesforce';
        s.Sync_Status__c = 'Fail';
        s.Integration_App__c = 'Platform Event Trigger'; 
        insert s;

        PAM_Order_Notification__mdt pamNotification = [Select Id, DeveloperName, Type__c, Value__c From PAM_Order_Notification__mdt Where Type__c = 'Product Code' LIMIT 1];
        Product2 prod = new Product2();
        prod.Name = 'Test PAM Prod';
        prod.ProductCode = pamNotification.Value__c;
        insert prod;

        Id pbId = Test.getStandardPricebookId();
        PricebookEntry pbEntry = new PricebookEntry();
        pbEntry.Pricebook2Id = pbId;
        pbEntry.Product2Id = prod.Id;
        pbEntry.UnitPrice = 20;
        insert pbEntry;

        OrderItem rec;
        rec = new OrderItem();  
        rec.orderId = o.Id;
        rec.Quantity = 1; 
        rec.UnitPrice = 1; 
        rec.PricebookEntryId = pbEntry.Id; 
        //rec.Serial__c = serial.Id;
        rec.Product2Id = prod.Id;
        insert rec;

        Integration_Snapshot__c s1 = new Integration_Snapshot__c();
        s1.Object_Name__c = 'Order';
        s1.External_ID__c  = s.Object_Name__c + '_' + 'SF' + '_' + 'PAM' + '_' + o.Id;
        s1.Record_ID__c = o.id;
        s1.System_Name__c = 'PAM';
        s1.Sync_Status__c = 'Fail';
        s1.Integration_App__c = 'Platform Event Trigger'; 
        insert s1;

        /*
        List <Integration_Snapshot__c> snapshots = new List <Integration_Snapshot__c>();
        snapshots.add(s);
        DynamicBusinessRuleNotifyFailSync d = new DynamicBusinessRuleNotifyFailSync();
        d.processRecords(null, null, snapshots, '"john_doe@test.com"', '', '');
        */

        Test.stopTest();





    }
    
    @isTest static void unitTest2() {

        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
        Order o = TestDataFactory.orders[0];
        o.SBCF_Order_Type__c = 'New';
        update o;
        TriggerHandler.clearAllBypasses();

        Test.startTest();
        
        List<Integration_Snapshot__c> listOfSnapShot = new List<Integration_Snapshot__c>();
        Integration_Snapshot__c s1 = new Integration_Snapshot__c();
        s1.Object_Name__c = 'Order';
        s1.External_ID__c  = s1.Object_Name__c + '_' + 'SF' + '_' + 'BOS' + '_' + o.Id;
        s1.Record_ID__c = o.id;
        s1.System_Name__c = 'BOS';
        s1.Sync_Status__c = 'Fail';
        s1.Integration_App__c = 'Platform Event Trigger';
        listOfSnapShot.add(s1);
        
        Integration_Snapshot__c s2 = new Integration_Snapshot__c();
        s2.Object_Name__c = 'Order';
        s2.External_ID__c  = s2.Object_Name__c + '_' + 'SF' + '_' + 'ECHO' + '_' + o.Id;
        s2.Record_ID__c = o.id;
        s2.System_Name__c = 'ECHO';
        s2.Sync_Status__c = 'Fail';
        s2.Integration_App__c = 'Platform Event Trigger';
        listOfSnapShot.add(s2);

		Integration_Snapshot__c s3 = new Integration_Snapshot__c();
        s3.Object_Name__c = 'Order';
        s3.External_ID__c  = s3.Object_Name__c + '_' + 'SF' + '_' + 'ZAB' + '_' + o.Id;
        s3.Record_ID__c = o.id;
        s3.System_Name__c = 'ZAB';
        s3.Sync_Status__c = 'Fail';
        s3.Integration_App__c = 'Platform Event Trigger';
        listOfSnapShot.add(s3);  
        
        Integration_Snapshot__c s4 = new Integration_Snapshot__c();
        s4.Object_Name__c = 'Order';
        s4.External_ID__c  = s4.Object_Name__c + '_' + 'SF' + '_' + 'Netsuite' + '_' + o.Id;
        s4.Record_ID__c = o.id;
        s4.System_Name__c = 'Netsuite';
        s4.Sync_Status__c = 'Fail';
        s4.Integration_App__c = 'Platform Event Trigger';
        listOfSnapShot.add(s4);  
        insert listOfSnapShot;

        Test.stopTest();
    }

}