/**
* @author        Ivan Yeung/salesforce services       
* @date          2018-10-15
* @description   Unit Test class for AccountTriggerHandler 
* @group         Test
*
*/
@isTest
public with sharing class DynamicBusinessRuleAccountUpdate_Test {
    @isTest static void testInsertUpdate() {


        Test.startTest();
        
        List<DNBoptimizer__DnBCompanyRecord__c> records = new List<DNBoptimizer__DnBCompanyRecord__c>();
        
        records.add(new DNBoptimizer__DnBCompanyRecord__c(Name='test1',DNBoptimizer__EmployeeCountTotal__c=10));
        records.add(new DNBoptimizer__DnBCompanyRecord__c(Name='test2',DNBoptimizer__EmployeeCountTotal__c=20));
        Insert records;
        
        //TestDataFactory.createAccounts();
        List<Account> listAcc = new List<Account>();
        
        listAcc = TestDataFactory.customers;
        //listAcc = TestDataFactory.createCustomerAccount();
        listAcc[0].DNBoptimizer__DnBCompanyRecord__c = records[0].Id;
        //listAcc[1].DNBoptimizer__DnBCompanyRecord__c = records[1].Id;
        
        update listAcc;
        
        List<Account> listAcctest = new List<Account>([Select Id,Employee_Count_DnB__c from Account where Id IN : listAcc]);
        System.AssertEquals(listAcctest[0].Employee_Count_DnB__c,10);
        //System.AssertEquals(listAcctest[1].Employee_Count_DnB__c,10);
        
        listAcc[0].DNBoptimizer__DnBCompanyRecord__c = records[1].Id;
        
        update listAcc;
        
        records[1].DNBoptimizer__EmployeeCountTotal__c = 50;
		records[0].DNBoptimizer__EmployeeCountTotal__c = 90;
		
		update records;
        
        listAcctest = new List<Account>([Select Id,Employee_Count_DnB__c from Account where Id IN : listAcc]);
        System.AssertEquals(listAcctest[0].Employee_Count_DnB__c,50);
        listAcc[0].DNBoptimizer__DnBCompanyRecord__c = null;
        update listAcc;
        

        Test.stopTest();
        
     }
 }