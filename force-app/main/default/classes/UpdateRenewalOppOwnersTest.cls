/**
* @author        Dilowar
* @date          2024
* @description   Test class for UpdateRenewalOppOwners. 
*
* @group         Test
*
*/
@isTest
public with sharing class UpdateRenewalOppOwnersTest {
    @testSetup
    static void setup() {
        try{
             //Insert Territory records.
             List<Territory2Type> terriType   = [SELECT id, 
                                                       DeveloperName 
                                                FROM Territory2Type 
                                                WHERE  DeveloperName = 'Territory' 
                                                LIMIT 1];                   
             
             List<Territory2Model>  model = [SELECT id, DeveloperName from Territory2Model where  DeveloperName = 'Geographic' LIMIT 1];               
     
             Territory2 territory= new Territory2();        
             territory.DeveloperName = 'test';        
             territory.name = 'test';         
             territory.Territory2TypeId = terriType[0].id;         
             territory.Territory2ModelId = model[0].id;         
             territory.AccountAccessLevel = 'All';         
             territory.OpportunityAccessLevel = 'Edit';         
             insert territory;
            
             Territory2 territory02 = new Territory2();        
             territory02.DeveloperName = 'test_02';        
             territory02.name = 'test_02';         
             territory02.Territory2TypeId = terriType[0].id;         
             territory02.Territory2ModelId = model[0].id;         
             territory02.AccountAccessLevel = 'All';         
             territory02.OpportunityAccessLevel = 'Edit';         
             insert territory02;
            
             List<User> usr = [select id, name, isActive from user where name  = 'Admin Salesforce' limit 1];
             List<User> usr01 = [select id, name, isActive from user where name  = 'System Renewal User' limit 1];
             List<User> usr03 = [select id, name, isActive from user where name  = 'Salesforce Team' limit 1];
             //Insert records into UserTerritory2Association object.
             UserTerritory2Association uta01 = new UserTerritory2Association();
             uta01.Territory2Id = territory.id;
             uta01.userId = usr[0].id;
             uta01.RoleInTerritory2 = 'Renewals';
             //uta01.isActive = true;
             insert uta01;
             UserTerritory2Association uta02 = new UserTerritory2Association();
             uta02.Territory2Id = territory02.id;
             uta02.userId = usr03[0].id;
             uta02.RoleInTerritory2 = 'Renewal - Backup Owner';
             //uta02.isActive = true;
             insert uta02;
             User usr02 = [Select id from User where Id = :UserInfo.getUserId()];
            system.runAs(usr02){
               TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');  
    			Id oppRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal').getRecordTypeId();  
                //Create an Account
                Account acc = TestDataFactory.customers[0];
        		acc.Territory_ID__c = territory.Id;
                update acc;
                
                Product2 testProd = TestDataFactory.products[0];
				testProd.SBQQ__SubscriptionPricing__c = 'Fixed Price';
                testProd.SBQQ__SubscriptionTerm__c = 1;
                update testProd;
                
                Contract testContract = new Contract(AccountId = acc.Id, 
                    Business_Group__c = 'Core', 
                    SBQQ__RenewalOpportunityStage__c = 'Not Contacted', 
                    StartDate = System.Today() - 20, ContractTerm = 12);
                insert testContract;
                testContract.Status = 'Activated';
                testContract.EndDate = system.today().addDays(150);
                //testContract.Auto_Renew__c = true;
                testContract.SBQQ__RenewalQuoted__c = false;
                testContract.Has_Contract_Error__c = false;
                testContract.Exclude_from_Batch__c = false;
                //testContract.Demo_Opp__c = false;
                testContract.SBQQ__RenewalForecast__c = false;
                testContract.All_Subs_RMA__c = false;
                //testContract.SBCF_EndDate__c = system.today().addDays(60);
                update testContract;
    
                SBQQ__Subscription__c testSub = new SBQQ__Subscription__c(SBQQ__Product__c = testProd.Id, SBQQ__Quantity__c = 1, SBQQ__Contract__c = testContract.Id, SBQQ__SubscriptionStartDate__c = System.Today() - 20); 
                insert testSub;
                
                Opportunity testOpp;
               // SBQQ__Quote__c testQuote;

                testOpp = TestDataFactory.opportunities[0];
               // testOpp.Ownerid = renewalUser.Id;
                testOpp.Territory2Id = territory.Id;
                testOpp.Primary_Product_Family_2__c = 'Email Security Gateway';
                testOpp.RecordTypeID = oppRecordTypeID;
                testOpp.SBQQ__RenewedContract__c = testContract.Id;
                testOpp.OwnerId = usr01[0].id;
                testOpp.Business_Group__c = 'Core';
                update testOpp;
                TriggerHandler.clearAllBypasses();  
            }
        }Catch(Exception e){
            system.debug('Exception' +e.getMessage()+ 'Occurred At' +e.getStackTraceString());
        }
        
    }
    @isTest static void test_UpdateRenewOppOwnerPrimary() {
        Test.startTest();
        List<Opportunity> lstOPP01 = [select id, name, Territory_ID__c, ownerId, owner.name from Opportunity where (RecordType_Name__c = 'Renewal' OR RecordType_Name__c = 'Locked Renewal') and Territory_ID__c != NULL and stageName != 'Closed Won' and stageName != 'Closed Lost' and Elligible_for_Renewal_Owner_assignme__c = TRUE];
       //System.debug('lstOPP01 is:' +lstOPP01);
        UpdateRenewalOppOwnersSch s = new UpdateRenewalOppOwnersSch();
            String sch ='0 0 * * * ?'; 
            System.schedule('TestUpdateRenewalOppOwnersSch', sch, s);
            UpdateRenewalOppOwners b = new UpdateRenewalOppOwners();
            Database.executeBatch(b, 5);
        Test.stopTest();
    }
    @isTest static void test_UpdateRenewOppOwnerBackup() {
        Test.startTest();
        List<Territory2> terrRecord = [select id from Territory2 where DeveloperName  = 'test_02' limit 1];
        
        List<Account> accRecord = [select id, Territory_ID__c from Account limit 1];
        accRecord[0].Territory_ID__c = terrRecord[0].id;
        update accRecord;
        
        List<Opportunity> lstOPP02 = [select id, name, Territory_ID__c, ownerId, owner.name from Opportunity where (RecordType_Name__c = 'Renewal' OR RecordType_Name__c = 'Locked Renewal') and Territory_ID__c != NULL and stageName != 'Closed Won' and stageName != 'Closed Lost' and Elligible_for_Renewal_Owner_assignme__c = TRUE];
       //System.debug('lstOPP02 is:' +lstOPP02);
        lstOPP02[0].accountID = accRecord[0].id;
        update lstOPP02;
        
        UpdateRenewalOppOwnersSch s = new UpdateRenewalOppOwnersSch();
            String sch ='0 0 * * * ?'; 
            System.schedule('TestUpdateRenewalOppOwnersSch', sch, s);
            UpdateRenewalOppOwners b = new UpdateRenewalOppOwners();
            Database.executeBatch(b, 5);
        Test.stopTest();
    }

}