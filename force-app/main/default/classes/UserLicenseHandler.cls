/**
* @author        Keerthi Atluri       
* @date          2020-05-18
* @description   Assigning CPQ Licenses to Community Users from User Trigger
*
* @group         Handler
*/

public inherited sharing class UserLicenseHandler implements DynamicBusinessRuleAction
{
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List<SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
        
        if (records == null || records.size() == 0 ){
            return;
        }
        
        try {
            String objectName =  records[0].getSObjectType().getDescribe().getName();
            
            if (objectName == 'User') {
                
                //Reserved for future update - filter based on profiles
                //List<String> lProfileIds = new List<String>(System.Label.LicenseProfileIds.split(','));
                Set<Id> sContactId = new Set<Id>();
                List<User> lCommunityUsers = new List<User>();
                List<UserPackageLicense> lUsersToAssignLicense = new List<UserPackageLicense>();
                Integer availableLicenses = 0;
                
                //Instantiate the log class to capture logs for error conditions
                //LogModel log = LogModel.startLog('UserLicenseHandler', 'assignCPQLicense');
                system.debug('@@ Process Initiated');
                
                //Query CPQ Package Information
                PackageLicense cpqPackage = [SELECT Id, 
                                             NamespacePrefix, 
                                             AllowedLicenses, 
                                             UsedLicenses,
                                             ExpirationDate,
                                             Status 
                                             FROM PackageLicense 
                                             WHERE NamespacePrefix = 'SBQQ' 
                                             LIMIT 1];
                
                //Checking for available CPQ Licenses
                availableLicenses = (cpqPackage.AllowedLicenses - cpqPackage.UsedLicenses);
                //log.addLog('No.of availablelicenses: ' + availableLicenses);
                system.debug('@@ No.of availablelicenses: ' + availableLicenses);
                
                //Run this logic when there are available licenses. When running in sandbox we just check for status.
                //We do this because in sandbox the allowed license = -1 and status is free
                if(cpqPackage != null && (availableLicenses>0 || cpqPackage.Status=='Free')) {
                    
                    //log.addLog('availableLicenses ' + availableLicenses);
                    for(Sobject u:records) {
                        Id contactId = (Id)u.get('contactId');
                        if(String.isNotBlank(String.valueOf(contactId))) {
                            sContactId.add(contactId);
                            lCommunityUsers.add((User)u);
                        }
                    }
                    
                    //Excluding Marketing Users
                    if(!sContactId.isEmpty()) {
                        
                        Set<Id> sExceptMarketingUsers = new Set<Id>();
                        for(Contact c:[SELECT Id,Name,Partner_Portal_Access__c 
                                       FROM Contact 
                                       WHERE Id IN:sContactId 
                                       AND Partner_Portal_Access__c != 'Marketing']) {
                                           sExceptMarketingUsers.add(c.Id);
                                       }
                        //Creating UserPackageLicense record
                        for(User usr:lCommunityUsers) {
                            if(sExceptMarketingUsers.contains(usr.contactId)) {
                                lUsersToAssignLicense.add(new UserPackageLicense(PackageLicenseId=cpqPackage.Id,
                                                                                 UserId=usr.Id));
                            }
                        }
                        
                        //Assigning licenses to Community Users
                        if(!lUsersToAssignLicense.isEmpty()) {
                            DML.SAVE(lUsersToAssignLicense);
                        }else {
                            //log.addLog('Error while assigning License - availableLicenses: ' + availableLicenses);
                            system.debug('Error while assigning License - availableLicenses: ' + availableLicenses);
                        }
                    }
                }
                //log.endLog('End: UserLicenseHandler');	
                system.debug('End: UserLicenseHandler');			
            }
            
        } Catch (Exception e) {
            System.debug('processRecords failed: ' + e);
            //log.addExceptionLog(e);
        }
    }
}