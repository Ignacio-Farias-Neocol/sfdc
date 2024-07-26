/**
 * @Author: Bhavesh Jha
 * Created Date: 04/16/2020
 */

public without sharing class CreateUserFromSelfRegistration {
    /**
     * @param List<UserWrapper> requiredData : required data passed from Flow Action
     * 
     */
    @InvocableMethod(label='Create User From Self Registration')
    public static List<String> createUser(List<UserWrapper> requiredDataCollection){
        List<User> userListForInsert = new List<User>();
        List<String> resultMessages = new List<String>();//indexed
        if(requiredDataCollection != null && !requiredDataCollection.isEmpty()){
            for(UserWrapper mUser: requiredDataCollection){
                userListForInsert.add(getUserInstanceFromParams(mUser.userName,//Username
                                                                mUser.email,//Email
                                                                mUser.alias,//Alias
                                                                mUser.firstName,//First Name
                                                                mUser.lastName,//Last Name
                                                                mUser.localeSidKey,//Locale
                                                                mUser.languageLocaleKey,//Language
                                                                mUser.emailEncodingKey,//Email Encoding
                                                                mUser.timeZoneSidKey,//Time Zone
                                                                mUser.currencyIsoCode,//Currency
                                                                mUser.profileId,//ProfileId
                                                                mUser.isactive,//isactive
                                                                mUser.contactid,//isactive
                                                                mUser.communityNickname
                                                               ));
            }
            if(!userListForInsert.isEmpty()){
                Database.SaveResult[] srList =  Database.insert(userListForInsert,false);
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        resultMessages.add('Success: User created, User ID: ' + sr.getId());
                    }
                    else {
                        // Operation failed, so get all errors   
                        if(!sr.getErrors().isEmpty()){
                            resultMessages.add('Error: Unable to create user, '+sr.getErrors()[0].getStatusCode() + ': ' + sr.getErrors()[0].getMessage());
                        }else{
                            resultMessages.add('Error: Unable to create user.');
                        }
                    }
                }
            }
        }
        
        return resultMessages;
    }
    /**
    * @params...
    * Description: 
    * Required fields when inserting Users:
    *   Alias
    *   Username
    *   Email
    *   First Name
    *   Last Name
    *   Locale (LOCALESIDKEY)
    *   Language (LANGUAGELOCALEKEY)
    *   Email Encoding (EMAILENCODINGKEY)
    *   Time Zone (TIMEZONESIDKEY)
    *   Currency (CURRENCYISOCODE)
    *   ProfileId 
    */
    public static User getUserInstanceFromParams(String userName,//0
                                                 String email,//1
                                                 String alias,//2
                                                 String firstName,//3
                                                 String lastName,//4
                                                 String localeSidKey,//5
                                                 String languageLocaleKey,//6
                                                 String emailEncodingKey,//7
                                                 String timeZoneSidKey, //8
                                                 String currencyIsoCode, //9
                                                 String profileId, //10
                                                 Boolean isactive, //11
                                                 String contactId, //12
                                                 String communityNickname)
    {
        String currentTimeMillie = String.valueof(System.currentTimeMillis());
        return new User(Username = userName,
                        Email = email,
                        Alias = alias,
                        Firstname = firstName,
                        Lastname = lastName,
                        LocaleSidKey = localeSidKey,
                        LanguageLocaleKey = languageLocaleKey,
                        EmailEncodingKey = emailEncodingKey,
                        TimeZoneSidKey = timeZoneSidKey,
                        CurrencyIsoCode = currencyIsoCode,
                        ProfileId = profileId,
                        isactive = isactive,
                        contactId = ContactId,
                        CommunityNickname = communityNickname+currentTimeMillie);
                        
    }
    
    public class UserWrapper {
        @invocableVariable(label='Username')
        public String userName;
        @invocableVariable(label='Email')
        public String email;
        @invocableVariable(label='Alias')
        public String alias;
        @invocableVariable(label='First Name')
        public String firstName;
        @invocableVariable(label='Last Name')
        public String lastName;
        @invocableVariable(label='Locale')
        public String localeSidKey;
        @invocableVariable(label='Language')
        public String languageLocaleKey;
        @invocableVariable(label='Email Encoding')
        public String emailEncodingKey;
        @invocableVariable(label='Time Zone')
        public String timeZoneSidKey;
        @invocableVariable(label='Currency')
        public String currencyIsoCode;
        @invocableVariable(label='ProfileId')
        public String profileId;
        @invocableVariable(label='Active')
        public boolean isactive;
        @invocableVariable(label='ContactId')
        public String contactId;
        @invocableVariable(label='Community Nickname')
        public String communityNickname;
    }
}