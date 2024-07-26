public class LCC_CaseSerialDisplay {
	
    @auraEnabled
    public static List<Assigned_Serial__c> getCaseSubscriptions(Id caseId){
        Set<Id> asIdSet = new Set<Id>();        
        for(Case_Subscription__c cs: [Select Assigned_Serial__c from Case_Subscription__c where Case__c =: caseId]){
            asIdSet.add(cs.Assigned_Serial__c);
        }        
        return [Select Id, Name, Serial_Number__c, Subscription__r.Name, Subscription__c,
                Subscription__r.SBQQ__ProductName__c,Subscription__r.SBQQ__EndDate__c,  Serial__c 
                from Assigned_Serial__c
                where Id =: asIdSet];        
    }
    
    @auraEnabled
    public static List<Serial__c> getSerial(Id caseId){
		Set<Id> serialIdSet = new Set<Id>();
        List<Case_Subscription__c> caseSubList = [Select Id, 
                                                  Assigned_Serial__r.Serial__c
                                                  from Case_Subscription__c
                                                  where Case__c =: caseId];
        for(Case_Subscription__c caseSub: caseSubList){
			serialIdSet.add(caseSub.Assigned_Serial__r.Serial__c);
        }
        return [Select Id, Name, Serial_Number__c from Serial__c                            
                where Id =: serialIdSet];
    }    
    
    @auraEnabled
    public static List<Assigned_Serial__c> getActiveSubscriptions(Id serialId){
        return [Select Id, Name, Serial_Number__c, Subscription__r.Name, Subscription__c,
                Subscription__r.SBQQ__ProductName__c, Subscription__r.SBQQ__EndDate__c, Serial__c 
                from Assigned_Serial__c
                where Serial__c =: serialId
                and Subscription__r.SBQQ__EndDate__c >= TODAY];
    }    
    
    @auraEnabled
    public static Map<String, String> saveSubscriptions(Id caseId, List<String> ids, Id serialId){
        Map<String, String> returnMap = new Map<String, String>();
        try{
            Case caseRecord = new Case();
            caseRecord.Id = caseId;
            caseRecord.Serial__c = serialId;
            update caseRecord;            
            
            List<Case_Subscription__c> csList = [Select Id from Case_Subscription__c where Case__c =: caseId];
            delete csList;
            csList.clear();
            //List<String> idsList = ids.split(',');
            for(String idStr: ids){
                Case_Subscription__c cs = new Case_Subscription__c();
                cs.Case__c = caseId;
                cs.Assigned_Serial__c = idStr;
                csList.add(cs);
            }    
            if(!csList.isEmpty()) insert csList;   
            returnMap.put('isSuccess', 'true');
        } catch(Exception e){
            returnMap.put('isSuccess', 'false');
            returnMap.put('errorMessage', e.getMessage());
        }
        return returnMap;
    }      
}