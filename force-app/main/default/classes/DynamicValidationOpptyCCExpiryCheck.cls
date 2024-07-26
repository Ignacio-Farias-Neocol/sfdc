/**
* Created by aditya on 2023/08/03.
*
*  @Date 2023/08/03
*  This is Created as Part of SFDC-19649

*/
public with sharing class DynamicValidationOpptyCCExpiryCheck implements DynamicValidationRule{
    
    public Set<String> getExpectedFields() {
        return new Set<String> {
        }; 
            } 
    
    public Map<SObject,Boolean> evaluateRule(List<SObject> records){
        Map<Sobject,Boolean> oppForCCExpiryCheck = new Map<Sobject,Boolean>();
        Set<Id> oppIdsToCheck = new Set<Id>();
        Map<Id,Opportunity> mapoppty = new map<Id,Opportunity>();
        
        for (SObject o : records) {
            Opportunity opp = (Opportunity) o; 
            if (!System.isQueueable() && opp.Stagename=='Order in Process' || opp.Stagename=='Closed Won') {
                oppIdsToCheck.add(opp.Id);
                mapoppty.put(opp.Id,opp);
                
            }           
        }
        if (!oppIdsToCheck.isEmpty()){
            List<Opportunity> oppToCheck = [SELECT Id, Bill_To_Credit_Card__r.Expired__c FROM Opportunity WHERE Id IN :oppIdsToCheck];            
            for (Opportunity oppty : oppToCheck) {                
                if (oppty.Bill_To_Credit_Card__r.Expired__c == true) {
                    //oppForCCExpiryCheck.put(oppty,false);
                    oppForCCExpiryCheck.put(mapoppty.get(oppty.Id),false);
                }
            }
        }        
        return oppForCCExpiryCheck;  
    }
    
}