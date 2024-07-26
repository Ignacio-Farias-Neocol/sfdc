public with sharing class ContactSelector {

    public without sharing class ContactSelectorWithoutSharing {

        public  List<Contact> getContactsByEmail(string emailString){

                System.debug('ContactSelector :: getContactsByEmail:: '+emailString); // To be removed

                return
                [
                    SELECT Id, Name, Email, Account.Name, Phone, MailingCountryCode
                    FROM Contact WHERE Email = :emailString
                    LIMIT 15
                ];
            }
        }
    }