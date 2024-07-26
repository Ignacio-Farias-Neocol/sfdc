/**
* @author Aditya
* @date 13 July 2022
* @description Helper class for UpdateCommunityUserCurrency
*/
public class UpdateCommunityUserCurrencyHelper {
    
    Public static void updateCommunityUserCurrency(Set<Id> recIds,List<User> listOfCommUsers, String objectName){
        Set<Id> contIds = new Set<Id>();
        Map<Id,Contact> contMap = new Map<Id,Contact>();
        if(objectName == 'Account'){
             contMap = new Map<Id,Contact>([SELECT Id,AccountId FROM Contact WHERE AccountId IN :recIds]);
        }
        contIds = objectName == 'Account' ? contMap.keySet() : recIds;
        if(listOfCommUsers == null || listOfCommUsers.size()==0){
            listOfCommUsers = [SELECT Id,ContactId,CurrencyIsoCode,DefaultCurrencyIsoCode,Contact.Account.Type FROM User WHERE ContactId IN :contIds AND (Contact.Account.Type = :Label.g_Account_Type_Distributor_Core OR Contact.Account.Type = :Label.g_Account_Type_Partner_Reseller OR Contact.Account.Type = :Label.g_Account_Type_Customer)];
        }
        Map<Id,Contact> mapofContact = new Map<Id,Contact>([SELECT Id, AccountId, Account.Type,Account.CurrencyIsoCode, Community_User__c,Community_User__r.Profile.Name FROM Contact WHERE Id in :contIds]);
        System.debug('mapofContact...'+mapofContact);
        if(mapofContact != null && !mapofContact.isEmpty()){
            List<User> listOfUserToUpdate = new List<User>();
            for(User usr : listOfCommUsers){
                if(mapofContact.containsKey(usr.ContactId)){
                    if(mapofContact.get(usr.ContactId).Account.Type == Label.g_Account_Type_Distributor_Core || mapofContact.get(usr.ContactId).Account.Type == Label.g_Account_Type_Partner_Reseller || mapofContact.get(usr.ContactId).Account.Type == Label.g_Account_Type_Customer){
                        if(mapofContact.get(usr.ContactId).Account.CurrencyIsoCode != usr.CurrencyIsoCode || mapofContact.get(usr.ContactId).Account.CurrencyIsoCode != usr.DefaultCurrencyIsoCode){
                            listOfUserToUpdate.add(new User(Id=usr.Id,CurrencyIsoCode=mapofContact.get(usr.ContactId).Account.CurrencyIsoCode,DefaultCurrencyIsoCode=mapofContact.get(usr.ContactId).Account.CurrencyIsoCode));
                        }
                    }
                }
            }
            if(listOfUserToUpdate != null && listOfUserToUpdate.size()>0){
                UPDATE listOfUserToUpdate;
            }
        }
    }
}