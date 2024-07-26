global class CommunitiesRegHelper {

    global class CommunitiesRegException extends Exception {}

    global class UserData {

        @InvocableVariable (required=true)
        global String email;
        
        @InvocableVariable (required=true)
        global String userName;

        @InvocableVariable
        global ID userId;
        
        @InvocableVariable
        global ID contactId;
        
        @InvocableVariable
        global String lastName;
        
        @InvocableVariable
        global String firstName;

        @InvocableVariable
        global String companyName;

        @InvocableVariable
        global Boolean isExistingMember;

        @InvocableVariable
        global String newUserUrl;

        @InvocableVariable
        global String welcomeBackEmailSubject;

        @InvocableVariable
        global String welcomeBackEmailBody;

        // Constructor
        UserData(ID contactId, String firstName, String lastName, String email, String companyName) {
            this.contactId = contactId;
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
            this.userName = email;
            this.companyName = companyName;
        }
    }

    global static String getSiteUrl(){
        return Url.getSalesforceBaseUrl().toExternalForm();
    }

    global static String getSiteId(){
        return Network.getNetworkId();
    }

    global static AuthProvider getAuthProviderInfo(String authProviderName){
        List<AuthProvider> authProviders= [SELECT Id, AuthorizeUrl, DeveloperName, FriendlyName, LogoutUrl, SsoKickoffUrl FROM AuthProvider WHERE DeveloperName = :authProviderName];
        return (authProviders != null && !authProviders.IsEmpty()) ? authProviders[0] : null;
    }

    global static String getAuthProviderBaseUrl(String authProviderName){
        String url = getAuthProviderInfo(authProviderName) != null ? getAuthProviderInfo(authProviderName).AuthorizeUrl : null;
        return url != null ? url.substringBefore('com') + 'com' : null;
    }

    global static String getSsoUrl(String authProviderName){
        return getAuthProviderInfo(authProviderName) != null ? getAuthProviderInfo(authProviderName).SsoKickoffUrl : null;
    }

    global static String getNewUserUrl(String authProviderName, String email, String name, String company, String redirect){
        String newUserUrl = getAuthProviderBaseUrl(authProviderName);
        newUserUrl = newUserUrl != null ? newUserUrl + '/new_user?' : null;
        newUserUrl = newUserUrl != null &&  email != null ? newUserUrl + 'email='+email+'&' : null;
        newUserUrl = newUserUrl != null &&  name != null ? newUserUrl + 'name='+name+'&' : null;
        newUserUrl = newUserUrl != null &&  company != null ? newUserUrl + 'company='+company+'&' : null;
        newUserUrl = newUserUrl != null &&  redirect != null ? newUserUrl + 'redirect='+redirect : null;
        return newUserUrl;
    }

    global static boolean canCreateUser(UserData data) {
        //Check whether we want to allow creation of a user with this data
        if(data != null && data.email != null && data.username != null) {
            return true;
        } 
        return false;
    }

    global static List<UserData> createUser(List<Contact> contacts){

        UserData data;
        List<UserData> userData;
        List<Communities_Setting__mdt> mdt = [SELECT API_Name__c, Auth_Provider_Name__c FROM Communities_Setting__mdt WHERE Auth_Provider_Name__c = 'Barracuda'];
        if(contacts != null) {
            data = new UserData(contacts[0].Id,contacts[0].FirstName,contacts[0].LastName,contacts[0].Email,contacts[0].Account.Name);
        }
        if(!canCreateUser(data)) {
            //Returning null or throwing an exception fails the create user flow
           throw new CommunitiesRegException('Contact Email is required');
        }
 
        //Profile p = [SELECT Id FROM profile WHERE name = 'Apollo: CCPlus Barracuda Admin'];
        //List<User> users = [SELECT Id, FirstName, UserName, Email, Profile.Name, IsActive FROM User WHERE UserName = :data.email AND (Profile.Name = 'Apollo: CCPlus Barracuda' OR Profile.Name = 'Apollo: CCPlus Barracuda Admin')];
        Profile p = [SELECT Id FROM profile WHERE name = 'Apollo: Barracuda CCPlus Admin Login Profile'];
        List<User> users = [SELECT Id, FirstName, UserName, Email, Profile.Name, IsActive FROM User WHERE UserName = :data.email AND (Profile.Name = 'Apollo: Barracuda CCPlus Login Profile' OR Profile.Name = 'Apollo: Barracuda CCPlus Admin Login Profile')];
        
        Boolean updateUser = false;
        
        //Check the portal user already exist and update the profile
        if(users != null && !users.isEmpty()) {
            String provider = mdt!=null && !mdt.IsEmpty() ? mdt[0].API_Name__c : 'BCC';
            // Assign Community Admin Permission, if necessary
            updateUser(users[0].Id, p.Id);
            data.userId = users[0].Id;
            data.isExistingMember = true;
            data.welcomeBackEmailSubject = System.Label.Email_Subject_Welcome_Back;
            String body = System.Label.Email_Body_Welcome_Back.replace('[customer]', users[0].FirstName);
            //body = body.replace('[urlink]', CommunitiesRegHelper.getSiteUrl());
            body = body.replace('[urlink]', getSsoUrl(provider)!=null?getSsoUrl(provider):'');
            body = body.replace('[username]', users[0].UserName);
            body = body.replace('[linebreak]', '\n\r');
            data.welcomeBackEmailBody = body;
            userData = new List<UserData> {data};
            return userData;
        }
        /*
        This code is no longer required at this point because new users will be created first in Barracuda Authdb
        User u = new User();
        u.username = data.username;
        u.email = data.email;
        u.lastName = data.lastName;
        u.firstName = data.firstName;
        String alias = data.username;
        //Alias must be 8 characters or less
        if(alias.length() > 8) {
            alias = alias.substring(0, 8);
        }
        u.alias = alias;
        u.languagelocalekey = UserInfo.getLocale();
        u.localesidkey = UserInfo.getLocale();
        u.emailEncodingKey = 'UTF-8';
        u.timeZoneSidKey = 'America/Los_Angeles';
        u.profileId = p.Id;
        u.contactId = data.contactId;
        //Dont activate new community admin user prior to specified wait time
        u.isActive = false;
        insert u;
        data.userId = u.Id;
        */
        data.isExistingMember = false;
        data.newUserUrl = getNewUserUrl(mdt[0].API_Name__c, 
                                        data.email, 
                                        data.firstName+'%20'+data.lastName, 
                                        data.companyName, 
                                        getSsoUrl(mdt[0].API_Name__c));
        userData = new List<UserData> {data};

        return userData;
    }

    @future
    global static void updateUser(Id userId, Id profileId) {
        Boolean updateUser = false;
        List<User> users = [SELECT Id, Profile.Name, IsActive FROM User WHERE Id = :userId];
        // Assign Community Admin Permission, if necessary
        //if(users[0].Profile.Name == 'Apollo: CCPlus Barracuda') {
          if(users[0].Profile.Name == 'Apollo: Barracuda CCPlus Login Profile') {
            users[0].ProfileId = profileId;
            updateUser = true;
        }
        if(users[0].IsActive == false) {
            users[0].IsActive = true;
            updateUser = true;
        }
        if(updateUser) {
            update users[0];
        }    
    }
    /*
    // Assign Permission Set
    private static void assignPermission(Id userId, String permissionName) {
        List<PermissionSetAssignment> psas;
        List<PermissionSet> ps;
        if(userId != null) {
            psas = [SELECT id, PermissionSet.Name 
                    FROM PermissionSetAssignment
                    WHERE PermissionSet.IsOwnedByProfile = false 
                    AND (AssigneeId = :userId) 
                    AND PermissionSet.Name = :permissionName];  

            if(psas == null || psas.isEmpty()) {
                ps = [SELECT id, Name 
                        FROM PermissionSet 
                        WHERE Name = :permissionName];
                if(ps != null && !ps.IsEmpty()) {
                    PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps[0].id, AssigneeId = userId) ;
                    insert psa;
                }
            }                         
        }
    }

    @future
    global static void assignUserPermission(Id userId, String permissionName) {
        assignPermission(userId, permissionName);
    }

    @InvocableMethod(label='Assign Permission Set')
    global static void assignCustomerAdminPermission(List<Id> userIds) {
        assignPermission(userIds[0], '<PermissionSet Name Goes Here>');
    }
    */

}