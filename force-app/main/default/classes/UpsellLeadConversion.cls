public with sharing class UpsellLeadConversion {
	@InvocableMethod
    public static void fetchContracts(List<Id> leadIdList){
    	Lead leadRec = [Select ID,FirstName,LastName,Primary_Hot_List__c,Email,Phone FROM Lead Where Id =: leadIdList[0]];
        Hot_List__c hotlistRec= [Select Id ,Account__c,Converted_Opportunity__c,OwnerId FROM Hot_List__c WHERE Id =: leadRec.Primary_Hot_List__c];
        Account acctRec = new Account();
        if(hotlistRec.Account__c != null){
        	acctRec = [Select Id, OwnerId FROM Account WHERE Id =: hotlistRec.Account__c];
        }
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadRec.id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
		lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setOwnerId(acctRec.OwnerId);
        if(hotlistRec.Account__c != null){
        	lc.setAccountId(hotlistRec.Account__c);
        }
        if(hotlistRec.Converted_Opportunity__c != null){
        	lc.setOpportunityId(hotlistRec.Converted_Opportunity__c);	    
        }else{
        	lc.setDoNotCreateOpportunity(true);    
        }
		Database.LeadConvertResult lcr = Database.convertLead(lc);
    }
}