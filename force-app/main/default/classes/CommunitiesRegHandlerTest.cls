@IsTest
public with sharing class CommunitiesRegHandlerTest {
    
    @testSetup static void setup() {
        Map<String, String> paramsMap = initializeParams();
        Account acc = new Account(name = 'test acc');
        acc.Is_Unit_Test__c = true;
        insert acc;
        List <Account> accounts = [SELECT Id FROM Account LIMIT 1];
        System.assert(!accounts.isEmpty(), 'There must be at least one account in this environment!');
        String accountId = accounts[0].Id;
        Contact con = new Contact(FirstName=paramsMap.get('firstName'),LastName=paramsMap.get('lastName'),Email=paramsMap.get('email'),AccountId=accountId);
        insert con;
    }

    /* Verifies Registration flow with a comtact that is created within the test */
    @IsTest
    static void testNewUser() {
        List <Contact> contacts = [SELECT Id, FirstName, LastName, Email, Account.Name FROM Contact LIMIT 1];
        System.assert(!contacts.isEmpty());
        List<CommunitiesRegHelper.UserData> userdata = CommunitiesRegHandler.registerUser(contacts);
        System.assert(userdata != null && !userdata.isEmpty());
        System.assertEquals(null, userdata[0].userId);
    }

    @IsTest
    static void testExistingUser() {
        String uniqueUserName = 'sysuser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole r = [SELECT Id FROM UserRole WHERE DeveloperName='IT'];
        User u = new User(Alias = 'sysuser', 
                            Email='sysuser@testorg.com',
                            EmailEncodingKey='UTF-8', 
                            LastName='Testing', 
                            LanguageLocaleKey='en_US',
                            LocaleSidKey='en_US', 
                            ProfileId = p.Id,
                            UserRoleId = r.Id,
                            TimeZoneSidKey='America/Los_Angeles', 
                            UserName=uniqueUserName);
        insert u;

        System.runAs(u) {
            List <Contact> contacts = [SELECT Id, FirstName, LastName, Email, Account.Name FROM Contact LIMIT 1];
            System.assert(!contacts.isEmpty());
            Map<String, String> paramsMap = initializeParams();
            createTestUser(paramsMap, contacts[0].Id);
            List<CommunitiesRegHelper.UserData> userdata = CommunitiesRegHandler.registerUser(contacts);
            System.assertNotEquals(null, userdata);
            System.assert(userdata[0].isExistingMember);
            //System.assert([SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSet.IsOwnedByProfile = false AND (AssigneeId = :userdata[0].userId) AND PermissionSet.Name = 'BarracudaCCPlusAdmin'] > 0);
        }
    }

    /* Helper method to initialize the parameters required for Customer Community Registration. */
    private static Map<String, String> initializeParams() {
        Map <String, String> paramsMap = new Map<String, String> ();
        String firstName = 'test';
        String lastName = 'User';
        String email = 'testUser@salesforce.com';
        paramsMap.put('firstName', firstName);
        paramsMap.put('lastName', lastName);
        paramsMap.put('email', email);
        return paramsMap;
    }

    private static User createTestUser(Map<String, String> paramsMap, String contactId) {
        //Profile p = [SELECT Id FROM profile WHERE name = 'Apollo: CCPlus Barracuda'];
        Profile p = [SELECT Id FROM profile WHERE name = 'Apollo: Barracuda CCPlus Login Profile'];
        User u = new User();
        u.username = paramsMap.get('email');
        u.email = paramsMap.get('email');
        u.lastName = paramsMap.get('lastName');
        u.firstName =  paramsMap.get('firstName');
        String alias = paramsMap.get('email');
        //Alias must be 8 characters or less
        if(alias.length() > 8) {
            alias = alias.substring(0, 8);
        }
        u.alias = alias;
        u.languagelocalekey = 'en_US';
        u.localesidkey = 'en_US';
        u.emailEncodingKey = 'UTF-8';
        u.timeZoneSidKey = 'America/Los_Angeles';
        u.profileId = p.Id;
        u.contactId = contactId;
        u.isActive = false;
        insert u;
        return u;
    }
}