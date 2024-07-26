public with sharing class ContactService {
  
    public static List<Contact> getContactsByEmail(string emailString){
        
        return new ContactSelector.ContactSelectorWithoutSharing().getContactsByEmail(emailString);
    }

}