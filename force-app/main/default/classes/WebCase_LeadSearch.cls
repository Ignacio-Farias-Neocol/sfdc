/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-18-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class WebCase_LeadSearch {
    
    @AuraEnabled(cacheable=true)
    public static List<Lead> searchLeadsBySuppliedEmail(String suppliedEmail) {
        
        List<Contact> matchingContacts = [SELECT Id FROM Contact WHERE Email = :suppliedEmail LIMIT 1];
        
        if(!matchingContacts.isEmpty()) {
            return null; // A contact with the supplied email already exists, so return null
        }else{
          return [SELECT Id, Name,Status FROM Lead WHERE Email LIKE :suppliedEmail and Status != 'Converted' limit 1];   
        }
        
       
    }
}