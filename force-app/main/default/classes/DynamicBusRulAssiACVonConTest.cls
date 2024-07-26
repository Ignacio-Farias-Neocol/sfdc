/**
* @author        Dilowar
* @date          2023-08-31
* @description   Test class for DynamicBusRulAssiACVonContract.
*                This has been added as a part of SFDC-20558
* @group         Test
*
*/
@isTest
public with sharing class DynamicBusRulAssiACVonConTest {
    @testSetup static void setup() {
        TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler'); 
        List <Account> customers = TestDataFactory.customers;
        List <Opportunity> opportunities = TestDataFactory.opportunities;
        for(Opportunity opp : opportunities){
            opp.SBCF_Annual_Contract_Value2__c = 10.00;
            opp.SBQQ__PrimaryQuote__c = NULL;
        }
        update opportunities;
        //List<Order> orders = TestDataFactory.orders;
        //List<Account> distributor = TestDataFactory.partnersDistributor;
        TriggerHandler.clearAllBypasses(); 
    }
    @isTest
    static void testPreACVOnOpp(){
        try{
            Account acc = [select id from Account limit 1];
            Opportunity opp = [select id from Opportunity limit 1];
            List<Contract> testContracts = new List<Contract> {
                new Contract(AccountId = acc.Id, StartDate = System.Today(), ContractTerm = 12, Business_Group__c = 'Core', SBQQ__RenewalOpportunity__c = opp.Id)
            };
            insert testContracts;
            Opportunity oppt = new Opportunity();
            oppt.Name ='Oppty 1' ;
            oppt.AccountID = acc.Id;
            oppt.Bill_To_Account__c = acc.id;
            oppt.Primary_Product_Family_2__c = 'Email Security Gateway'; // e.g. other values: Load Balancer, Phishline, Cloud Control
            oppt.Model_Series__c = 'API';
            oppt.StageName = 'Accepted';
            oppt.Amount = 3000;
            oppt.CloseDate = System.today();
            //oppt.Primary_Contact__c = rec.id;
            // new business opportunities
            oppt.recordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByDeveloperName().get('New_Business').getRecordTypeId();
            oppt.Bypass_Validation__c = true;
            //oppt.Reseller__c = newAccount2.Id;
            //oppt.Distributor__c = newAccount3.Id;
            oppt.Is_Unit_Test__c = true;
            oppt.LeadSource = 'Renewal';
            oppt.PurchaseOrderID__c = '2020';
            oppt.SBCF_Annual_Contract_Value2__c = 12.00;
            oppt.SBQQ__PrimaryQuote__c = NULL;
            oppt.SBQQ__AmendedContract__c = testContracts[0].id;
            List<Opportunity> lstOppt = new List<Opportunity>();
            lstOppt.add(oppt);
            insert lstOppt; 
            Map<Id, Opportunity> newMapOpp = new Map<Id, Opportunity>();
            for(Opportunity op : lstOppt){
                newMapOpp.put(op.id, op);
            }
            Test.startTest();
            if(!lstOppt.isEmpty() && !newMapOpp.isEmpty()){
                DynamicBusRulAssiACVonContract davc = new DynamicBusRulAssiACVonContract();
                davc.processRecords(newMapOpp, NULL, lstOppt, NULL, NULL, 'Insert');
            }
            Test.stopTest();
        }Catch(Exception e){
            System.debug('Exception occurred at:' +e.getStackTraceString());
        }
    }
}