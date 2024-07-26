/**
* @author        Dilowar
* @date          2023-08-31
* @description   Test class for DynamicBusRulPopAccNmOnAssigSer.This has been added as a part of SFDC-20384
* @group         Test
*
*/
@isTest
public class DynamicBusRulPopAccNmAssSerTest {
	@testSetup
    static void setup() {
        // by pass business action
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); 
        List<Contact> contacts = TestDataFactory.customerContacts;
        List<Account> customers = TestDataFactory.customers;
        List<Account> partners = TestDataFactory.partners;
        List<Product2> products = TestDataFactory.products;
        //Opportunity
        Opportunity testOpp = TestDataFactory.createOpportunity(customers[0]);
        //Remove partners from the oppty
        testOpp.Distributor__c = null;
        testOpp.Distributor_Contact__c = null;
        testOpp.Reseller__c =  null;
        testOpp.Reseller_Contact__c = null;
        // testOpp.Business_Group__c = 'MSP';

        //Get addresses for the opportunity
        for(Address__c addr : [SELECT id, 
                                    Street__c, 
                                    City__c, 
                                    State_Name__c, 
                                    Country_Name__c, 
                                    Zip_Postal_Code__c,
                                    Type__c
                            FROM Address__c 
                            WHERE Account__c = :customers[0].Id ]){
        if(addr.Type__c == 'Billing'){
            System.debug('Inside billing');
            testOpp.Billing_Address__c = addr.Id;
            testOpp.Street__c = addr.Street__c;
            testOpp.City__c = addr.City__c;
            testOpp.State__c = addr.State_Name__c;
            testOpp.Country__c = addr.Country_Name__c;
            testOpp.Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
        }
        else if(addr.Type__c == 'Shipping'){
            System.debug('Inside shipping');
            testOpp.Shipping_Address__c = addr.Id;
            testOpp.Ship_To_Street__c = addr.Street__c;
            testOpp.Ship_To_City__c = addr.City__c;
            testOpp.Ship_To_State__c = addr.State_Name__c;
            testOpp.Ship_To_Country__c = addr.Country_Name__c;
            testOpp.Ship_To_Zip_Postal_Code__c = addr.Zip_Postal_Code__c;
        }
        }

        insert testOpp;

        Contract contract = new Contract();
        contract.AccountId = testOpp.accountId;
        contract.SBQQ__Opportunity__c = testOpp.Id;
        insert contract;

        Serial__c serial1 = new Serial__c();
        serial1.Serial_Number__c = '9999';
        serial1.Status__c = 'Active';
        serial1.Contract__c = contract.Id;

        Serial__c serial2 = new Serial__c();
        serial2.Serial_Number__c = '0000';
        serial2.Status__c = 'Active';
        serial2.Contract__c = contract.Id;        
        insert new List<Serial__c>{serial1, serial2};

        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c  = testOpp.accountId;
        subscription.SBQQ__Contract__c = contract.Id;
        subscription.SBCF_Serial_Number__c = null;
        subscription.SBQQ__Quantity__c = 1;
        insert subscription;         
        TriggerHandler.clearAllBypasses();    
        }
    @isTest static void test_AssignedSerialCreate() {
        //Get the serial record
        List<Serial__c> serial = [SELECT ID FROM Serial__c WHERE Serial_Number__c = '9999' Limit 1];
        //Get subscription record
        List<SBQQ__Subscription__c> sub = [SELECT ID FROM SBQQ__Subscription__c Limit 1];
        List<Opportunity> lstOpp = [select id, AccountID from Opportunity limit 1];

        Assigned_Serial__c assignedSerial = new Assigned_Serial__c();
        assignedSerial.Serial__c = serial[0].Id;
        assignedSerial.Subscription__c = sub[0].Id;
        assignedSerial.Status__c = 'Active';
        assignedSerial.Qty_In_Use__c = 10;
        assignedSerial.External_Id__c = 'uniqueId1';
        assignedSerial.End_User_Account__c = lstOpp[0].AccountId;
        insert assignedSerial;
        List <Assigned_Serial__c> assignedSerials = new List <Assigned_Serial__c>();
        assignedSerials.add(assignedSerial);
        Test.startTest();
        DynamicBusRulPopAccNmOnAssigSer d = new DynamicBusRulPopAccNmOnAssigSer();
      d.processRecords(null, null, assignedSerials, '', '', 'Insert');
        Test.stopTest();
    }
    
}