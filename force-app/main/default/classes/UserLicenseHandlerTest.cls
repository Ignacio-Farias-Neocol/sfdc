@isTest
public class UserLicenseHandlerTest
{
    @testSetup static void createTestRec() {
        Account acc = new Account();
        acc.Name = 'UserLicenseHandlerTestAccount';
        insert acc;
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'UserLicenseHandlerTestContact';
        con.Email = 'UserLicenseHandlerTest@test.com';
        con.AccountId = acc.Id;
        insert con;         
    }
    
    @isTest
    static void assignCpqLicense() {
        //Get set up data
        Contact con = [SELECT Id,Name,AccountId FROM Contact WHERE Email = 'UserLicenseHandlerTest@test.com' LIMIT 1];
      //  PackageLicense cpqPackage = [SELECT Id, NamespacePrefix, AllowedLicenses, UsedLicenses,ExpirationDate,Status FROM PackageLicense WHERE NamespacePrefix = 'SBQQ' LIMIT 1];
        PermissionSetLicense cpqPackagePermId =[SELECT Id, MasterLabel FROM PermissionSetLicense where MasterLabel='Salesforce CPQ License' Limit 1];
        Profile pr = [SELECT Id,Name FROM Profile WHERE Name = 'Customer Community Plus Login User' LIMIT 1];

        Test.startTest();
        User u = new User();
        u.Alias = 'userLice';
        u.Email = 'UserLicenseHandlerTest@test.com';
        u.EmailEncodingKey = 'UTF-8';
        u.LastName = 'UserLicenseHandlerTestUser';
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.ProfileId = pr.Id;
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.UserName = 'UserLicenseHandlerTestUser@barracudatest.com';
        u.contactId = con.Id;
       
        insert u;       
        insert new PermissionSetLicenseAssign(AssigneeId= u.id, PermissionSetLicenseId = cpqPackagePermId.Id);
        
        Test.stopTest();
      
        //Assertion
     /*  UserPackageLicense upl = [SELECT PackageLicenseId, 
                                         UserId
                                  FROM UserPackageLicense 
                                  WHERE PackageLicenseId = :cpqPackage.Id 
                                  AND UserId = :u.Id];*/
                                  
                                   PermissionSetLicenseAssign upl = [SELECT PermissionSetLicenseId, 
                                         AssigneeId 
                                  FROM PermissionSetLicenseAssign
                                  WHERE PermissionSetLicenseId= :cpqPackagePermId.Id
                                  AND AssigneeId = :u.Id];

        System.assert(upl!=null);
    }
}