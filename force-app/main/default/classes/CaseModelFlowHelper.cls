public class CaseModelFlowHelper {
    
    @InvocableMethod(label='set contact center' description='set contact center from email address')
    public static List<Case> setContactCenter(List<Case> caseList) {
        FlowActionTriggerHandler.byPass = true;
        System.debug('##check if premium support case');
        Id americaQueueId;
        Id mwQueueId;
        Id mspQueueId;
        Id sonianQueueId;
        Id indiaQueueId;
        Id emeaQueueId;   
        Id chinaQueueId;
        Id japanQueueId;
        
        List<String> strList = new List<String>();
        
        Map<Id, Group> groupMap = new Map<Id, Group>([Select Id, Name, DeveloperName, Type from Group 
                                                      where Type = 'Queue' and DeveloperName in 
                                                      ('Contact_Center_Americas', 'Barracuda_MSP', 'WM_Sonian', 'WM_Managed_Workplace', 'Contact_Center_EMEA', 
                                                       'Contact_Center_India', 'Contact_Center_China', 'Support_Japan')]);
        for(Group groupRecord: groupMap.values()){
            if(groupRecord.DeveloperName == 'Contact_Center_Americas'){
                americaQueueId = groupRecord.Id;
            } else if(groupRecord.DeveloperName == 'Barracuda_MSP'){
                mspQueueId = groupRecord.Id;
            } else if(groupRecord.DeveloperName == 'WM_Sonian'){
                sonianQueueId = groupRecord.Id;
            } else if(groupRecord.DeveloperName == 'WM_Managed_Workplace'){
                mwQueueId = groupRecord.Id;
            } else if(groupRecord.DeveloperName == 'Contact_Center_EMEA'){
                emeaQueueId = groupRecord.Id;
            } else if(groupRecord.DeveloperName == 'Contact_Center_India'){
                indiaQueueId = groupRecord.Id;
            } else if(groupRecord.DeveloperName == 'Contact_Center_China'){
                chinaQueueId = groupRecord.Id;
            } else if(groupRecord.DeveloperName == 'Support_Japan'){
                japanQueueId = groupRecord.Id;
            }
        }
        
        if(caseList!=null && caseList.size()>0)
        {
            for(Case caseRecord :caseList)
            {
                //Case caseRecord = caseList[0];
                String contactCenter = '';
                System.debug('##caseRecord:: ' + JSON.serialize(caseRecord));
                List<String> fromAddressList=new List<String>();
                // String fromAddress = caseRecord.From_Address__c; SFDC-13763
                String fromAddress = caseRecord.From_Address_New__c;
                if(String.isNotEmpty(fromAddress) && String.isNotBlank(fromAddress))
                {
                    fromAddressList = fromAddress.split(';');
                    
                    Set<String> fromAddressSet = new Set<String>();
                    for(String addressStr: fromAddressList){
                        addressStr = addressStr.toLowerCase();
                        fromAddressSet.add(addressStr.trim());
                    }
                    
                    Map<String, Set<String>> fromAddressMap = new Map<String, Set<String>>();
                    for(Case_From_Address_New__mdt cfa: [Select DeveloperName, Email_Address__c from Case_From_Address_New__mdt]){
                        if(String.isBlank(cfa.Email_Address__c)) continue;
                        List<String> emailAddressList = cfa.Email_Address__c.split(';');                       
                        fromAddressMap.put(cfa.DeveloperName, new Set<String>(emailAddressList));
                    }
                    
                    System.debug('##fromAddressSet:: ' + fromAddressSet);
                    caseRecord.Premium_Emails__c = false;  
                    // caseRecord.Priority = 'P3';
                    caseRecord.Is_Priority_updated__c = true;
                    
                    if(caseRecord.OwnerId == americaQueueId){
                        caseRecord.Web_Region__c = 'Americas';
                        
                        // check if the email is premiumsupport/support/professionalservice
                        Boolean isPremiumSupportEmail = false;
                        Boolean isSupportEmail = false;
                        Boolean isProfessionalServiceEmail = false;
                        for(String incomingEmailAddress: fromAddressSet){
							if(fromAddressMap.get('premiumsupport_team_barracuda_com').contains(incomingEmailAddress)) isPremiumSupportEmail = true;
                            if(fromAddressMap.get('support_barracuda_com').contains(incomingEmailAddress)) isSupportEmail = true;
                            if(fromAddressMap.get('professionalservice_barracuda_com').contains(incomingEmailAddress)) isProfessionalServiceEmail = true;
                        }
                        
                        if(caseRecord.Priority != 'P4' && isPremiumSupportEmail){
                            caseRecord.Contact_Center_Workaround__c = 'AMERICAS PREMIUM';  
                            caseRecord.Premium_Emails__c = true;
                            caseRecord.Priority = 'P2';
                        } else if(caseRecord.Priority != 'P4' && isSupportEmail){
                            caseRecord.Contact_Center_Workaround__c = 'AMERICAS';
                            caseRecord.Is_Priority_updated__c = false;
                        } else if(caseRecord.Priority == 'P4' && isProfessionalServiceEmail){
                            caseRecord.IsProfessionalService__c = true;
                            caseRecord.Is_Priority_updated__c = true;
                            caseRecord.Contact_Center_Workaround__c = 'AMERICAS';
                            caseRecord.Priority = 'P3';
                        }
                    } else if(caseRecord.OwnerId == emeaQueueId){
                        caseRecord.Web_Region__c = 'EMEA';
                        
                        // check if the email is emeapremiumsupport/emeasupport/emeaprofessionalservice
                        Boolean isEmeaPremiumSupportEmail = false;
                        Boolean isEmeaSupportEmail = false;
                        Boolean isEmeaProfessionalServiceEmail = false;
                        for(String incomingEmailAddress: fromAddressSet){
							if(fromAddressMap.get('emeapremiumsupport_team_barracuda_com').contains(incomingEmailAddress)) isEmeaPremiumSupportEmail = true;
                            if(fromAddressMap.get('emeasupport_barracuda_com').contains(incomingEmailAddress)) isEmeaSupportEmail = true;
                            if(fromAddressMap.get('emeaprofessionalservice_barracuda_com').contains(incomingEmailAddress)) isEmeaProfessionalServiceEmail = true;
                        }
                        
                        if(caseRecord.Priority != 'P4' && isEmeaPremiumSupportEmail){
                            caseRecord.Contact_Center_Workaround__c = 'EMEA PREMIUM';
                            caseRecord.Premium_Emails__c = true;
                            caseRecord.Priority = 'P2';
                        } else if(caseRecord.Priority != 'P4' && isEmeaSupportEmail){
                            caseRecord.Contact_Center_Workaround__c = 'EMEA';
                            caseRecord.Is_Priority_updated__c = false;
                        } else if(caseRecord.Priority == 'P4' && isEmeaProfessionalServiceEmail){
                            caseRecord.IsProfessionalService__c = true;
                            caseRecord.Is_Priority_updated__c = true;
                            caseRecord.Contact_Center_Workaround__c = 'EMEA';
                            caseRecord.Priority = 'P3';
                        }        
                    } else if(caseRecord.OwnerId == indiaQueueId){
                        caseRecord.Web_Region__c = 'APAC';
                        
                        // check if the email is wafpremium/indiasupport/apacprofessionalservice
                        Boolean iswafpremiumsupport = false;
                        Boolean isindiasupport = false;
                        Boolean isapacprofessionalservice = false;
                        for(String incomingEmailAddress: fromAddressSet){
							if(fromAddressMap.get('wafpremium_team_barracuda_com').contains(incomingEmailAddress)) iswafpremiumsupport = true;
                            if(fromAddressMap.get('indiasupport_barracuda_com').contains(incomingEmailAddress)) isindiasupport = true;
                            if(fromAddressMap.get('apacprofessionalservice_barracuda_com').contains(incomingEmailAddress)) isapacprofessionalservice = true;
                        }
                        
                        if(caseRecord.Priority != 'P4' && iswafpremiumsupport){
                            caseRecord.Contact_Center_Workaround__c = 'APAC PREMIUM';
                            caseRecord.Premium_Emails__c = true;
                            caseRecord.Priority = 'P2';
                        } else if(caseRecord.Priority != 'P4' && isindiasupport){
                            caseRecord.Contact_Center_Workaround__c = 'APAC';
                            caseRecord.Is_Priority_updated__c = false;
                        } else if(caseRecord.Priority == 'P4' && isapacprofessionalservice){
                            caseRecord.IsProfessionalService__c = true;
                            caseRecord.Is_Priority_updated__c = true;
                            caseRecord.Contact_Center_Workaround__c = 'APAC';
                            caseRecord.Priority = 'P3';
                        } 
                    } else if(caseRecord.OwnerId == chinaQueueId){
                        caseRecord.Web_Region__c = 'China';
                        
                        // check if the email is China region
                        Boolean isChina = false;
                        for(String incomingEmailAddress: fromAddressSet){
							if(fromAddressMap.get('support_barracuda_com_cn').contains(incomingEmailAddress)) isChina = true;
                        }                        
                        if(isChina){
                            caseRecord.Is_Priority_updated__c = false;
                            caseRecord.Contact_Center_Workaround__c = 'CHINA';   
                        }
                    } else if(caseRecord.OwnerId == japanQueueId){
                        caseRecord.Web_Region__c = 'Japan';
                        
                        // check if the email is Japan region
                        Boolean isJapan = false;
                        for(String incomingEmailAddress: fromAddressSet){
							if(fromAddressMap.get('jsupport_barracuda_com').contains(incomingEmailAddress)) isJapan = true;
                        }                         
                        if(isJapan){
                            caseRecord.Is_Priority_updated__c = false;
                            caseRecord.Contact_Center_Workaround__c = 'JAPAN'; 
                        } 
                    } else if(caseRecord.OwnerId == mwQueueId){
                        caseRecord.Web_Region__c = 'Americas';
                        
                        // check if the email is MW region
                        Boolean isMW = false;
                        for(String incomingEmailAddress: fromAddressSet){
							if(fromAddressMap.get('mwsupport_barracuda_com').contains(incomingEmailAddress)) isMW = true;
                        }                         
                        if(isMW){
                            caseRecord.Is_Priority_updated__c = false;
                            caseRecord.Contact_Center_Workaround__c = 'MW'; 
                        }   
                    } else if(caseRecord.OwnerId == mspQueueId){
                        caseRecord.Web_Region__c = 'Americas';
                        
                        // check if the email is MSP region
                        Boolean isMSP = false;
                        for(String incomingEmailAddress: fromAddressSet){
							if(fromAddressMap.get('support_barracudamsp_com').contains(incomingEmailAddress)) isMSP = true;
                        }                         
                        if(isMSP){
                            caseRecord.Is_Priority_updated__c = false;
                            caseRecord.Contact_Center_Workaround__c = 'MSP'; 
                        } 
                    } else if(caseRecord.OwnerId == sonianQueueId){
                        caseRecord.Web_Region__c = 'Americas';
                        
                        // check if the email is SONIAN region
                        Boolean isSonian = false;
                        for(String incomingEmailAddress: fromAddressSet){
							if(fromAddressMap.get('archivetechsupport_barracuda_com').contains(incomingEmailAddress)) isSonian = true;
                        }                           
                        if(isSonian){
                            caseRecord.Is_Priority_updated__c = false;
                            caseRecord.Contact_Center_Workaround__c = 'SONIAN'; 
                        } 
                    } 
                }
            }
        }
        //System.debug('##strList:: ' + strList.size() + '##strList:: ' + strList.size() + ' ##jsonString::' + JSON.serialize(strList));
        System.debug('##jsonstring:: ' + JSON.serialize(caseList));
        return caseList;
    }
}