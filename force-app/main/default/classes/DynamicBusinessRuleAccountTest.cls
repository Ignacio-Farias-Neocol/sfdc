@isTest
public class DynamicBusinessRuleAccountTest {
    @testSetup static void testSetup(){
        Account acc = new Account();
        acc.Name = 'TESH ACC';
        acc.Type = 'Partner - MSP';
        insert acc;
        
        Country__c mCountry = new Country__c();
        mCountry.Country_ISO__c = 'US';
        insert mCountry; 
        
        /*Address__c sAddress = new Address__c();
        sAddress.Country__c = mCountry.id;
        sAddress.Account__c = acc.id;
        sAddress.Type__c = 'Billing';
        insert sAddress;*/
    }
    
    @isTest static void unitTestPositive(){
        Test.startTest();
        List<Account> accList = new List<Account>{new Account(Name='TESTACC1',Type = 'Partner - MSP'),
            new Account(Name='TESTACC2',Type = 'Partner - MSP')};
        insert accList;
        accList[0].Bill_To_Phone__c = '0123456789';
        update accList;
        
        List<Integration_Snapshot__c> snapShotList = [Select id from Integration_Snapshot__c where Record_ID__c =: accList.get(0).id];
            
        //Assert snapShotList whether it has been created or not after publish Platform Event (Integration_Event__e).
        System.assert(snapShotList != null && !snapShotList.isEmpty());
        
        Test.stopTest();        
    } 
    
    @isTest static void unitTestNegative(){
        Test.startTest();
        List<Account> accList = new List<Account>{new Account(Name='TESTACC1'),
            new Account(Name='TESTACC2')};
        insert accList;
        accList[0].Bill_To_Phone__c = '0123456789';
        update accList;
        
        List<Integration_Snapshot__c> snapShotList = new List<Integration_Snapshot__c>([Select id from Integration_Snapshot__c where Record_ID__c =: accList.get(0).id]);
            
        //Assert snapShotList whether it has been created or not after publish Platform Event (Integration_Event__e).
        System.assert(snapShotList.isEmpty());
        
        Test.stopTest();        
    } 
    
    @isTest static void unitTestAccountNameChangePositive(){
        Test.startTest();
        List<Account> accList = new List<Account>{new Account(Name='TESTACC1',Type = 'Partner - MSP'),
            new Account(Name='TESTACC2',Type = 'Partner - MSP')};
        insert accList;
        accList[0].Name = 'TESTACC0';
        update accList;
        
        List<Integration_Snapshot__c> snapShotList = [Select id from Integration_Snapshot__c where Record_ID__c =: accList.get(0).id];
            
        //Assert snapShotList whether it has been created or not after publish Platform Event (Integration_Event__e).
        System.assert(snapShotList != null && !snapShotList.isEmpty());
        
        Test.stopTest();        
    } 
    
     @isTest static void unitTestAccountNameChangeNegative(){
        Test.startTest();
        List<Account> accList = new List<Account>{new Account(Name='TESTACC1'),
            new Account(Name='TESTACC2')};
        insert accList;
         accList[0].Name = 'TESTACC0';
        update accList;
        
        List<Integration_Snapshot__c> snapShotList = new List<Integration_Snapshot__c>([Select id from Integration_Snapshot__c where Record_ID__c =: accList.get(0).id]);
            
        //Assert snapShotList whether it has been created or not after publish Platform Event (Integration_Event__e).
        System.assert(snapShotList.isEmpty());
        
        Test.stopTest();        
    } 
}