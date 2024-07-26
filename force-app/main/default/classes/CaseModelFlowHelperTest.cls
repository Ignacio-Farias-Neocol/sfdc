@isTest
public class CaseModelFlowHelperTest {
	
    @isTest
    static void testMethod01(){
		try {           
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
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
			List<Case> lCase = TestDataFactory.webCases;
            TriggerHandler.clearAllBypasses();
            
            for(Case caseRecord: lCase){
                caseRecord.From_Address_New__c = 'professionalservice@barracuda.com';
                caseRecord.OwnerId = americaQueueId;
                caseRecord.Priority = 'P4';
            }       
            CaseModelFlowHelper.setContactCenter(lCase);             
            
            for(Case caseRecord: lCase){
                caseRecord.From_Address_New__c = 'premiumsupport_team@barracuda.com';
                caseRecord.OwnerId = americaQueueId;
            }
            
            System.debug('##lCase:: ' + JSON.serialize(lCase));            
            CaseModelFlowHelper.setContactCenter(lCase);
            
            for(Case caseRecord: lCase){
                caseRecord.From_Address_New__c = 'support@barracuda.com';
            }       
            CaseModelFlowHelper.setContactCenter(lCase);                       

		}catch(Exception err) {
			system.debug('@@Error:'+err.getMessage());
		}           
    }
    
    @isTest
    static void testMethod02(){
		try {           
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
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
			List<Case> lCase = TestDataFactory.webCases;
            TriggerHandler.clearAllBypasses();
            
            for(Case caseRecord: lCase){
                caseRecord.From_Address_New__c = 'emeapremiumsupport_team@barracuda.com';
                caseRecord.OwnerId = emeaQueueId;
            }            
            CaseModelFlowHelper.setContactCenter(lCase);
            
            for(Case caseRecord: lCase){
                caseRecord.From_Address_New__c = 'emeasupport@barracuda.com';
            }            
            CaseModelFlowHelper.setContactCenter(lCase);

            for(Case caseRecord: lCase){
                caseRecord.From_Address_New__c = 'emeaprofessionalservice@barracuda.com';
                caseRecord.Priority = 'P4';
            }            
            CaseModelFlowHelper.setContactCenter(lCase);            
		}catch(Exception err) {
			system.debug('@@Error:'+err.getMessage());
		}          
    }
    
    @isTest
    static void testMethod03(){
		try {           
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
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
			List<Case> lCase = TestDataFactory.webCases;
            TriggerHandler.clearAllBypasses();
            
            for(Case caseRecord: lCase){
                caseRecord.From_Address_New__c = 'Wafpremiumsupport@barracuda.com';
                caseRecord.OwnerId = indiaQueueId;
                caseRecord.Priority = 'P3';
            }            
            CaseModelFlowHelper.setContactCenter(lCase);
            
            for(Case caseRecord: lCase){
                caseRecord.From_Address_New__c = 'indiasupport@barracuda.com';
            }            
            CaseModelFlowHelper.setContactCenter(lCase);
                        
            for(Case caseRecord: lCase){
                caseRecord.From_Address_New__c = 'linkandloadsupport_team@barracuda.com';
            }            
            CaseModelFlowHelper.setContactCenter(lCase);                

            for(Case caseRecord: lCase){
                caseRecord.From_Address_New__c = 'apacprofessionalservice@barracuda.com';
                caseRecord.Priority = 'P4';
            }            
            CaseModelFlowHelper.setContactCenter(lCase);            
		}catch(Exception err) {
			system.debug('@@Error:'+err.getMessage());
		}          
    }    
    
    @isTest
    static void testMethod04(){
		try {           
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
            TriggerHandler.bypass('DynamicBusinessRuleActionTriggerHandler');
			List<Case> lCase = TestDataFactory.webCases;
            TriggerHandler.clearAllBypasses();
            
            for(Case caseRecord: lCase){
                caseRecord.From_Address_New__c = 'helpdesk_dtg@barracuda.com.cn';
                caseRecord.OwnerId = chinaQueueId;
            }            
            CaseModelFlowHelper.setContactCenter(lCase);
            
            for(Case caseRecord: lCase){
                caseRecord.From_Address_New__c = 'jsupport_dtg@barracuda.com';
                caseRecord.OwnerId = japanQueueId;
            }            
            CaseModelFlowHelper.setContactCenter(lCase); 
            
            for(Case caseRecord: lCase){
                caseRecord.From_Address_New__c = 'mwsupport_dtg@barracuda.com';
                caseRecord.OwnerId = mwQueueId;
            }            
            CaseModelFlowHelper.setContactCenter(lCase);   
            
            for(Case caseRecord: lCase){
                caseRecord.From_Address_New__c = 'support_dtg@barracudamsp.com';
                caseRecord.OwnerId = mspQueueId;
            }            
            CaseModelFlowHelper.setContactCenter(lCase);
            
            for(Case caseRecord: lCase){
                caseRecord.From_Address_New__c = 'archivetechsupport_dtg@barracuda.com';
                caseRecord.OwnerId = sonianQueueId;
            }            
            CaseModelFlowHelper.setContactCenter(lCase);              
            
         
		}catch(Exception err) {
			system.debug('@@Error:'+err.getMessage());
		}  
        
    }        
}