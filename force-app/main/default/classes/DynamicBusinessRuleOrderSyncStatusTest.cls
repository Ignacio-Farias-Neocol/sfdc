/**
* @author        Pradeep Shetty/salesforce services
* @date          2019-09-24
* @description   Unit Test class for DynamicBusinessRuleUpdateOrderSyncStatus
* @group         Test
*
*/
@isTest
public with sharing class DynamicBusinessRuleOrderSyncStatusTest {

  //Scenario: BOS Sync is successful
  @isTest static void test_BOSSyncSuccessful() {

    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
    Order o = TestDataFactory.orders[0];
    TriggerHandler.clearAllBypasses();

    Test.startTest();

    //Create and insert an integration snapshot record
    Integration_Snapshot__c s = new Integration_Snapshot__c();
    s.Object_Name__c      = 'Order';
    s.External_ID__c      = 'Order' + o.Id+ '-order-sync-bos-event';
    s.Message_Payload__c  = 'BOS SYNC TEST';
    s.Record_ID__c        = o.id;
    s.System_Name__c      = 'BOS';
    s.Sync_Status__c      = 'Success';
    s.System_Record_Id__c = '12345678'; 
    s.Integration_App__c  = 'proc-order-sync-bos-event'; 
    insert s;
      
    Test.stopTest();

    //Fetch the updated Order
    Order updatedOrder = [Select BOS_Sync_Status__c, 
                                 Netsuite_Sync_Status__c 
                          From Order 
                          Where Id = :o.Id 
                          Limit 1];
    //Assertions
    System.assertEquals('Success', updatedOrder.BOS_Sync_Status__c);
    System.assert(String.isBlank(updatedOrder.Netsuite_Sync_Status__c));
  }

  //Scenario: Netsuite Sync is successful
  @isTest static void test_NetsuiteSyncSuccessful() {

    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
    Order o = TestDataFactory.orders[0];
    TriggerHandler.clearAllBypasses();

    Test.startTest();

    //Create and insert an integration snapshot record
    Integration_Snapshot__c s = new Integration_Snapshot__c();
    s.Object_Name__c      = 'Order';
    s.External_ID__c      = 'Order' + o.Id+ '-order-sync-netsuite-event';
    s.Message_Payload__c  = 'NETSUITE SYNC TEST';
    s.Record_ID__c        = o.id;
    s.System_Name__c      = 'Netsuite';
    s.Sync_Status__c      = 'Success';
    s.System_Record_Id__c = '12345678'; 
    s.Integration_App__c  = 'proc-order-sync-netsuite-event'; 
    insert s;
    
    Test.stopTest();

    //Fetch the updated Order
    Order updatedOrder = [Select BOS_Sync_Status__c, 
                                 Netsuite_Sync_Status__c 
                          From Order 
                          Where Id = :o.Id 
                          Limit 1];
    //Assertions
    System.assertEquals('Success', updatedOrder.Netsuite_Sync_Status__c);
    System.assert(String.isBlank(updatedOrder.BOS_Sync_Status__c));
  }
  //Scenario: BOS Sync failed
  @isTest static void test_BOSSyncFail() {

    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
    Order o = TestDataFactory.orders[0];
    TriggerHandler.clearAllBypasses();

    Test.startTest();

    //Create and insert an integration snapshot record
    Integration_Snapshot__c s = new Integration_Snapshot__c();
    s.Object_Name__c     = 'Order';
    s.External_ID__c     = 'Order' + o.Id+ '-order-sync-bos-event';
    s.Message_Payload__c = 'BOS SYNC TEST';
    s.Record_ID__c       = o.id;
    s.System_Name__c     = 'BOS';
    s.Sync_Status__c     = 'N/A';
    s.Integration_App__c = 'proc-order-sync-bos-event'; 
    insert s;
      
    Test.stopTest();

    //Fetch the updated Order
    Order updatedOrder = [Select BOS_Sync_Status__c, 
                                 Netsuite_Sync_Status__c 
                          From Order 
                          Where Id = :o.Id 
                          Limit 1];
    //Assertions
    System.assertEquals('N/A', updatedOrder.BOS_Sync_Status__c);
    System.assert(String.isBlank(updatedOrder.Netsuite_Sync_Status__c));
  }

  //Scenario: Netsuite Sync failed
  @isTest static void test_NetsuiteSyncFail() {

    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
    Order o = TestDataFactory.orders[0];
    TriggerHandler.clearAllBypasses();

    Test.startTest();

    //Create and insert an integration snapshot record
    Integration_Snapshot__c s = new Integration_Snapshot__c();
    s.Object_Name__c     = 'Order';
    s.External_ID__c     = 'Order' + o.Id+ '-order-sync-netsuite-event';
    s.Message_Payload__c = 'NETSUITE SYNC TEST';
    s.Record_ID__c       = o.id;
    s.System_Name__c     = 'Netsuite';
    s.Sync_Status__c     = 'N/A';
    s.Integration_App__c = 'proc-order-sync-netsuite-event'; 
    insert s;
    
    Test.stopTest();

    //Fetch the updated Order
    Order updatedOrder = [Select BOS_Sync_Status__c, 
                                 Netsuite_Sync_Status__c 
                          From Order 
                          Where Id = :o.Id 
                          Limit 1];
    //Assertions
    System.assertEquals('N/A', updatedOrder.Netsuite_Sync_Status__c);
    System.assert(String.isBlank(updatedOrder.BOS_Sync_Status__c));
  }   
    
  //Scenario: ZAB Sync is successful  SFDC-13633
  @isTest static void test_ZABSyncSuccessful() {

    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
    Order o = TestDataFactory.orders[0];
    TriggerHandler.clearAllBypasses();

    Test.startTest();

    //Create and insert an integration snapshot record
    Integration_Snapshot__c s = new Integration_Snapshot__c();
    s.Object_Name__c      = 'Order';
    s.External_ID__c      = 'Order' + o.Id+ '-order-sync-zab-event';
    s.Message_Payload__c  = 'ZAB SYNC TEST';
    s.Record_ID__c        = o.id;
    s.System_Name__c      = 'ZAB';
    s.Sync_Status__c      = 'Success';
    s.System_Record_Id__c = '12345678'; 
    s.Integration_App__c  = 'proc-order-sync-zab-event'; 
    insert s;
      
    Test.stopTest();

    //Fetch the updated Order
    Order updatedOrder = [Select BOS_Sync_Status__c, 
                                 Netsuite_Sync_Status__c,ZAB_Sync_Status__c,ECHO_Sync_Status__c
                          From Order 
                          Where Id = :o.Id 
                          Limit 1];
    //Assertions
    System.assertEquals('Success', updatedOrder.ZAB_Sync_Status__c);
    System.assert(String.isBlank(updatedOrder.BOS_Sync_Status__c));
    System.assert(String.isBlank(updatedOrder.Netsuite_Sync_Status__c));
    System.assert(String.isBlank(updatedOrder.ECHO_Sync_Status__c));
  }
    
  //Scenario: ZAB Sync failed  SFDC-13633
  @isTest static void test_ZABSyncFail() {

    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
    Order o = TestDataFactory.orders[0];
    TriggerHandler.clearAllBypasses();

    Test.startTest();

    //Create and insert an integration snapshot record
    Integration_Snapshot__c s = new Integration_Snapshot__c();
    s.Object_Name__c     = 'Order';
    s.External_ID__c     = 'Order' + o.Id+ '-order-sync-zab-event';
    s.Message_Payload__c = 'ZAB SYNC TEST';
    s.Record_ID__c       = o.id;
    s.System_Name__c     = 'ZAB';
    s.Sync_Status__c     = 'Failure';
    s.Integration_App__c = 'proc-order-sync-zab-event'; 
    insert s;
      
    Test.stopTest();

    //Fetch the updated Order
    Order updatedOrder = [Select BOS_Sync_Status__c, 
                                 Netsuite_Sync_Status__c,ZAB_Sync_Status__c,ECHO_Sync_Status__c 
                          From Order 
                          Where Id = :o.Id 
                          Limit 1];
    //Assertions
    System.assertEquals('Failure', updatedOrder.ZAB_Sync_Status__c);
    System.assert(String.isBlank(updatedOrder.BOS_Sync_Status__c));
    System.assert(String.isBlank(updatedOrder.Netsuite_Sync_Status__c));
    System.assert(String.isBlank(updatedOrder.ECHO_Sync_Status__c));
  }
    
  //Scenario: ECHO Sync is successful  SFDC-13633
  @isTest static void test_ECHOSyncSuccessful() {

    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
    Order o = TestDataFactory.orders[0];
    TriggerHandler.clearAllBypasses();

    Test.startTest();

    //Create and insert an integration snapshot record
    Integration_Snapshot__c s = new Integration_Snapshot__c();
    s.Object_Name__c      = 'Order';
    s.External_ID__c      = 'Order' + o.Id+ '-order-sync-echo-event';
    s.Message_Payload__c  = 'ECHO SYNC TEST';
    s.Record_ID__c        = o.id;
    s.System_Name__c      = 'ECHO';
    s.Sync_Status__c      = 'Success';
    s.System_Record_Id__c = '12345678'; 
    s.Integration_App__c  = 'proc-order-sync-echo-event'; 
    insert s;
      
    Test.stopTest();

    //Fetch the updated Order
    Order updatedOrder = [Select BOS_Sync_Status__c, 
                                 Netsuite_Sync_Status__c,ZAB_Sync_Status__c,ECHO_Sync_Status__c
                          From Order 
                          Where Id = :o.Id 
                          Limit 1];
    //Assertions
    System.assertEquals('Success', updatedOrder.ECHO_Sync_Status__c);
    System.assert(String.isBlank(updatedOrder.BOS_Sync_Status__c));
    System.assert(String.isBlank(updatedOrder.Netsuite_Sync_Status__c));
    System.assert(String.isBlank(updatedOrder.ZAB_Sync_Status__c));
  }
    
  //Scenario: ECHO Sync failed  SFDC-13633
  @isTest static void test_ECHOSyncFail() {

    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
    Order o = TestDataFactory.orders[0];
    TriggerHandler.clearAllBypasses();

    Test.startTest();

    //Create and insert an integration snapshot record
    Integration_Snapshot__c s = new Integration_Snapshot__c();
    s.Object_Name__c     = 'Order';
    s.External_ID__c     = 'Order' + o.Id+ '-order-sync-echo-event';
    s.Message_Payload__c = 'ECHO SYNC TEST';
    s.Record_ID__c       = o.id;
    s.System_Name__c     = 'ECHO';
    s.Sync_Status__c     = 'Failure';
    s.Integration_App__c = 'proc-order-sync-echo-event'; 
    insert s;
      
    Test.stopTest();

    //Fetch the updated Order
    Order updatedOrder = [Select BOS_Sync_Status__c, 
                                 Netsuite_Sync_Status__c,ZAB_Sync_Status__c,ECHO_Sync_Status__c 
                          From Order 
                          Where Id = :o.Id 
                          Limit 1];
    //Assertions
    System.assertEquals('Failure', updatedOrder.ECHO_Sync_Status__c);
    System.assert(String.isBlank(updatedOrder.BOS_Sync_Status__c));
    System.assert(String.isBlank(updatedOrder.Netsuite_Sync_Status__c));
    System.assert(String.isBlank(updatedOrder.ZAB_Sync_Status__c));
  }

  //Scenario: Order should not be updated when an Salesforce snapshot is created
  @isTest static void test_SalesforceSnapshot() {

    TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
    Order o = TestDataFactory.orders[0];
    TriggerHandler.clearAllBypasses();

    Test.startTest();

    //Create and insert an integration snapshot record for Salesforce
    Integration_Snapshot__c s = new Integration_Snapshot__c();
    s.Object_Name__c     = 'Order';
    s.External_ID__c     = o.Id;
    s.Message_Payload__c = 'SALESFORCE SNAPSHOT TEST';
    s.Record_ID__c       = o.id;
    s.System_Name__c     = 'Salesforce';
    s.Sync_Status__c     = 'Success';
    s.Integration_App__c = 'Platform Event Trigger'; 
    insert s;
    
    Test.stopTest();

    //Fetch the updated Order
    Order updatedOrder = [Select BOS_Sync_Status__c, 
                                 Netsuite_Sync_Status__c,ZAB_Sync_Status__c,ECHO_Sync_Status__c  
                          From Order 
                          Where Id = :o.Id 
                          Limit 1];
    //Assertions
    System.assert(String.isBlank(updatedOrder.Netsuite_Sync_Status__c));
    System.assert(String.isBlank(updatedOrder.BOS_Sync_Status__c));
    System.assert(String.isBlank(updatedOrder.ZAB_Sync_Status__c));
    System.assert(String.isBlank(updatedOrder.ECHO_Sync_Status__c));
  }     
}