@IsTest 
public class DynamicBusRuleUpdAccountManagerTest {
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
                         EmailEncodingKey='UTF-8', LastName='TestingATM'+uu.size(), LanguageLocaleKey='en_US',
                         LocaleSidKey='en_US', ProfileId = p.Id,
                         TimeZoneSidKey='America/New_York', UserName= uid + '@test.com',isActive = true, UserRoleId = r.Id);      
            uu.add(u);
        }
        insert uu;
    }
    
    static testMethod void testUpdateAccManager(){ 
        Id custRecTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        List<Account> lstOfAccs = new List<Account>();
        Account customer;
        List<User> userList = [SELECT Id FROM User WHERE LastName LIKE 'TestingATM%' LIMIT 3];
        userList[0].ManagerId = userList[1].Id;
        Update userList[0];
        
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
        customer.ownerId = userList[0].Id;
        customer.CSM2__c = userList[0].Id;
        insert customer;
                
        /*AccountTeamMember atm = new AccountTeamMember();
        atm.AccountId = customer.Id;            
        atm.TeamMemberRole = 'Customer Success Manager - High Touch';
        atm.UserId = userList[0].Id;
        atm.AccountAccessLevel = 'Read';
        atm.ContactAccessLevel = 'Read';
        atm.CaseAccessLevel = 'Read';
        atm.OpportunityAccessLevel = 'Read';
        insert atm;*/
        
        Test.startTest();
           	userList[0].ManagerId = userList[2].Id;
            update userList[0];
        Test.stopTest();
        User usr = [SELECT Id, LastName FROM User WHERE Id = :userList[2].Id];
        Account acc = [SELECT Id,CSM_Manager__c FROM Account WHERE Id = :customer.Id];
        System.assertEquals(acc.CSM_Manager__c, usr.LastName, 'Names are matching');
    }
}