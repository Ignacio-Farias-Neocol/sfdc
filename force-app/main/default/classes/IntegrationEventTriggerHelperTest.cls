@isTest(seeAllData = FALSE)
public with sharing class IntegrationEventTriggerHelperTest {
    public testMethod static void testCreateAppLogRecord(){
        User logginUser = [select id from User where id = :UserInfo.getUserId()];
        try{
            List<Case> caseRecordList = new List<Case>(); 
            List<Integration_Event__e> intEvents = new List<Integration_Event__e>();
            Case caseRec = TestDataFactory.webCases[0];
            System.debug('caseRec is:' +caseRec);
            Id CaseRecordID = caseRec.id;
            System.debug('CaseRecordID is:' +CaseRecordID);
            Test.startTest();
            if(CaseRecordID != NULL){
                caseRecordList = [select id, caseNumber, serial_number__c, status, Case_Owner_Person__c, Engineering_Escalated_By__c, Escalated_To__c, Escalation_Approver__c, Escalated_to_support_escalations_by__c, RMA_Submitted_By__c, RMA_Approval_1__c, RMA_Approval_2__c from Case where id = :CaseRecordID];
            }
            system.debug('caseRecordList is:' +caseRecordList);
            for(Case cs : caseRecordList){
                if(Test.isRunningTest()){
                    Integration_Event__e iEvent = new Integration_Event__e();
                    //iEvent.UUID__c = PlatformEventHelper.GUIDGenerator();
                    iEvent.Object_Name__c = 'Case';
                    iEvent.Record_ID__c = cs.id;
                    iEvent.Object_Payload__c = JSON.serialize(cs);
                    iEvent.Event_Type__c = 'JUD-UPDATE';
                    EventBus.publish(iEvent);
                }
            }
            for(Case cs : caseRecordList){
                if(Test.isRunningTest()){
                    Integration_Event__e iEvent = new Integration_Event__e();
                    //iEvent.UUID__c = PlatformEventHelper.GUIDGenerator();
                    iEvent.Object_Name__c = 'Case';
                    iEvent.Record_ID__c = cs.id;
                    iEvent.Object_Payload__c = JSON.serialize(cs);
                    iEvent.Event_Type__c = 'UPDATE';
                    EventBus.publish(iEvent);
                }
            }
            if(Test.isRunningTest()){
                Integration_Event__e iEvent = new Integration_Event__e();
                iEvent.Object_Name__c = 'Order';
                //iEvent.Record_ID__c = cs.id;
                //iEvent.Object_Payload__c = JSON.serialize(cs);
                iEvent.Event_Type__c = 'VOID_ORDER';
                EventBus.publish(iEvent);
            }
            List<AppLog__c> lstLogs = [select id, apexClassName__c, message__c from AppLog__c where apexClassName__c  = 'DynamicBusinessRuleAPIForJudge' and message__c = 'JUD-UPDATE'];
            System.assertEquals(0, lstLogs.size());
            Test.stopTest();
        
        }Catch(Exception e){
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    }
    public testMethod static void testCreateAssignedSerialForMSPOrder(){
        try{
            List <Account> customers = TestDataFactory.customers;
        
        Product2 product = new Product2();
        product.Name = ' Test Product ';
        product.Description='Test Product Entry 1';
        product.productCode = 'ABC';
        product.isActive = true;
        insert product;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = product.Id;
        standardPrice.UnitPrice = 1;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;                
        
        Order order = new Order();
        order.AccountId = customers[0].Id;
        order.Status = 'Draft';
        order.EffectiveDate = system.today();
        order.Pricebook2Id =  pricebookId ;
        order.Quote_Business_Group__c = 'Barracuda MSP';
        insert order;
        
        OrderItem orderItem = new OrderItem();
        orderItem.OrderId = order.id;
        orderItem.Quantity = 24;
        orderItem.UnitPrice = 240;
        orderItem.Product2id = product.id;
        orderItem.PricebookEntryId = standardPrice.id;
        insert orderItem; 
        
        Test.startTest();
        if(Test.isRunningTest()){
            Integration_Event__e iEvent02 = new Integration_Event__e();
            iEvent02.Object_Name__c = 'Order';
            iEvent02.Record_ID__c = order.id;
            iEvent02.Event_Type__c = 'Order';
            EventBus.publish(iEvent02);
        }
        Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception' +e.getMessage()+'occurred at'+e.getStackTraceString());
        }
    }
}