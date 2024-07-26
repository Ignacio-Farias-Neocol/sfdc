@IsTest
public class DynamicBusinessRuleAccTeamMemberTest {
    @testSetup
    public static void insertUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole r = [SELECT Id FROM UserRole where Name ='Sales Operations' LIMIT 1];
        User u;
        List<User> uu = new List<User>();
        while (uu.size() < 5) {
            Blob b = Crypto.GenerateAESKey(128);
            String h = EncodingUtil.ConvertTohex(b);
            String uid = h.SubString(0,8);
            u = new User(Alias = uid, Email= uid + '@test.com',
                         EmailEncodingKey='UTF-8', LastName='TestingATM', LanguageLocaleKey='en_US',
                         LocaleSidKey='en_US', ProfileId = p.Id,
                         TimeZoneSidKey='America/New_York', UserName= uid + '@test.com',isActive = true, UserRoleId = r.Id);      
            uu.add(u);
        }
        insert uu;
    }
    
    @isTest
    public static void deleteAccountTeamMemberTest(){
        Id custRecTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        List<Account> lstOfAccs = new List<Account>();
        Account customer;
        User u = [SELECT Id FROM User where LastName = 'TestingATM' LIMIT 1];
        while (lstOfAccs.size() < 5) {
            customer = new Account();
            customer.Is_Unit_Test__c  = true;
            customer.Name = 'Customer Test'+ String.valueOf(lstOfAccs.size());
            customer.billingStreet = '415 Mission Street';
            customer.billingCity = 'San Francisco';
            customer.BillingCountryCode = 'US';
            customer.billingStateCode = 'CA';
            customer.billingPostalCode = '94105';
            customer.recordTypeId = custRecTypeId;
            customer.Status__c = 'Active';
            customer.Territory_ID__c = '123';
            customer.AccountSource = 'Renewal';
            customer.Terr_Theater__c = 'APAC';
            customer.CurrencyIsoCode = 'USD';   
            customer.ownerId = u.Id;
            lstOfAccs.add(customer);
        }
        insert lstOfAccs;
        List<User> lstOfUsers = [SELECT Id, Name, isActive FROM User  where LastName = 'TestingATM' LIMIT 5];
        List<AccountTeamMember> lstOfAccTeamMembers = new List<AccountTeamMember>();
        for(Integer i = 0; i < 5; i++){
            AccountTeamMember atm = new AccountTeamMember();
            atm.AccountId = lstOfAccs[i].Id;            
            atm.TeamMemberRole = 'Customer Success Manager - High Touch';
            atm.UserId = lstOfUsers[i].Id;
            atm.AccountAccessLevel = 'Read';
            atm.ContactAccessLevel = 'Read';
            atm.CaseAccessLevel = 'Read';
            atm.OpportunityAccessLevel = 'Read';
            lstOfAccTeamMembers.add(atm);
        }
        insert lstOfAccTeamMembers;
        delete lstOfAccTeamMembers;
        Account acc = [SELECT Id ,CSM__c FROM Account LIMIT 1];        
        system.assertEquals(NULL, acc.CSM__c );
    }
    
    static testMethod void testCSMNameBatch() 
    {        
        Id custRecTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        List<Account> lstOfAccs = new List<Account>();
        Account customer;
        User u = [SELECT Id FROM User where LastName = 'TestingATM' LIMIT 1];
        while (lstOfAccs.size() < 5) {
            customer = new Account();
            customer.Is_Unit_Test__c  = true;
            customer.Name = 'Customer Test'+ String.valueOf(lstOfAccs.size());
            customer.billingStreet = '415 Mission Street';
            customer.billingCity = 'San Francisco';
            customer.BillingCountryCode = 'US';
            customer.billingStateCode = 'CA';
            customer.billingPostalCode = '94105';
            customer.recordTypeId = custRecTypeId;
            customer.Status__c = 'Active';
            customer.Territory_ID__c = '123';
            customer.AccountSource = 'Renewal';
            customer.Terr_Theater__c = 'APAC';
            customer.CurrencyIsoCode = 'USD';   
            customer.ownerId = u.Id;
            customer.CSM__c = u.Id;
            lstOfAccs.add(customer);
        }
        insert lstOfAccs;
        
        Test.startTest();
        UpdateCSMName_Batch obj = new UpdateCSMName_Batch();
        DataBase.executeBatch(obj); 
        Test.stopTest();
        
        Account acc = [SELECT Id ,CSM__c,CSM_Name__c,CSM_Manager__c FROM Account LIMIT 1];        
        //system.assertNotEquals(NULL, acc.CSM_Manager__c );
    }
    
    
}