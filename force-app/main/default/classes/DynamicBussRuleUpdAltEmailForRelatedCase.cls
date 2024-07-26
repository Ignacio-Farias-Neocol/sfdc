/**
 * Created by aditya padhy on 2023/05/11.
 *
 *  @Date 2023/05/11
 *  SFDC-19035
 
 */
public with sharing class DynamicBussRuleUpdAltEmailForRelatedCase implements DynamicBusinessRuleAction {
    public void processRecords(Map<Id,SObject> newRecordMap, Map<Id,SObject> oldRecordMap, List <SObject> records, String jsonParameter, String triggerOrder, String triggerContext) {
    LogModel log = LogModel.startLog('DynamicBussRuleUpdAltEmailForRelatedCase', 'DynamicBusinessRuleAction');
    System.debug('~#~~~~: starting: ' +  'DynamicBusinessRuleAccountWeb');
        try{
            List<Id> contactids = new List<Id>();
            List<String> strstatus = new List<String>{'New', 'In Progress' ,'Waiting for Customer Response','Vendor Hold'};
            
            for(sobject ocon : newRecordMap.values()){
                Contact ocontact = (Contact) ocon;
                if(ocontact.Use_Alt_Email_for_Case__c == true){
                    contactids.add(ocontact.Id);
                }
            }
            
            List<Case> casesToUpdate = new List<Case>();
            if(!contactids.IsEmpty() && contactids.size()>0){
                
                //for(Case c : [SELECT Id,ContactId,Alt_Email_in_use__c,ContactEmail FROM Case WHERE ContactId IN :newRecordMap.keySet() AND (Status = 'New' OR Status = 'In Progress' OR Status = 'Waiting for Customer Response' OR Status = 'Vendor Hold')]){
                  for(Case c : [SELECT Id,ContactId,Alt_Email_in_use__c,ContactEmail FROM Case WHERE ContactId IN :contactids  AND Status =: strstatus]){
                  
                    Contact cont = (Contact)newRecordMap.get(c.ContactId);
                    c.Alt_Email_in_use__c = cont.Use_Alt_Email_for_Case__c;
                    c.SuppliedEmail = cont.Alternative_Email__c;
                    casesToUpdate.add(c);
                }
            }

            if(casesToUpdate!=null && casesToUpdate.size()>0){
                //UPDATE casesToUpdate;
                List<Database.SaveResult> res = Database.update(casesToUpdate, false);
            }
        }catch(Exception ex){
            log.addExceptionLog(ex);
        }
    }
}