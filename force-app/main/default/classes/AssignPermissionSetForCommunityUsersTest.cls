@isTest
public class AssignPermissionSetForCommunityUsersTest {
    
    @testSetup static void createTestRec() {
        List<Account> accList = new List<Account>();
        Account acc1 = new Account();
        acc1.Name = 'TestAccount1';
        acc1.Type = 'Partner - Reseller';
        accList.add(acc1);
        Account acc2 = new Account();
        acc2.Name = 'TestAccount2';
        acc2.Type = 'Customer';
        accList.add(acc2);
        insert accList;
        
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact();
        con1.FirstName = 'Test';
        con1.LastName = 'CommunityUserContact';
        con1.Email = 'communityusertest@test.com';
        con1.AccountId = acc1.Id;
        conList.add(con1);
        Contact con2 = new Contact();
        con2.FirstName = 'Test2';
        con2.LastName = 'CommunityUserContact2';
        con2.Email = 'communityusertest2@test.com';
        con2.AccountId = acc2.Id;
        conList.add(con2);
        insert conList;         
    }
    
    @isTest
    static void assignCpqLicense() {
        List<Contact> con = [SELECT Id,Name,AccountId FROM Contact WHERE Email like '%communityusertest%' LIMIT 2];
        Profile pr = [SELECT Id,Name FROM Profile WHERE Name = 'Barracuda Partner Core Admin' LIMIT 1];

        Test.startTest();
        List<User> usrList = new List<User>();
        User u = new User();
        u.Alias = 'commUser';
        u.Email = 'communityusertest@test.com';
        u.EmailEncodingKey = 'UTF-8';
        u.LastName = 'CommunityUserContact';
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.ProfileId = pr.Id;
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.UserName = 'communityusertest@barracudatest.com';
        u.contactId = con[0].Id;
        usrList.add(u);
        User u1 = new User();
        u1.Alias = 'comUser2';
        u1.Email = 'communityusertest1@test.com';
        u1.EmailEncodingKey = 'UTF-8';
        u1.LastName = 'CommunityUserContact2';
        u1.LanguageLocaleKey = 'en_US';
        u1.LocaleSidKey = 'en_US';
        u1.ProfileId = pr.Id;
        u1.TimeZoneSidKey = 'America/Los_Angeles';
        u1.UserName = 'communityusertest2@barracudatest.com';
        u1.contactId = con[1].Id;
        usrList.add(u1);
        insert usrList; 
        Test.stopTest();
        List<Id> usrIds = new List<Id>();
        for(User usr : usrList){
			usrIds.add(usr.Id);            
        }
        
        List<PermissionSetAssignment> psaList = [SELECT PermissionSet.Name,PermissionSetId,AssigneeId,Assignee.contact.account.type FROM PermissionSetAssignment WHERE AssigneeId in :usrIds];
        System.debug('psaList...'+psaList);
        Integer partnerCount = 0, customerCount = 0;
        for(PermissionSetAssignment psa : psaList){
            System.debug('PermissionSet.Name...'+psa.PermissionSet.Name);
            if(psa.PermissionSet.Name == 'SalesforceCPQPartnerUserAccess' || psa.PermissionSet.Name == 'SteelBrickCPQPartnerUser'){
                partnerCount=partnerCount+1;
            }
            if(psa.PermissionSet.Name == 'SalesforceCPQCustomerUserAccess' || psa.PermissionSet.Name == 'SteelBrickCPQCustomerUser'){
                customerCount=customerCount+1;
            }
            System.debug('partnerCount...'+partnerCount);
            System.debug('customerCount...'+partnerCount);
                
        }
        System.assertEquals(2,partnerCount);
        System.assertEquals(2,customerCount);
                        
        PermissionSetLicenseAssign upl = [SELECT PermissionSetLicense.MasterLabel, PermissionSetLicenseId, AssigneeId  FROM PermissionSetLicenseAssign WHERE AssigneeId = :u.Id];
        System.assertEquals('Salesforce CPQ License',upl.PermissionSetLicense.MasterLabel);
    }

}